function Write-ToSQLTable {
    param(
        [Parameter(Mandatory=$true, position=0)]
        [String]$database,
        [Parameter(Mandatory=$true, position=1)]
        [String]$table = "master",
        [Parameter(Mandatory=$true, position=2)]
        [Array]$InsertKeys,
        [Parameter(Mandatory=$true, position=3)]
        [Array]$InsertValues,
        [Parameter(Mandatory=$false, position=4)]
        [String]$server,
        [Parameter(Mandatory=$false, position=5)]
        [String]$schema = "dbo",
        [Parameter(Mandatory=$false, ValueFromPipeline)]
        [System.Data.SqlClient.SqlConnection]$conn = $null
    )

    ############# INITIALIZE OBJECTS ######################################
    if ($conn -eq $null){
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server = $server; Database = $database; Integrated Security = True"
        try{
            $conn.open()
        } catch [System.Data.SqlClient.SqlException]{
            write-error "database not accessible to user account"
            break
        }
    }

    if ($conn.State -ne "Open"){
        $conn.Open()
    }

    $query = New-Object System.Data.SqlClient.SqlCommand
    $query.connection = $conn

    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter
    $ds = New-Object System.Data.DataSet

    $tableTypeString = ""
    $inputTypeString = ""

    $KeysFormatted = ""
    $ValuesFormatted = ""

    ############# VERIFY INPUT VALUE TYPES ################################

    $query.CommandText = "SELECT * FROM [$database].[$schema].[$table];"
    $adapter.SelectCommand = $query
    $adapter.fill($ds)

    $ds.tables.Columns.DataType.Name | %{ $tableTypeString += $_ }
    $InsertValues | %{ $inputTypeString += $_.getType().name }

    if ($tableTypeString -eq $inputTypeString){
        # FORMAT INSERT KEYS
        $InsertKeys | % {
            $keysFormatted += [string](Convert-ToSQLColumnName $_)
            if ($_ -ne $InsertKeys[-1]){
                $KeysFormatted += ", "
            }
        }

        # FORMAT INSERT VALUES
        $InsertValues | % {
            if ($_.getType().name -eq "String"){
                $ValuesFormatted += [string](Convert-ToSQLString $_)
            } elseif ($_.getType().name -eq "DateTime"){
                $ValuesFormatted += [string](Convert-ToSQLDateTime $_)
            } else {
                $ValuesFormatted += [string]($_.toString())
            }
            
            if ($_ -ne $InsertValues[-1]){
                $ValuesFormatted += ", "
            }
        }

        # BUILD/EXECUTE QUERY
        $queryText = "INSERT INTO [$database].[$schema].[$table] ($KeysFormatted) VALUES ($ValuesFormatted);"
        write-Verbose $queryText
        $query.CommandText = $queryText
        $query.ExecuteNonQuery()
    } else {
        write-error "Bad insert value passed in`ntable: $tableTypeString`ninput: $inputTypeString"
    }

    $conn.close()
}
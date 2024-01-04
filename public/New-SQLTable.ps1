function New-SQLTable {
    param(
        [Parameter(Mandatory=$true, position=0)]
        [String]$database = "",
        [Parameter(Mandatory=$true, position=1)]
        [String]$table,
        [Parameter(Mandatory=$true, position=2)]
        [Hashtable]$columns = @{},
        [Parameter(Mandatory=$false, position=3)]
        [String]$server,
        [Parameter(Mandatory=$false, position=4)]
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
    
    #######################################################################

    $count = 1
    $columnsFormatted = "("
    $columns.Keys | %{
        $columnsFormatted += ((Convert-ToSQLColumnName $_) + " " + $columns[$_])
        if ($count -ne $columns.count){
            $columnsFormatted += ", "
        }
        $count += 1
    }
    $columnsFormatted += ")"

    $queryString = "CREATE TABLE [$database].[$schema].[$table] $columnsFormatted;"
    $query.CommandText = $queryString
    Write-Verbose $queryString

    $query.ExecuteNonQuery()

    $conn.close()
}
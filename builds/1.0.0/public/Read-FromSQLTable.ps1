function Read-FromSQLTable {
    param(
        [Parameter(Mandatory=$true, position=0)]
        [String]$database,
        [Parameter(Mandatory=$true, position=1)]
        [String]$table = "master",
        [Parameter(Mandatory=$false, position=2)]
        [String]$NumRows = "50",
        [Parameter(Mandatory=$false, position=3)]
        [String]$Schema = "dbo",
        [Parameter(Mandatory=$false, position=4)]
        [String]$server,
        [Parameter(Mandatory=$false, position=5)]
        [Array]$values = ('*'),
        [Parameter(Mandatory=$false)]
        [ValidateSet("Top", "Distinct")]
        [String]$SelectModifier,
        [Parameter(ParameterSetName='Order',Mandatory=$false)]
        [ValidateSet("Ascending", "Descending")]
        [String]$Order,
        [Parameter(ParameterSetName='Order',Mandatory=$false)]
        [String]$OrderBy = "",
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

    try {$SelectModifier = $SelectModifier.toUpper()} catch {}
    try {$Order = $Order.ToUpper()} catch {}
    $ValuesFormatted = ""

    ############# VERIFY INPUT VALUE TYPES ################################

    if ($values.Count -eq 1 -and $values[0] -eq "*"){
        $ValuesFormatted = "*"
    } else {
        $values | % {
            $ValuesFormatted += Convert-ToSQLColumnName $_
            if ($_ -ne $values[-1]){
                $ValuesFormatted += ", "
            }
        }
    }

    ############# QUERY BUILDER ###########################################

    $queryText = "SELECT "

    if ($SelectModifier -eq "TOP" -or $SelectModifier -eq "DISTINCT"){
        $queryText += ("$SelectModifier ($NumRows) ")
    } else {
        if ($NumRows -gt 0){
            $queryText += ("TOP ($NumRows) ")
        }
    }
    
    $queryText += [String]($ValuesFormatted + " FROM [$database].[$schema].[$table]")

    if ($Order -in @("ASCENDING", "DESCENDING")){
        $queryText += " ORDER BY "
        if ($OrderBy -in $values -or $values -eq @('*')){
            if ($OrderBy -eq ""){
                Write-Error "Must Specify value to order by"
                break
            }
            $queryText += $OrderBy
            if ($Order -eq "ASCENDING"){
                $queryText += " ASC"
            } else {
                $queryText += " DESC"
            }
        } else {
            write-error "Key to order by must by included in Keys to select"
            break
        }
    }
    
    $queryText += ";"

    $query.CommandText = $queryText
    Write-Verbose $queryText

    $adapter.SelectCommand = $query
    $adapter.fill($ds)
    
    $conn.close()

    return $ds.tables
}
function Write-ToSQLTable {
    <#
    
        .SYNOPSIS
        Write-ToSQLTable 

        .DESCRIPTION
        
        .PARAMETER InsertKeys
        .PARAMETER InsertValues
        .PARAMETER Table
        .PARAMETER Schema
        .PARAMETER Server
        .PARAMETER Database
        .PARAMETER Conn
    
        .EXAMPLE
    
    #>
    [CmdletBinding(DefaultParameterSetName = 'CreateConn')]
    param(
        [Parameter(Mandatory, ParameterSetName='CreateConn', position=0)]
        [Parameter(Mandatory, ParameterSetName='PassedConn', position=0)]
        [Array]$InsertKeys,
        [Parameter(Mandatory, ParameterSetName='CreateConn', position=1)]
        [Parameter(Mandatory, ParameterSetName='PassedConn', position=1)]
        [Array]$InsertValues,
        [Parameter(ParameterSetName='CreateConn')]
        [Parameter(ParameterSetName='PassedConn')]
        [String]$Table = "master",
        [Parameter(ParameterSetName='CreateConn')]
        [Parameter(ParameterSetName='PassedConn')]
        [String]$Schema = "dbo",
        [Parameter(Mandatory, ParameterSetName='CreateConn', position=2)]
        [Parameter(Mandatory, ParameterSetName='PassedConn', position=2)]
        [String]$Database,
        [Parameter(Mandatory, ParameterSetName='CreateConn', position=3)]
        [String]$Server,
        [Parameter(Mandatory, ParameterSetName='PassedConn', position=3)]
        [System.Data.SqlClient.SqlConnection]$Conn = $null
    )

    ############# INITIALIZE OBJECTS ######################################
    if ($PSCmdlet.ParameterSetName -eq "CreateConn"){
        $conn = New-Object System.Data.SqlClient.SqlConnection
        $conn.ConnectionString = "Server = $($server); Database = $($database); Integrated Security = True"
        try{
            $conn.open()
        } catch [System.Data.SqlClient.SqlException]{
            write-error "database not accessible to user account"
            return $null
        }
    } else {
        $passedConnState = $conn.State
        if ($passedConnState -eq "Closed"){
            $conn.Open()
        }
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
    
    $query.CommandText = "SELECT * FROM [$($database)].[$($schema)].[$($table)];"
    $adapter.SelectCommand = $query
    $adapter.fill($ds)
    
    $ds.tables.Columns.DataType.Name | ForEach-Object{ $tableTypeString += $_ }
    $InsertValues | ForEach-Object{ $inputTypeString += $_.getType().name }
    
    if ($tableTypeString -eq $inputTypeString){
       # FORMAT INSERT KEYS
       $InsertKeys | ForEach-Object {
           $KeysFormatted += [string](Convert-ToSQLColumnName $($_))
           if ($_ -ne $InsertKeys[-1]){
               $KeysFormatted += ", "
           }
       }
    
       # FORMAT INSERT VALUES
       $InsertValues | ForEach-Object {
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
       $queryText = "INSERT INTO [$($database)].[$($schema)].[$($table)] ($($KeysFormatted)) VALUES ($($ValuesFormatted));"
       write-Verbose $queryText
       $query.CommandText = $queryText
       $query.ExecuteNonQuery()
    } else {
        write-error "Bad insert value passed in`ntable: $($tableTypeString)`ninput: $($inputTypeString)"
    }
    
    if ($PSCmdlet.ParameterSetName -eq "CreateConn"){
        $conn.close()
    } else {
        # if passed a connection, ensure that it remains in the state it was in when passed
        if ($passedConnState -ne "Closed"){
            $conn.close()
        }
    }
}

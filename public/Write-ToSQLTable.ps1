function Write-ToSQLTable {
    <#
    
        .SYNOPSIS
        Write-ToSQLTable takes in a hashmap as well as 3 additional strings and one
        other parameter for specifying the server. The hashmap keys must be the same
        as the columns in the table you are attempting to write to

        .DESCRIPTION
        InsertObject object can be given as a parameter or passed into function, then
        one of two parameter sets are used. If you intend to use a connection object
        multiple times, you can pass a [System.Data.SqlClient.SqlConnection] object in
        as the -Connection parameter. Otherwise a Server name is needed to create the 
        connection object in the function. Table, Schema, and Database are needed in
        any calls as they are used to build the SQL commands being ran
        
        .PARAMETER InsertObject
        Input hashmap, meant to correspond to a row of the database. An object being
        passed in should have keys and values that correspond to the columns and 
        data types being stored in the table. If the function finds a mismatch it throws 
        an error

        .PARAMETER Table
        String parameter that specified the SQL table being accessed. Used to build 
        the SQL Commands

        .PARAMETER Schema
        String parameter that specified the SQL schema being accessed. Used to build 
        the SQL Commands

        .PARAMETER Database
        String parameter that specified the SQL Database being accessed. Used to build 
        the SQL Commands

        .PARAMETER Server
        String parameter that specified the SQL Server being accessed. Used to build 
        the SQL Commands

        .PARAMETER Conn
        [System.Data.SqlClient.SqlConnection] object that is used to execute SQL commands
        on the server. A connection object that is passed in is returned to the state it
        was in when passed in.
    
        .EXAMPLE
        Write-ToSQLTable 
            -InsertObject @{col1=1;col2="two";col3=(get-date)} 
            -Table "Test-RunInfo" 
            -Database "ScriptTesting" 
            -Server "SQLSERVER" 
            -Verbose
    
        Write-ToSQLTable 
            -InsertObject @{col1=1;col2="two";col3=(get-date)} 
            -Table "Test-RunInfo" 
            -Database "ScriptTesting" 
            -Connection $conn
            -Verbose
    #>
    [CmdletBinding(DefaultParameterSetName = 'CreateConn')]
    param(
        [Parameter(Mandatory, ParameterSetName='CreateConn', position=0, ValueFromPipeline)]
        [Parameter(Mandatory, ParameterSetName='PassedConn', position=0, ValueFromPipeline)]
        [hashtable]$InsertObject,
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
        [System.Data.SqlClient.SqlConnection]$Connection = $null
    )

    begin{
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

        $query.CommandText = "SELECT * FROM [$($database)].[$($schema)].[$($table)];"
        $adapter.SelectCommand = $query
        $adapter.fill($ds)

        $tableTypes = @{}
        $ds.Tables.Columns | ForEach-Object {
            $tableTypes[$($_.ColumnName)] = $_.DataType.Name
        }

        $InsertObject.Keys | ForEach-Object {
            if ($_ -notin $ds.Tables.Columns.ColumnName){
                Throw "Key in Insert Object hashtable does not correspond to column of selected table"
            }
            if ($InsertObject[$_].GetType().Name -ne $tableTypes[$_]){
                Throw "Invalid type in InsertObject hashmap: $($_)"
            }
        }
    } process {
        $KeysFormatted = ""
        $ValuesFormatted = ""
        $counter = 0
        
        $InsertObject.Keys | ForEach-Object {
            $KeysFormatted += (Convert-ToSQLColumnName $($_))

            if ($tableTypes[$_] -eq "String"){
                $ValuesFormatted += [string](Convert-ToSQLString $($InsertObject[$_]))
            } elseif ($tableTypes[$_] -eq "DateTime"){
                $ValuesFormatted += [string](Convert-ToSQLDateTime $($InsertObject[$_]))
            } else {
                $ValuesFormatted += ($InsertObject[$_]).toString()
            }

            $counter += 1

            if ($counter -lt $InsertObject.Count){
                $ValuesFormatted += ", "
                $KeysFormatted += ", "
            }
        }

        $queryText = "INSERT INTO [$($database)].[$($schema)].[$($table)] ($($KeysFormatted)) VALUES ($($ValuesFormatted));"
        write-Verbose $queryText
        $query.CommandText = $queryText
        $query.ExecuteNonQuery()
    } end {
        if ($PSCmdlet.ParameterSetName -eq "CreateConn"){
            $conn.close()
        } else {
            if ($passedConnState -ne "Closed"){
                $conn.close()
            }
        }
    }
}

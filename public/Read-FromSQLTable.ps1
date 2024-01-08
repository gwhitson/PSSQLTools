function Read-FromSQLTable {
    <#
    
        .SYNOPSIS

        .DESCRIPTION
        
        .PARAMETER SelectKeys
        Array of Strings to be used as column names to select.
        Used as a part of CreateConnSome/PassedConnSome Parameter Sets

        .PARAMETER SelectAll
        Switch to state this will be a 'SELECT *' command.
        Used as a part of CreateConnAll/PassedConnAll Parameter Sets

        .PARAMETER SelectModifier
        Used as a part of CreateConnSome/PassedConnSome Parameter Sets

        .PARAMETER Order

        .PARAMETER OrderBy

        .PARAMETER NumRows
        String parameter that specifies the number of rows to query in combination with 'TOP' Select modifier.
        Used as a part of CreateConnSome/PassedConnSome Parameter Sets

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
    #>
    [CmdletBinding(DefaultParameterSetName = 'CreateConnAll')]
    param(
        [Parameter(Mandatory, ParameterSetName='CreateConnSome', position=0)]
        [Parameter(Mandatory, ParameterSetName='PassedConnSome', position=0)]
        [Array]$SelectKeys,
        [Parameter(Mandatory, ParameterSetName='CreateConnAll', position=0)]
        [Parameter(Mandatory, ParameterSetName='PassedConnAll', position=0)]
        [switch]$SelectAll,
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [ValidateSet("TOP", "DISTINCT")]
        [String]$SelectModifier = "TOP",
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [String]$NumRows = "1",
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [ValidateSet("ASCENDING", "DESCENDING")]
        [String]$Order = "DESCENDING",
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [String]$OrderBy = $null,
        [Parameter(ParameterSetName='CreateConnAll')]
        [Parameter(ParameterSetName='PassedConnAll')]
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [String]$Table = "master",
        [Parameter(ParameterSetName='CreateConnAll')]
        [Parameter(ParameterSetName='PassedConnAll')]
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [String]$Schema = "dbo",
        [Parameter(Mandatory, ParameterSetName='CreateConnAll', position=1)]
        [Parameter(Mandatory, ParameterSetName='PassedConnAll', position=1)]
        [Parameter(Mandatory, ParameterSetName='CreateConnSome', position=1)]
        [Parameter(Mandatory, ParameterSetName='PassedConnSome', position=1)]
        [String]$Database,
        [Parameter(Mandatory, ParameterSetName='CreateConnAll', position=2)]
        [Parameter(Mandatory, ParameterSetName='CreateConnSome', position=2)]
        [String]$Server,
        [Parameter(Mandatory, ParameterSetName='PassedConnAll', position=2)]
        [Parameter(Mandatory, ParameterSetName='PassedConnSome', position=2)]
        [System.Data.SqlClient.SqlConnection]$Connection = $null
    )

    begin{
        if ($PSCmdlet.ParameterSetName -eq "CreateConnAll" -or $PSCmdlet.ParameterSetName -eq "CreateConnSome"){
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

        if ($PSCmdlet.ParameterSetName -eq "CreateConnSome" -or $PSCmdlet.ParameterSetName -eq "PassedConnSome"){
            $query.CommandText = "SELECT * FROM [$($Database)].[$($Schema)].[$($Table)];"
            $adapter.SelectCommand = $query
            $adapter.fill($ds)
            $SelectKeys | ForEach-Object {
                if ($_ -notin $ds.Tables.Columns.ColumnName){
                    Throw "Key in Search Object hashtable does not correspond to column of selected table"
                    return 0;
                }
            }
            if ($SelectModifier -eq "DISTINCT" -and ($SelectKeys.count) -gt 1){
                Throw "`'DISTINCT`' Modifier cannot be used with multiple Select Keys"
            }
        }

    } process {
        $queryText = ""
        $KeysFormatted = ""
        
        if ($PSCmdlet.ParameterSetName -eq "CreateConnAll" -or $PSCmdlet.ParameterSetName -eq "PassedConnAll"){
            $KeysFormatted = "*"
        } else {
            $counter = 0
            $SelectKeys | ForEach-Object {
                $KeysFormatted += (ConvertTo-SQLColumnName $($_))
                    $counter += 1

                    if ($counter -lt $SelectKeys.Count){
                        $KeysFormatted += ", "
                    }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "CreateConnSome" -or $PSCmdlet.ParameterSetName -eq "PassedConnSome"){
            $queryText = "SELECT $($SelectModifier)" 
            if ($SelectModifier -eq "TOP") {
                $queryText += " ($($NumRows))"
            }
            $queryText += " $($KeysFormatted) FROM [$($Database)].[$($Schema)].[$($Table)] ORDER BY $(ConvertTo-SQLColumnName $OrderBy) "
            if ($Order -eq "ASCENDING"){
                $queryText += "ASC;"
            } else {
                $queryText += "DESC;"
            }
        } else {
            $queryText = "SELECT * FROM [$($database)].[$($schema)].[$($table)]"
        }

        write-Verbose $queryText
    } end {
        $ret = New-Object System.Data.DataSet
        $query.CommandText = $queryText
        $adapter.SelectCommand = $query
        $adapter.fill($ret)

        if ($PSCmdlet.ParameterSetName -eq "CreateConnAll" -or $PSCmdlet.ParameterSetName -eq "CreateConnSome"){
            $conn.close()
        } else {
            if ($passedConnState -eq "Closed"){
                $conn.close()
            }
        }
        write-host $PSCmdlet.ParameterSetName
        return $ret.tables
    }
}

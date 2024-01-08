function Read-FromSQLTable {
    <#
    
        .SYNOPSIS

        .DESCRIPTION
        
        .PARAMETER InsertObject
        .PARAMETER Table
        .PARAMETER Schema
        .PARAMETER Database
        .PARAMETER Server
        .PARAMETER Conn
        .EXAMPLE
    #>
    [CmdletBinding(DefaultParameterSetName = 'CreateConnAll')]
    param(
        [Parameter(Mandatory, ParameterSetName='CreateConnSome', position=0)]
        [Parameter(Mandatory, ParameterSetName='PassedConnSome', position=0)]
        [hashtable]$SearchObject,
        [Parameter(Mandatory, ParameterSetName='CreateConnAll', position=0)]
        [Parameter(Mandatory, ParameterSetName='PassedConnAll', position=0)]
        [switch]$SelectAll,
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [ValidateSet("TOP", "DISTINCT")]
        [String]$SelectModifier = "TOP",
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [ValidateSet("ASCENDING", "DESCENDING")]
        [String]$Order = "DESCENDING",
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [String]$OrderBy,
        [Parameter(ParameterSetName='CreateConnSome')]
        [Parameter(ParameterSetName='PassedConnSome')]
        [String]$NumRows = "1",
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
            $SearchObject.Keys | ForEach-Object {
                if ($_ -notin $ds.Tables.Columns.ColumnName){
                    Throw "Key in Search Object hashtable does not correspond to column of selected table"
                    return 0;
                }
            }
        }

    } process {
        $queryText = ""
        $KeysFormatted = ""
        $counter = 0
        
        if ($PSCmdlet.ParameterSetName -eq "CreateConnAll" -or $PSCmdlet.ParameterSetName -eq "PassedConnAll"){
            $KeysFormatted = "*"
        } else {
            $SearchObject.Keys | ForEach-Object {
                $KeysFormatted += (ConvertTo-SQLColumnName $($_))
                    $counter += 1

                    if ($counter -lt $SearchObject.Count){
                        $KeysFormatted += ", "
                    }
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "CreateConnSome" -or $PSCmdlet.ParameterSetName -eq "PassedConnSome"){
            $queryText = "SELECT $($SelectModifier)" 
            if ($SelectModifier -eq "TOP") {
                $queryText += " ($($NumRows)) "
            }
            $queryText += " $($KeysFormatted) FROM [$($Database)].[$($Schema)].[$($Table)];"
        } else {
            $queryText = "SELECT * FROM [$($database)].[$($schema)].[$($table)];"
        }

        write-Verbose $queryText
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

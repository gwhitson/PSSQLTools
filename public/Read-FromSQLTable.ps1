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

        if ($PSCmdlet.ParameterSetName -eq "CreateConnAll" -or $PSCmdlet.ParameterSetName -eq "PassedConnAll"){
            $query.CommandText = "SELECT * FROM [$($database)].[$($schema)].[$($table)];"
            $adapter.SelectCommand = $query
            $adapter.fill($ds)
        } else {
            $SearchObject.Keys | ForEach-Object {
                if ($_ -notin $ds.Tables.Columns.ColumnName){
                    Throw "Key in Search Object hashtable does not correspond to column of selected table"
                    return 0;
                }
            }
        }

    } process {
        $queryText = ""
        $queryOptions = ""
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
                        write-error "Key to order by must be included in keys to select"
                            break
                    }
            }

        $queryText += ";"

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

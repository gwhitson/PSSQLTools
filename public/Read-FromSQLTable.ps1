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
    [CmdletBinding(DefaultParameterSetName = 'CreateConn')]
    param(
        [Parameter(Mandatory, ParameterSetName='SelectSome', position=0, ValueFromPipeline)]
        [hashtable]$SearchObject,
        [Parameter(Mandatory, ParameterSetName='SelectAll', position=0)]
        [switch]$SelectAll,
        [Parameter(ParameterSetName="SelectSome", HelpMessage="Default Value is `'TOP`'")]
        [ValidateSet("TOP", "DISTINCT")]
        [String]$SelectModifier = "TOP",
        [Parameter(ParameterSetName="SelectSome", HelpMessage="Default Value is `'DESCENDING`'")]
        [ValidateSet("ASCENDING", "DESCENDING")]
        [String]$Order = "DESCENDING",
        [Parameter(ParameterSetName="SelectSome", HelpMessage="Default Value is first key in Search Object")]
        [String]$OrderBy = $($SearchObject.keys)[0],
        [Parameter(ParameterSetName="SelectSome", HelpMessage="Default Value is 1")]
        [String]$NumRows = "1",
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

        $SearchObject.Keys | ForEach-Object {
            if ($_ -notin $ds.Tables.Columns.ColumnName){
                Throw "Key in Search Object hashtable does not correspond to column of selected table"
                return 0;
            }
        }
    } process {
        $queryText = ""
        $KeysFormatted = ""
        $counter = 0
        
        $SearchObject.Keys | ForEach-Object {
            $KeysFormatted += (ConvertTo-SQLColumnName $($_))
            $counter += 1

            if ($counter -lt $SearchObject.Count){
                $KeysFormatted += ", "
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

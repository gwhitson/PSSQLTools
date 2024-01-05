function New-SQLTable {
    <#
    
        .SYNOPSIS
        
        .DESCRIPTION
        
        .PARAMETER filepath
    
        .EXAMPLE
    
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
    <#param(
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
    )#>

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
        $columnsFormatted += ((ConvertTo-SQLColumnName $_) + " " + $columns[$_])
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

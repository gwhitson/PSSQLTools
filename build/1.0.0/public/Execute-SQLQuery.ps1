function Execute-SQLQuery {
    param(
        [Alias("Query")]
        [Parameter(Mandatory=$true, position=0)]
        [String]$queryText= "",
        [Parameter(Mandatory=$true, position=1)]
        [String]$database = "",
        [Parameter(Mandatory=$false, position=2)]
        [String]$server,
        [Parameter(Mandatory=$false, ValueFromPipeline)]
        [System.Data.SqlClient.SqlConnection]$conn = $null
    )

    ############# INITIALIZE OBJECTS ######################################
    if ($conn -eq $null){
        if ($server -eq ""){
            write-error "Server needed if connection not given"
            break
        }
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

    $queryString = $queryText
    $query.CommandText = $queryString
    Write-Verbose $queryString

    $query.ExecuteNonQuery()

    $conn.close()
}
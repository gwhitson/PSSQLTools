function Convert-ToSQLDateTime {
    <#
    
        .SYNOPSIS
        Convert-ToSQLDateTime converts a DataTie object into a SQL Query compatible DateTime string
        
        .DESCRIPTION
        Requires a valid DateTime object and converts it into a string compatible with the SQL DateTime datatype
        
        .PARAMETER Date
        Date to be formatted for use in SQL Queries
    
        .EXAMPLE
        Convert-ToSQLDateTime (get-date)
    
    #>
    param(
        [Alias("Input")]
        [ValidateNotNullOrEmpty()]
        [DateTime]$date
    )
    return $date.toString("\'yyyy-MM-dd HH:mm:ss\'")
}
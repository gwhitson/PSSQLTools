function ConvertTo-SQLString{
    <#
    
        .SYNOPSIS
        ConvertTo-SQLString intakes a variable and ensures it is a PowerShell comaptible string. It then formats it for use in SQL Queries

        .DESCRIPTION
        Designed primarily for use with integers, and strings. Ensures that they are formatted properly for use in SQL Queries
        
        .PARAMETER Input
        Input to be converted to an SQL Query Compatible string
    
        .EXAMPLE
        ConvertTo-SQLString "this is a test string"
    
    #>
    param(
        [Alias("Input")]
        [ValidateNotNullOrEmpty()]
        $Inval
    )
    return ("`'" + ($Inval.toString()) + "`'")
}

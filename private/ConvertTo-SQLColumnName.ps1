function ConvertTo-SQLColumnName{
    <#
    
        .SYNOPSIS
        ConvertTo-SQLColumnName intakes a variable and ensures it is a PowerShell comaptible string. It then formats it for use as a Column Name for an SQL Query

        .DESCRIPTION
        Designed primarily for use with integers, and strings. Ensures that they are formatted properly for use as a Column Name for an SQL Query
        
        .PARAMETER Input
        Input to be converted to string usable as a Column Name for an SQL Query
    
        .EXAMPLE
        ConvertTo-SQLColumnName "col1"
    
    #>
    param(
        [Alias("Input")]
        [ValidateNotNullOrEmpty()]
        $Inval
    )
    return ("[$($Inval)]")
}

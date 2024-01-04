<#
    .SYNOPSIS
    converts a given PowerShell DateTime Object into a string compatible with the Microsoft SQL Server Version of a datetime
#>
function Convert-ToSQLDateTime {
    param(
        [datetime]$date
    )
    return ("`'" + (get-date $date -format "yyyy-MM-dd HH:mm:ss").ToString() + "`'")
}
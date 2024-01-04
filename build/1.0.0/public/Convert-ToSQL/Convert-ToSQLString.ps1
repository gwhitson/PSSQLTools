function Convert-ToSQLString{
    param(
        [ValidateNotNullOrEmpty()]
        $inString
    )
    return ("`'" + ($inString.toString()) + "`'")
}
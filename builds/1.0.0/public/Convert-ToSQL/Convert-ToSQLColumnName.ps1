function Convert-ToSQLColumnName{
    param(
        [ValidateNotNullOrEmpty()]
        $inString
    )
    return ("[" + ($inString.toString()) + "]")
}
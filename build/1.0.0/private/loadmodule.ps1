$publ = @(Get-ChildItem -Path "$PSScriptRoot\public\*.ps1" -ErrorAction SilentlyContinue -Recurse)
$priv = @(Get-ChildItem -Path "$PSScriptRoot\private\*.ps1" -ErrorAction SilentlyContinue -Recurse)

foreach ($script in ($publ + $priv)){
    try {
        write-host $($script.fullname)
        . $script.Fullname
    } catch {
        Write-host "Failed to import functions from $($script.Fullname)"
    }
}

#Export-ModuleMember -Function '*' -Alias '*'
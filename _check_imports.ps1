$etsDir = 'entry/src/main/ets'
Get-ChildItem -Recurse -Filter '*.ets' -Path $etsDir | ForEach-Object {
    $path = $_.FullName
    if ($path -match 'AppTheme\.ets$') { return }
    $content = Get-Content $path -Raw
    if ($content -match "TC\('" -and $content -notmatch "import.*\bTC\b.*from") {
        Write-Host "MISSING TC IMPORT: $($_.Name)"
    }
}

Set-Location 'E:\APP\family_food_app'
$hexColors = @{}
Get-ChildItem -Recurse -Filter '*.ets' -Path 'entry/src/main/ets' | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $matches = [regex]::Matches($content, "'#([0-9A-Fa-f]{6,8})'")
    foreach ($m in $matches) {
        $hex = $m.Groups[1].Value.ToUpper()
        if ($hex.Length -eq 6) { $hexColors[$hex] = 1 }
    }
}
Write-Host "=== Unique hex colors (excluding 8-char alpha) ==="
$hexColors.Keys | Sort-Object | ForEach-Object { Write-Host $_ }
Write-Host "Total unique: $($hexColors.Count)"

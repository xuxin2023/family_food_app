$file = 'E:\APP\family_food_app\entry\src\main\ets\components\NutrientRadarPanel.ets'
$lines = Get-Content $file
Write-Host "Total lines: $($lines.Count)"
foreach ($line in $lines[28..38]) {
    Write-Host $line
}

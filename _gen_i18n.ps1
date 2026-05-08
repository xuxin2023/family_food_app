$ErrorActionPreference = "Stop"
$basePath = 'E:\APP\family_food_app\entry\src\main\resources'

# Read base JSON - manual string parsing since ConvertFrom-Json might not work
$baseContent = Get-Content (Join-Path $basePath 'base\element\string.json') -Raw
$zhContent = Get-Content (Join-Path $basePath 'zh_CN\element\string.json') -Raw
$enContent = Get-Content (Join-Path $basePath 'en_US\element\string.json') -Raw

# Output the lengths
Write-Host ("base length: " + $baseContent.Length)
Write-Host ("zh_CN length: " + $zhContent.Length)
Write-Host ("en_US length: " + $enContent.Length)

# Write result to a file to read back
$baseContent | Out-File 'E:\APP\family_food_app\_raw_base.json'
$zhContent | Out-File 'E:\APP\family_food_app\_raw_zh.json'
$enContent | Out-File 'E:\APP\family_food_app\_raw_en.json'
Write-Host "Done writing raw files"

# Step 1: DOMAIN_ZERO → HILOG_DOMAIN.DEFAULT for remaining 9 files
Set-Location 'E:\APP\family_food_app'
$root = 'entry/src/main/ets'

# (relative_file, import_path)
$files = @(
    @('service\sync\SyncService.ets', '..\..\constants\AppConfig'),
    @('service\sync\CloudStorageProvider.ets', '..\..\constants\AppConfig'),
    @('service\share\CopyTextProvider.ets', '..\..\constants\AppConfig'),
    @('service\health\ManualHealthSignalProvider.ets', '..\..\constants\AppConfig'),
    @('service\ai\AiServiceBase.ets', '..\..\constants\AppConfig'),
    @('service\health\HwHealthSignalProvider.ets', '..\..\constants\AppConfig'),
    @('service\ai\AiClient.ets', '..\..\constants\AppConfig'),
    @('ServiceManager.ets', '.\constants\AppConfig'),
    @('AppState.ets', '.\constants\AppConfig')
)

foreach ($entry in $files) {
    $relPath = $entry[0]
    $importFrom = $entry[1]
    $fullPath = Join-Path $root $relPath

    $content = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)

    # Check if already done
    if ($content -match 'HILOG_DOMAIN\.DEFAULT') {
        Write-Host "SKIP: $relPath (already done)"
        continue
    }

    # Insert import after last existing import
    $lines = @($content) -replace "`r`n", "`n" -split "`n"
    $lastImportIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*import\s') { $lastImportIdx = $i }
    }
    if ($lastImportIdx -lt 0) { Write-Host "FAIL: $relPath (no imports)"; continue }

    $importLine = "import { HILOG_DOMAIN } from '$importFrom';"
    $newLines = $lines[0..$lastImportIdx] + $importLine + $lines[($lastImportIdx+1)..($lines.Count-1)]
    $content = $newLines -join "`r`n"

    # Replace const DOMAIN_ZERO = 0;
    $content = $content -replace 'const DOMAIN_ZERO\s*=\s*0\s*;', 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'

    [System.IO.File]::WriteAllText($fullPath, $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "DONE: $relPath"
}
Write-Host "=== Complete ==="

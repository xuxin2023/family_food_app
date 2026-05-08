# Step 1 v5: Match complete import statements (ending with ;)
Set-Location 'E:\APP\family_food_app'
$root = 'entry\src\main\ets'
$ErrorActionPreference = 'Continue'

$depth1 = @('pages','components','utils','service','repository','manager','entryability')
$rootFiles = @('ServiceManager.ets','AppState.ets')
$depth2 = @('service\sync','service\health','service\share','service\ai')

function Fix-File($relFile, $importPath) {
    $full = Join-Path $root $relFile
    if (-not (Test-Path $full)) { return }

    $lines = [System.IO.File]::ReadAllLines($full, [System.Text.Encoding]::UTF8)
    $hasIt = $false
    foreach ($l in $lines) { if ($l -match 'HILOG_DOMAIN\.DEFAULT') { $hasIt = $true; break } }
    if ($hasIt) { Write-Host "SKIP: $relFile"; return }

    # Find last complete import line (single-line import ending with ; OR multi-line end '} from ...')
    $lastImport = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        # Match: single-line import with semicolon, OR closing of multi-line import
        if ($l -match '^\s*import\s+.*;\s*$' -or $l -match '^\s*\}\s*from\s+.*;\s*$') {
            $lastImport = $i
        }
    }
    if ($lastImport -lt 0) { Write-Host "NOIMPORT: $relFile"; return }

    # Build output
    $out = @()
    for ($i = 0; $i -le $lastImport; $i++) { $out += $lines[$i] }
    $out += "import { HILOG_DOMAIN } from '$importPath';"
    for ($i = $lastImport + 1; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ($line -match '^\s*const\s+DOMAIN_ZERO\s*=\s*0\s*;\s*$') {
            $out += 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'
        } else {
            $out += $line
        }
    }

    [System.IO.File]::WriteAllText($full, ($out -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
    Write-Host "DONE: $relFile"
}

foreach ($dir in $depth1) {
    $dirPath = Join-Path $root $dir
    if (-not (Test-Path $dirPath)) { continue }
    Get-ChildItem -Path $dirPath -Filter *.ets | % { Fix-File "$dir\$($_.Name)" '../constants/AppConfig' }
}
foreach ($dir in $depth2) {
    $dirPath = Join-Path $root $dir
    if (-not (Test-Path $dirPath)) { continue }
    Get-ChildItem -Path $dirPath -Filter *.ets | % { Fix-File "$dir\$($_.Name)" '../../constants/AppConfig' }
}
foreach ($f in $rootFiles) { Fix-File $f './constants/AppConfig' }
Write-Host '=== Complete ==='

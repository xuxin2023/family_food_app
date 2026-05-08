# Step 1 final: use -replace for path splitting, simple approach
Set-Location 'E:\APP\family_food_app'
$root = 'entry\src\main\ets'
$ErrorActionPreference = 'Continue'

# Directories at depth 1 (relative to root) -> '../constants/AppConfig'
$depth1 = @(
    'pages','components','utils','service','repository','manager','entryability'
)

# Files at root level -> './constants/AppConfig'
$rootFiles = @('ServiceManager.ets','AppState.ets')

# Subdirs at depth 2 -> '../../constants/AppConfig'
$depth2 = @(
    'service\sync','service\health','service\share','service\ai'
)

function Fix-File($relFile, $importPath) {
    $full = Join-Path $root $relFile
    if (-not (Test-Path $full)) { return }

    $content = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
    if ($content -match 'HILOG_DOMAIN\.DEFAULT') { 
        Write-Host "SKIP: $relFile" 
        return 
    }
    if ($content -notmatch 'const DOMAIN_ZERO\s*=\s*0\s*;') {
        Write-Host "SKIP(no target): $relFile"
        return
    }

    # Split into lines
    $lines = $content -split '\r?\n'
    $out = @()
    $done = $false
    foreach ($line in $lines) {
        if (-not $done -and $line -match '^\s*const\s+DOMAIN_ZERO\s*=\s*0\s*;\s*$') {
            $out += "import { HILOG_DOMAIN } from '$importPath';"
            $out += 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'
            $done = $true
        } else {
            $out += $line
        }
    }
    [System.IO.File]::WriteAllText($full, ($out -join "`r`n"), [System.Text.UTF8Encoding]::new($false))
    Write-Host "DONE: $relFile"
}

# Process depth1 directories
foreach ($dir in $depth1) {
    $dirPath = Join-Path $root $dir
    if (-not (Test-Path $dirPath)) { continue }
    Get-ChildItem -Path $dirPath -Filter *.ets | ForEach-Object {
        Fix-File "$dir\$($_.Name)" '../constants/AppConfig'
    }
}

# Process depth2 directories
foreach ($dir in $depth2) {
    $dirPath = Join-Path $root $dir
    if (-not (Test-Path $dirPath)) { continue }
    Get-ChildItem -Path $dirPath -Filter *.ets | ForEach-Object {
        Fix-File "$dir\$($_.Name)" '../../constants/AppConfig'
    }
}

# Process root files
foreach ($f in $rootFiles) {
    Fix-File $f './constants/AppConfig'
}

Write-Host '=== Complete ==='

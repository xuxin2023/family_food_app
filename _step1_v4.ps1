# Step 1 v4: Insert import after LAST import line, then replace DOMAIN_ZERO
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
    $out = @()
    $importInserted = $false
    $constReplaced = $false
    $foundImportBlock = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Check if already migrated
        if ($line -match 'HILOG_DOMAIN\.DEFAULT') {
            Write-Host "SKIP: $relFile"
            return
        }

        # Track if we've seen the first non-import, non-comment line
        $isImport = $line -match '^\s*import\s'
        $isCommentOrBlank = $line -match '^\s*(//|/\*|\*|\s*$)'

        if (-not $importInserted) {
            if ($isImport) {
                $foundImportBlock = $true
                $out += $line
            } elseif ($isCommentOrBlank -and -not $foundImportBlock) {
                $out += $line
            } else {
                # First non-import line after import block - insert here
                $out += "import { HILOG_DOMAIN } from '$importPath';"
                $importInserted = $true
                # Fall through to process current line
            }
        }

        if ($importInserted) {
            if (-not $constReplaced -and $line -match '^\s*const\s+DOMAIN_ZERO\s*=\s*0\s*;\s*$') {
                $out += 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'
                $constReplaced = $true
            } else {
                $out += $line
            }
        }
    }

    if (-not $constReplaced) {
        Write-Host "WARN ($relFile): DOMAIN_ZERO not found"
        return
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

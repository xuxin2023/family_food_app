# Step 1 v3: DOMAIN_ZERO → HILOG_DOMAIN.DEFAULT
# Strategy: Insert import + modify const line atomically, avoid touching multi-line imports

Set-Location 'E:\APP\family_food_app'
$root = 'entry\src\main\ets'

# Build file list: find all files with 'const DOMAIN_ZERO = 0;'
$allMatches = Select-String -Path "$root\**\*.ets" -Pattern 'const DOMAIN_ZERO\s*=\s*0\s*;' -SimpleMatch
$files = @{}
foreach ($m in $allMatches) {
    $rel = $m.Path.Substring($root.Length + 1)
    if (-not $files.ContainsKey($rel)) {
        $files[$rel] = @()
    }
    $files[$rel] += $m.LineNumber
}

# Compute import path for each file
function Get-ImportPath($relPath) {
    $dir = [System.IO.Path]::GetDirectoryName($relPath)
    if ($dir -eq '') { return './constants/AppConfig' }
    $depths = ($dir.Split([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) | Where-Object { $_ -ne '' }).Count
    $prefix = if ($depths -eq 0) { './' } else { ('../' * $depths) }
    return $prefix + 'constants/AppConfig'
}

$count = 0
foreach ($rel in $files.Keys) {
    $fullPath = Join-Path $root $rel
    $importPath = Get-ImportPath $rel

    # Read all lines
    $lines = [System.IO.File]::ReadAllLines($fullPath, [System.Text.Encoding]::UTF8)
    $newLines = @()
    $inserted = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Check if this line is a 'const DOMAIN_ZERO = 0;' line
        if ($line -match '^\s*const\s+DOMAIN_ZERO\s*=\s*0\s*;\s*$') {
            if (-not $inserted) {
                # Insert import BEFORE this line
                $newLines += "import { HILOG_DOMAIN } from '$importPath';"
                $inserted = $true
            }
            # Replace the line
            $newLines += $line -replace 'const\s+DOMAIN_ZERO\s*=\s*0\s*;', 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'
        } elseif ($line -match '\bHILOG_DOMAIN\b') {
            # Already migrated
            Write-Host "SKIP: $rel (already has HILOG_DOMAIN)"
            $newLines = $null
            break
        } else {
            $newLines += $line
        }
    }

    if ($newLines -eq $null) { continue }

    # Write back
    $content = $newLines -join "`r`n"
    [System.IO.File]::WriteAllText($fullPath, $content, [System.Text.UTF8Encoding]::new($false))
    $count++
    Write-Host "DONE: $rel"
}

Write-Host "=== $count files updated ==="

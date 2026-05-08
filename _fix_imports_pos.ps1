# Fix all misplaced TC imports across all directories
Set-Location 'E:\APP\family_food_app'

Get-ChildItem -Recurse -Filter '*.ets' -Path 'entry/src/main/ets' | ForEach-Object {
    $path = $_.FullName
    $lines = Get-Content $path
    $content = [string]::Join("`r`n", $lines)
    $original = $content

    # Find ALL lines containing "import { TC } from"
    $importLines = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "import\s+\{[^}]*\bTC\b[^}]*\}\s+from") {
            $importLines += $i
        }
    }

    # If there's an import on line > 5, it's probably misplaced (after code)
    if ($importLines.Count -gt 0 -and $importLines[0] -gt 5) {
        Write-Host "BAD IMPORT in $($_.Name) at line $($importLines[0]+1)" -ForegroundColor Yellow
        # Remove all existing TC imports
        for ($i = $importLines.Count - 1; $i -ge 0; $i--) {
            $lineNum = $importLines[$i]
            $lines = $lines[0..($lineNum-1)] + $lines[($lineNum+1)..($lines.Count-1)]
        }
        # Add TC import at line 1 (after any file comment)
        $insertPos = 0
        if ($lines.Count -gt 0 -and $lines[0] -match '^//') { $insertPos = 1 }
        if ($lines.Count -gt 1 -and $lines[1] -match '^//') { $insertPos = 2 }
        $newLines = $lines[0..($insertPos-1)] + @('', "import { TC } from '../constants/AppTheme';") + $lines[$insertPos..($lines.Count-1)]
        $content = [string]::Join("`r`n", $newLines)
        Set-Content $path $content -NoNewline
    }
    elseif ($importLines.Count -gt 1) {
        Write-Host "DUPLICATE IMPORT in $($_.Name)" -ForegroundColor Yellow
        # Remove all duplicates, keep only the first
        for ($i = $importLines.Count - 1; $i -ge 1; $i--) {
            $lineNum = $importLines[$i]
            $lines = $lines[0..($lineNum-1)] + $lines[($lineNum+1)..($lines.Count-1)]
        }
        $content = [string]::Join("`r`n", $lines)
        Set-Content $path $content -NoNewline
    }
}
Write-Host "Fix complete!"

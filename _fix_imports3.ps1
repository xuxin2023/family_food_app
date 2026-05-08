# Fix imports: add TC, remove COLORS
Set-Location 'E:\APP\family_food_app'

$targetDirs = @('pages', 'components', 'engine', 'model', 'widget')
foreach ($dir in $targetDirs) {
    $etsFiles = Get-ChildItem -Recurse -Filter '*.ets' -Path "entry/src/main/ets/$dir"
    foreach ($f in $etsFiles) {
        $content = Get-Content $f.FullName -Raw
        $original = $content
        $changed = $false

        # Remove COLORS from import (handle various patterns)
        if ($content -match 'COLORS, ') { $content = $content -replace 'COLORS, ', ''; $changed = $true }
        if ($content -match ', COLORS') { $content = $content -replace ', COLORS', ''; $changed = $true }
        if ($content -match 'import \{ COLORS \}') { $content = $content -replace 'import \{ COLORS \}', ''; $changed = $true }
        # Clean up any double commas or spaces
        if ($changed) {
            $content = $content -replace 'import \{ ,', 'import {'
            $content = $content -replace 'import \{  ', 'import { '
        }

        # Add TC import if TC() is used but not imported
        if ($content -match "TC\('" -and $content -notmatch "import.*\bTC\b.*from") {
            if ($content -match "import \{.+?\} from '.*AppTheme'") {
                $content = $content -replace "(import \{)(.+?)(\} from '.*AppTheme')", ('$1$2, TC$3')
            } else {
                # No AppTheme import, add one after other imports
                $content = $content -replace "`r`n`r`n", ("`r`nimport { TC } from '../constants/AppTheme';`r`n`r`n")
            }
            $changed = $true
        }

        if ($changed) {
            Set-Content $f.FullName $content -NoNewline
            Write-Host "Fixed import: $dir/$($f.Name)"
        }
    }
}
Write-Host "Import fix complete!"

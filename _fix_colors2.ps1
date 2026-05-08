# Step 2b fix: Handle remaining COLORS.WHITE and add TC imports
Set-Location 'E:\APP\family_food_app'

$etsFiles = Get-ChildItem -Recurse -Filter '*.ets' -Path 'entry/src/main/ets' | Where-Object { $_.FullName -notmatch 'AppTheme\.ets$' }

foreach ($f in $etsFiles) {
    $content = Get-Content $f.FullName -Raw
    $original = $content
    $needsImport = $false

    # Fix remaining COLORS.WHITE -> TC('TEXT_WHITE')
    $content = $content -replace 'COLORS\.WHITE\b', "TC('TEXT_WHITE')"

    # Fix remaining hardcoded hexes not covered by first pass
    $content = $content -replace "\.fontColor\('#666666'\)", ".fontColor(TC('TEXT_SECONDARY'))"
    $content = $content -replace "\.backgroundColor\('#80000000'\)", ".backgroundColor(TC('OVERLAY'))"
    $content = $content -replace "\.backgroundColor\('#33000000'\)", ".backgroundColor(TC('SHADOW'))"

    # If file uses TC() but doesn't import it, add import
    if ($content -match "TC\('" -and $content -notmatch "import.*TC\b.*from") {
        $needsImport = $true
        # Find existing import from AppTheme
        if ($content -match "import \{ .*\} from '.*AppTheme'") {
            # Add TC to existing import
            $content = $content -replace "(import \{[^}]*)\} from '(\.\.\/)*constants\/AppTheme'", ('$1, TC } from ''$2constants/AppTheme''')
        } else {
            # Add new import line after any other import
            $content = $content -replace "(import.*?from '.*?'\r?\n)", ('$1' + "import { TC } from '../constants/AppTheme';`r`n")
        }
    }

    if ($content -ne $original) {
        Set-Content $f.FullName $content -NoNewline
        Write-Host "Fixed: $($f.Name)"
    }
}

Write-Host "Fix complete!"

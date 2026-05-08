# Cleanup: remove COLORS from imports
Set-Location 'E:\APP\family_food_app'

$etsFiles = Get-ChildItem -Recurse -Filter '*.ets' -Path 'entry/src/main/ets' | Where-Object { $_.FullName -notmatch 'AppTheme\.ets$' }

foreach ($f in $etsFiles) {
    $content = Get-Content $f.FullName -Raw
    $original = $content
    $changed = $false

    # Remove COLORS from imports (handles various patterns)
    # Pattern: import { COLORS, TC } -> import { TC }
    $content = $content -replace "import \{ COLORS , TC ", "import { TC "
    # Pattern: import { COLORS }, TC } -> import { TC }
    $content = $content -replace "import \{ COLORS, TC", "import { TC"
    # Pattern: import { COLORS , BUTTON -> import { BUTTON
    $content = $content -replace "import \{ COLORS , ", "import { "
    # Pattern: import { COLORS, XXX -> import { XXX
    $content = $content -replace "import \{ COLORS, ", "import { "
    # Pattern: import { XXX, COLORS } -> import { XXX }
    $content = $content -replace ", COLORS \} from", " } from"
    $content = $content -replace ", COLORS\} from", " } from"
    # Pattern: import { COLORS } alone -> remove line completely
    # tricky, skip for now

    # also fix double spaces like '  ,' -> ' ,'
    $content = $content -replace "  ,", " ,"
    # fix ' , ' -> ', '
    $content = $content -replace " , ", ", "

    if ($content -ne $original) {
        Set-Content $f.FullName $content -NoNewline
        Write-Host "Cleaned: $($f.Name)"
    }
}

Write-Host "Cleanup complete!"

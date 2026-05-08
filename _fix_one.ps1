# Apply colors migration to a single file
param($file)
Set-Location 'E:\APP\family_food_app'
$content = Get-Content $file -Raw
$original = $content

# COLORS replacements
$content = $content -replace 'COLORS\.PRIMARY\b', "TC('PRIMARY')"
$content = $content -replace 'COLORS\.PRIMARY_LIGHT\b', "TC('PRIMARY_LIGHT')"
$content = $content -replace 'COLORS\.PRIMARY_DARK\b', "TC('PRIMARY_DARK')"
$content = $content -replace 'COLORS\.SECONDARY\b', "TC('SECONDARY')"
$content = $content -replace 'COLORS\.SUCCESS\b', "TC('SUCCESS')"
$content = $content -replace 'COLORS\.WARNING\b', "TC('WARNING')"
$content = $content -replace 'COLORS\.ERROR\b', "TC('ERROR')"
$content = $content -replace 'COLORS\.ACCENT_BLUE\b', "TC('ACCENT_BLUE')"
$content = $content -replace 'COLORS\.ACCENT_PURPLE\b', "TC('ACCENT_PURPLE')"
$content = $content -replace 'COLORS\.TEXT_PRIMARY\b', "TC('TEXT_PRIMARY')"
$content = $content -replace 'COLORS\.TEXT_SECONDARY\b', "TC('TEXT_SECONDARY')"
$content = $content -replace 'COLORS\.TEXT_TERTIARY\b', "TC('TEXT_TERTIARY')"
$content = $content -replace 'COLORS\.WHITE\b', "TC('TEXT_WHITE')"
$content = $content -replace 'COLORS\.BG_PAGE\b', "TC('BG_PAGE')"
$content = $content -replace 'COLORS\.BG_CARD\b', "TC('BG_CARD')"
$content = $content -replace 'COLORS\.BG_CARD_HIGHLIGHT\b', "TC('BG_CARD_HIGHLIGHT')"
$content = $content -replace 'COLORS\.BG_GRADIENT_START\b', "TC('BG_GRADIENT_START')"
$content = $content -replace 'COLORS\.BG_GRADIENT_END\b', "TC('BG_GRADIENT_END')"
$content = $content -replace 'COLORS\.BG_LIGHT\b', "TC('BG_LIGHT')"
$content = $content -replace 'COLORS\.SHADOW_LIGHT\b', "TC('SHADOW_LIGHT')"
$content = $content -replace 'COLORS\.SHADOW\b', "TC('SHADOW')"
$content = $content -replace 'COLORS\.DIVIDER\b', "TC('DIVIDER')"
$content = $content -replace 'COLORS\.BORDER\b', "TC('BORDER')"

# Hex replacements
$content = $content -replace "'#FFD700'", "TC('YELLOW_GOLD')"
$content = $content -replace "'#4CAF50'", "TC('LEVEL_GREEN')"
$content = $content -replace "'#2196F3'", "TC('ACCENT_BLUE_2196')"
$content = $content -replace "'#E0E0E0'", "TC('BORDER')"
$content = $content -replace "'#FFFDE7'", "TC('BG_LIGHT_GOLD')"
$content = $content -replace "'#F1F8E9'", "TC('BG_LIGHT_BLUE')"
$content = $content -replace "'#E3F2FD'", "TC('BG_WARM_BLUE')"
$content = $content -replace "'#FFFFFF'", "TC('TEXT_WHITE')"

# Fix import: remove COLORS, add TC
$content = $content -replace 'COLORS, ', ''
$content = $content -replace '(\} from .*AppTheme)', ', TC$1'

Set-Content $file $content -NoNewline
Write-Host "Done: $file"

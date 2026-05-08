# Step 2: Color migration script
Set-Location 'E:\APP\family_food_app'

$etsFiles = Get-ChildItem -Recurse -Filter '*.ets' -Path 'entry/src/main/ets' | Where-Object { $_.FullName -notmatch 'AppTheme\.ets$' }

$totalFiles = @($etsFiles).Count
$idx = 0

foreach ($f in $etsFiles) {
    $idx++
    $content = Get-Content $f.FullName -Raw
    $original = $content
    $changed = $false

    # === PHASE 1: Contextual COLORS.WHITE replacement ===
    # fontColor(COLORS.WHITE) -> fontColor(TC('TEXT_WHITE'))
    $content = $content -replace '\.fontColor\(COLORS\.WHITE\)', ".fontColor(TC('TEXT_WHITE'))"
    # backgroundColor(COLORS.WHITE) -> backgroundColor(TC('BG_CARD'))
    $content = $content -replace '\.backgroundColor\(COLORS\.WHITE\)', ".backgroundColor(TC('BG_CARD'))"
    # color(COLORS.WHITE) -> color(TC('TEXT_WHITE'))
    $content = $content -replace '\.color\(COLORS\.WHITE\)', ".color(TC('TEXT_WHITE'))"
    # fill(COLORS.WHITE) -> fill(TC('TEXT_WHITE'))
    $content = $content -replace '\.fill\(COLORS\.WHITE\)', ".fill(TC('TEXT_WHITE'))"

    # === PHASE 2: Special COLORS mappings ===
    $content = $content -replace 'COLORS\.BLACK\b', "TC('TEXT_PRIMARY')"
    $content = $content -replace 'COLORS\.PURPLE_ACCENT\b', "TC('ACCENT_PURPLE_7B1F')"

    # === PHASE 3: Mechanical COLORS.XXX -> TC('XXX') ===
    $colorFields = @(
        'PRIMARY_DARK','PRIMARY_LIGHT','SECONDARY','SUCCESS','WARNING','ERROR',
        'ACCENT_BLUE','ACCENT_PURPLE',
        'TEXT_PRIMARY','TEXT_SECONDARY','TEXT_TERTIARY','TEXT_WHITE',
        'BG_PAGE','BG_CARD','BG_CARD_HIGHLIGHT','BG_GRADIENT_START','BG_GRADIENT_END','BG_LIGHT',
        'BORDER','DIVIDER','SHADOW','DOT_INACTIVE',
        'LEVEL_GREEN','LEVEL_YELLOW','LEVEL_ORANGE','LEVEL_RED',
        'ORANGE_ACCENT','ORANGE_DEEP',
        'ACCENT_GREEN_4CAF','ACCENT_GREEN_66BB','ACCENT_RED_EF53','ACCENT_RED_F443',
        'ACCENT_ORANGE_FFA7','ACCENT_ORANGE','ACCENT_PURPLE_9C27',
        'BG_WARM_ORANGE','BG_WARM_PINK','BG_WARM_PURPLE','BG_WARM_BLUE','BG_WARM_YELLOW','BG_LIGHT_GREEN'
    )
    foreach ($field in $colorFields) {
        $content = $content -replace "COLORS\.$field\b", "TC('$field')"
    }

    # === PHASE 4: Hardcoded hex -> TC() ===
    $hexMap = @{
        '#757575' = "TC('TEXT_HINT_7575')"
        '#616161' = "TC('TEXT_HINT_6161')"
        '#888888' = "TC('TEXT_HINT_8888')"
        '#9E9E9E' = "TC('TEXT_HINT_9E9E')"
        '#AAAAAA' = "TC('TEXT_HINT_AAAA')"
        '#BDBDBD' = "TC('TEXT_DISABLED')"
        '#333333' = "TC('TEXT_DARK_3333')"
        '#2E7D32' = "TC('LEVEL_POSITIVE_GREEN')"
        '#F57C00' = "TC('LEVEL_AMBER')"
        '#D32F2F' = "TC('ERROR_STRONG')"
        '#E53935' = "TC('ERROR_RED')"
        '#7B1FA2' = "TC('ACCENT_PURPLE_7B1F')"
        '#2196F3' = "TC('ACCENT_BLUE_2196')"
        '#66BB6A' = "TC('ACCENT_GREEN_66BB')"
        '#81C784' = "TC('ACCENT_GREEN_81C7')"
        '#8BC34A' = "TC('ACCENT_GREEN_8BC3')"
        '#AED581' = "TC('ACCENT_GREEN_AED5')"
        '#EF5350' = "TC('ACCENT_RED_EF53')"
        '#FFA726' = "TC('ACCENT_ORANGE_FFA7')"
        '#FF7043' = "TC('ACCENT_ORANGE')"
        '#9C27B0' = "TC('ACCENT_PURPLE_9C27')"
        '#EF6C00' = "TC('ORANGE_DEEP')"
        '#FF8A65' = "TC('ORANGE_LIGHT_FF8A')"
        '#FFB74D' = "TC('CARB_COLOR')"
        '#FFB74F' = "TC('ORANGE_LIGHT_FFB74F')"
        '#4FC3F7' = "TC('PROTEIN_COLOR')"
        '#BA68C8' = "TC('FAT_COLOR')"
        '#FFD54F' = "TC('YELLOW_AMBER_FFD5')"
        '#FFD700' = "TC('YELLOW_GOLD')"
        '#FFF5F5' = "TC('BG_ERROR_TINT')"
        '#E8F5E9' = "TC('BG_GOOD_TINT')"
        '#F0E8FF' = "TC('BG_LIGHT_PURPLE')"
        '#F1F8E9' = "TC('BG_LIGHT_BLUE')"
        '#FFFDE7' = "TC('BG_LIGHT_GOLD')"
        '#F7F8FA' = "TC('BG_ALT_F7F8')"
        '#FFF3E0' = "TC('BG_WARM_ORANGE')"
        '#FCE4EC' = "TC('BG_WARM_PINK')"
        '#F3E5F5' = "TC('BG_WARM_PURPLE')"
        '#E3F2FD' = "TC('BG_WARM_BLUE')"
        '#FFF8E1' = "TC('BG_WARM_YELLOW')"
        '#E8E8E8' = "TC('BORDER_LIGHT_E8E8')"
        '#E0E0E0' = "TC('BORDER')"
        '#EEEEEE' = "TC('DIVIDER')"
        '#D0D0D0' = "TC('DOT_INACTIVE')"
        '#F5F5F5' = "TC('BG_LIGHT')"
        '#FAFAFA' = "TC('BG_PAGE')"
        '#66000000' = "TC('OVERLAY')"
        '#FFFFFF30' = "TC('SEMI_WHITE')"
        '#FFD0D0' = "TC('PINK_LIGHT_D0D0')"
    }
    foreach ($hex in $hexMap.Keys) {
        $tcVal = $hexMap[$hex]
        # .fontColor('#XXXXXX') -> .fontColor(TC('XXX'))
        $content = $content -replace "\.fontColor\('$hex'\)", ".fontColor($tcVal)"
        # .backgroundColor('#XXXXXX') -> .backgroundColor(TC('XXX'))
        $content = $content -replace "\.backgroundColor\('$hex'\)", ".backgroundColor($tcVal)"
        # .color('#XXXXXX') -> .color(TC('XXX'))
        $content = $content -replace "\.color\('$hex'\)", ".color($tcVal)"
        # .fill('#XXXXXX') -> .fill(TC('XXX'))
        $content = $content -replace "\.fill\('$hex'\)", ".fill($tcVal)"
        # color: '#XXXXXX' (object literal) -> color: TC('XXX')
        $content = $content -replace "color: '$hex',", "color: $tcVal,"
        $content = $content -replace "color: '$hex'\s*\}", "color: $tcVal }"
        $content = $content -replace "color: '$hex'\s*\n", "color: $tcVal`n"
        # cardBg: '#XXXXXX' -> cardBg: TC('XXX')
        $content = $content -replace "cardBg: '$hex',", "cardBg: $tcVal,"
        # borderColor: '#XXXXXX' -> borderColor: TC('XXX')
        $content = $content -replace "borderColor: '$hex',", "borderColor: $tcVal,"
        # backgroundColor: '#XXXXXX' -> backgroundColor: TC('XXX')
        $content = $content -replace "backgroundColor: '$hex',", "backgroundColor: $tcVal,"
        # fontColor: '#XXXXXX' -> fontColor: TC('XXX')  
        $content = $content -replace "fontColor: '$hex',", "fontColor: $tcVal,"
        # Return '#XXXXXX' in functions
        $content = $content -replace "return '$hex'", "return $tcVal as string"
        # Just plain '#XXXXXX' in value position
        $content = $content -replace "= '$hex'", "= $tcVal"
        # shadow color
        $content = $content -replace "color: '$hex', offsetY", "color: $tcVal, offsetY"
    }

    # If content changed, write back
    if ($content -ne $original) {
        Set-Content $f.FullName $content -NoNewline
        $changed = $true
    }
}

Write-Host "Migration complete!"

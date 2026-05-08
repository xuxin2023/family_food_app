# Re-apply color migration to pages/components/engine/model/widget only
Set-Location 'E:\APP\family_food_app'

$targetDirs = @('pages', 'components', 'engine', 'model', 'widget')
$hexMap = @{
    '#E8A0BF' = "TC('PRIMARY')"
    '#F5D0E0' = "TC('PRIMARY_LIGHT')"
    '#C77D9E' = "TC('PRIMARY_DARK')"
    '#F5C6A0' = "TC('SECONDARY')"
    '#7EC8A0' = "TC('SUCCESS')"
    '#F0C060' = "TC('WARNING')"
    '#E88A8A' = "TC('ERROR')"
    '#D32F2F' = "TC('ERROR_STRONG')"
    '#E53935' = "TC('ERROR_RED')"
    '#80B8E0' = "TC('ACCENT_BLUE')"
    '#2196F3' = "TC('ACCENT_BLUE_2196')"
    '#B8A0D4' = "TC('ACCENT_PURPLE')"
    '#7B1FA2' = "TC('ACCENT_PURPLE_7B1F')"
    '#9C27B0' = "TC('ACCENT_PURPLE_9C27')"
    '#4CAF50' = "TC('LEVEL_GREEN')"
    '#66BB6A' = "TC('ACCENT_GREEN_66BB')"
    '#81C784' = "TC('ACCENT_GREEN_81C7')"
    '#8BC34A' = "TC('ACCENT_GREEN_8BC3')"
    '#AED581' = "TC('ACCENT_GREEN_AED5')"
    '#EF5350' = "TC('ACCENT_RED_EF53')"
    '#F44336' = "TC('LEVEL_RED')"
    '#FFA726' = "TC('ACCENT_ORANGE_FFA7')"
    '#FF5722' = "TC('LEVEL_ORANGE')"
    '#FF9800' = "TC('LEVEL_YELLOW')"
    '#EF6C00' = "TC('ORANGE_DEEP')"
    '#F57C00' = "TC('LEVEL_AMBER')"
    '#FF8A65' = "TC('ORANGE_LIGHT_FF8A')"
    '#FFB74D' = "TC('CARB_COLOR')"
    '#FFB74F' = "TC('ORANGE_LIGHT_FFB74F')"
    '#FFD54F' = "TC('YELLOW_AMBER_FFD5')"
    '#FFD700' = "TC('YELLOW_GOLD')"
    '#4FC3F7' = "TC('PROTEIN_COLOR')"
    '#BA68C8' = "TC('FAT_COLOR')"
    '#1A1A1A' = "TC('TEXT_PRIMARY')"
    '#666666' = "TC('TEXT_SECONDARY')"
    '#999999' = "TC('TEXT_TERTIARY')"
    '#FFFFFF' = "TC('TEXT_WHITE')"
    '#BDBDBD' = "TC('TEXT_DISABLED')"
    '#616161' = "TC('TEXT_HINT_6161')"
    '#757575' = "TC('TEXT_HINT_7575')"
    '#888888' = "TC('TEXT_HINT_8888')"
    '#9E9E9E' = "TC('TEXT_HINT_9E9E')"
    '#AAAAAA' = "TC('TEXT_HINT_AAAA')"
    '#333333' = "TC('TEXT_DARK_3333')"
    '#FAFAFA' = "TC('BG_PAGE')"
    '#FFF5F8' = "TC('BG_CARD_HIGHLIGHT')"
    '#FDE8F0' = "TC('BG_GRADIENT_START')"
    '#FFF0E0' = "TC('BG_GRADIENT_END')"
    '#F5F5F5' = "TC('BG_LIGHT')"
    '#F7F8FA' = "TC('BG_ALT_F7F8')"
    '#FFF3E0' = "TC('BG_WARM_ORANGE')"
    '#FCE4EC' = "TC('BG_WARM_PINK')"
    '#F3E5F5' = "TC('BG_WARM_PURPLE')"
    '#E3F2FD' = "TC('BG_WARM_BLUE')"
    '#FFF8E1' = "TC('BG_WARM_YELLOW')"
    '#E8F5E9' = "TC('BG_LIGHT_GREEN')"
    '#FFFDE7' = "TC('BG_LIGHT_GOLD')"
    '#F1F8E9' = "TC('BG_LIGHT_BLUE')"
    '#F0E8FF' = "TC('BG_LIGHT_PURPLE')"
    '#FFF5F5' = "TC('BG_ERROR_TINT')"
    '#2E7D32' = "TC('BG_POSITIVE_2E7D')"
    '#66000000' = "TC('OVERLAY')"
    '#FFFFFF30' = "TC('SEMI_WHITE')"
    '#E0E0E0' = "TC('BORDER')"
    '#E8E8E8' = "TC('BORDER_LIGHT_E8E8')"
    '#EEEEEE' = "TC('DIVIDER')"
    '#1A000000' = "TC('SHADOW')"
    '#0A000000' = "TC('SHADOW_LIGHT')"
    '#D0D0D0' = "TC('DOT_INACTIVE')"
    '#FFD0D0' = "TC('PINK_LIGHT_D0D0')"
    '#000000' = "TC('TEXT_PRIMARY')"
    '#33000000' = "TC('SHADOW')"
    '#22000000' = "TC('SHADOW_LIGHT')"
    '#80000000' = "TC('OVERLAY')"
    '#FF7043' = "TC('LEVEL_ORANGE')"
}

foreach ($dir in $targetDirs) {
    $etsFiles = Get-ChildItem -Recurse -Filter '*.ets' -Path "entry/src/main/ets/$dir"
    foreach ($f in $etsFiles) {
        $content = Get-Content $f.FullName -Raw
        $original = $content

        # Replace COLORS.X -> TC('X')
        $content = $content -replace 'COLORS\.PRIMARY\b', "TC('PRIMARY')"
        $content = $content -replace 'COLORS\.PRIMARY_LIGHT\b', "TC('PRIMARY_LIGHT')"
        $content = $content -replace 'COLORS\.PRIMARY_DARK\b', "TC('PRIMARY_DARK')"
        $content = $content -replace 'COLORS\.SECONDARY\b', "TC('SECONDARY')"
        $content = $content -replace 'COLORS\.SUCCESS\b', "TC('SUCCESS')"
        $content = $content -replace 'COLORS\.WARNING\b', "TC('WARNING')"
        $content = $content -replace 'COLORS\.ERROR\b', "TC('ERROR')"
        $content = $content -replace 'COLORS\.ERROR_STRONG\b', "TC('ERROR_STRONG')"
        $content = $content -replace 'COLORS\.ERROR_RED\b', "TC('ERROR_RED')"
        $content = $content -replace 'COLORS\.ACCENT_BLUE\b', "TC('ACCENT_BLUE')"
        $content = $content -replace 'COLORS\.ACCENT_BLUE_2196\b', "TC('ACCENT_BLUE_2196')"
        $content = $content -replace 'COLORS\.ACCENT_PURPLE\b', "TC('ACCENT_PURPLE')"
        $content = $content -replace 'COLORS\.ACCENT_PURPLE_7B1F\b', "TC('ACCENT_PURPLE_7B1F')"
        $content = $content -replace 'COLORS\.ACCENT_PURPLE_9C27\b', "TC('ACCENT_PURPLE_9C27')"
        $content = $content -replace 'COLORS\.ACCENT_GREEN_4CAF\b', "TC('ACCENT_GREEN_4CAF')"
        $content = $content -replace 'COLORS\.ACCENT_GREEN_66BB\b', "TC('ACCENT_GREEN_66BB')"
        $content = $content -replace 'COLORS\.ACCENT_GREEN_81C7\b', "TC('ACCENT_GREEN_81C7')"
        $content = $content -replace 'COLORS\.ACCENT_GREEN_8BC3\b', "TC('ACCENT_GREEN_8BC3')"
        $content = $content -replace 'COLORS\.ACCENT_GREEN_AED5\b', "TC('ACCENT_GREEN_AED5')"
        $content = $content -replace 'COLORS\.ACCENT_RED_EF53\b', "TC('ACCENT_RED_EF53')"
        $content = $content -replace 'COLORS\.ACCENT_RED_F443\b', "TC('ACCENT_RED_F443')"
        $content = $content -replace 'COLORS\.ACCENT_ORANGE_FFA7\b', "TC('ACCENT_ORANGE_FFA7')"
        $content = $content -replace 'COLORS\.ACCENT_ORANGE\b', "TC('ACCENT_ORANGE')"
        $content = $content -replace 'COLORS\.ORANGE_ACCENT\b', "TC('ORANGE_ACCENT')"
        $content = $content -replace 'COLORS\.ORANGE_DEEP\b', "TC('ORANGE_DEEP')"
        $content = $content -replace 'COLORS\.ORANGE_AMBER\b', "TC('ORANGE_AMBER')"
        $content = $content -replace 'COLORS\.ORANGE_LIGHT_FF8A\b', "TC('ORANGE_LIGHT_FF8A')"
        $content = $content -replace 'COLORS\.ORANGE_LIGHT_FFB7\b', "TC('ORANGE_LIGHT_FFB7')"
        $content = $content -replace 'COLORS\.ORANGE_LIGHT_FFB74F\b', "TC('ORANGE_LIGHT_FFB74F')"
        $content = $content -replace 'COLORS\.YELLOW_AMBER_FFD5\b', "TC('YELLOW_AMBER_FFD5')"
        $content = $content -replace 'COLORS\.YELLOW_GOLD\b', "TC('YELLOW_GOLD')"
        $content = $content -replace 'COLORS\.CARB_COLOR\b', "TC('CARB_COLOR')"
        $content = $content -replace 'COLORS\.PROTEIN_COLOR\b', "TC('PROTEIN_COLOR')"
        $content = $content -replace 'COLORS\.FAT_COLOR\b', "TC('FAT_COLOR')"
        $content = $content -replace 'COLORS\.TEXT_PRIMARY\b', "TC('TEXT_PRIMARY')"
        $content = $content -replace 'COLORS\.TEXT_SECONDARY\b', "TC('TEXT_SECONDARY')"
        $content = $content -replace 'COLORS\.TEXT_TERTIARY\b', "TC('TEXT_TERTIARY')"
        $content = $content -replace 'COLORS\.TEXT_WHITE\b', "TC('TEXT_WHITE')"
        $content = $content -replace 'COLORS\.TEXT_DISABLED\b', "TC('TEXT_DISABLED')"
        $content = $content -replace 'COLORS\.TEXT_HINT_6161\b', "TC('TEXT_HINT_6161')"
        $content = $content -replace 'COLORS\.TEXT_HINT_7575\b', "TC('TEXT_HINT_7575')"
        $content = $content -replace 'COLORS\.TEXT_HINT_8888\b', "TC('TEXT_HINT_8888')"
        $content = $content -replace 'COLORS\.TEXT_HINT_9E9E\b', "TC('TEXT_HINT_9E9E')"
        $content = $content -replace 'COLORS\.TEXT_HINT_AAAA\b', "TC('TEXT_HINT_AAAA')"
        $content = $content -replace 'COLORS\.TEXT_DARK_3333\b', "TC('TEXT_DARK_3333')"
        $content = $content -replace 'COLORS\.TEXT_HINT_AAAA\b', "TC('TEXT_HINT_AAAA')"
        $content = $content -replace 'COLORS\.BG_PAGE\b', "TC('BG_PAGE')"
        $content = $content -replace 'COLORS\.BG_CARD\b', "TC('BG_CARD')"
        $content = $content -replace 'COLORS\.BG_CARD_HIGHLIGHT\b', "TC('BG_CARD_HIGHLIGHT')"
        $content = $content -replace 'COLORS\.BG_GRADIENT_START\b', "TC('BG_GRADIENT_START')"
        $content = $content -replace 'COLORS\.BG_GRADIENT_END\b', "TC('BG_GRADIENT_END')"
        $content = $content -replace 'COLORS\.BG_LIGHT\b', "TC('BG_LIGHT')"
        $content = $content -replace 'COLORS\.BG_ALT_F7F8\b', "TC('BG_ALT_F7F8')"
        $content = $content -replace 'COLORS\.BG_WARM_ORANGE\b', "TC('BG_WARM_ORANGE')"
        $content = $content -replace 'COLORS\.BG_WARM_PINK\b', "TC('BG_WARM_PINK')"
        $content = $content -replace 'COLORS\.BG_WARM_PURPLE\b', "TC('BG_WARM_PURPLE')"
        $content = $content -replace 'COLORS\.BG_WARM_BLUE\b', "TC('BG_WARM_BLUE')"
        $content = $content -replace 'COLORS\.BG_WARM_YELLOW\b', "TC('BG_WARM_YELLOW')"
        $content = $content -replace 'COLORS\.BG_LIGHT_GREEN\b', "TC('BG_LIGHT_GREEN')"
        $content = $content -replace 'COLORS\.BG_LIGHT_GOLD\b', "TC('BG_LIGHT_GOLD')"
        $content = $content -replace 'COLORS\.BG_LIGHT_BLUE\b', "TC('BG_LIGHT_BLUE')"
        $content = $content -replace 'COLORS\.BG_LIGHT_PURPLE\b', "TC('BG_LIGHT_PURPLE')"
        $content = $content -replace 'COLORS\.BG_ERROR_TINT\b', "TC('BG_ERROR_TINT')"
        $content = $content -replace 'COLORS\.BG_GOOD_TINT\b', "TC('BG_GOOD_TINT')"
        $content = $content -replace 'COLORS\.BG_POSITIVE_2E7D\b', "TC('BG_POSITIVE_2E7D')"
        $content = $content -replace 'COLORS\.OVERLAY\b', "TC('OVERLAY')"
        $content = $content -replace 'COLORS\.SEMI_WHITE\b', "TC('SEMI_WHITE')"
        $content = $content -replace 'COLORS\.BORDER\b', "TC('BORDER')"
        $content = $content -replace 'COLORS\.BORDER_LIGHT_E8E8\b', "TC('BORDER_LIGHT_E8E8')"
        $content = $content -replace 'COLORS\.DIVIDER\b', "TC('DIVIDER')"
        $content = $content -replace 'COLORS\.SHADOW\b', "TC('SHADOW')"
        $content = $content -replace 'COLORS\.SHADOW_LIGHT\b', "TC('SHADOW_LIGHT')"
        $content = $content -replace 'COLORS\.DOT_INACTIVE\b', "TC('DOT_INACTIVE')"
        $content = $content -replace 'COLORS\.LEVEL_GREEN\b', "TC('LEVEL_GREEN')"
        $content = $content -replace 'COLORS\.LEVEL_YELLOW\b', "TC('LEVEL_YELLOW')"
        $content = $content -replace 'COLORS\.LEVEL_ORANGE\b', "TC('LEVEL_ORANGE')"
        $content = $content -replace 'COLORS\.LEVEL_RED\b', "TC('LEVEL_RED')"
        $content = $content -replace 'COLORS\.LEVEL_AMBER\b', "TC('LEVEL_AMBER')"
        $content = $content -replace 'COLORS\.LEVEL_POSITIVE_GREEN\b', "TC('LEVEL_POSITIVE_GREEN')"
        $content = $content -replace 'COLORS\.PINK_LIGHT_D0D0\b', "TC('PINK_LIGHT_D0D0')"
        $content = $content -replace 'COLORS\.WHITE\b', "TC('TEXT_WHITE')"
        $content = $content -replace 'COLORS\.BLACK\b', "TC('TEXT_PRIMARY')"

        # Replace hex values
        foreach ($hex in $hexMap.Keys) {
            $tcVal = $hexMap[$hex]
            $content = $content -replace ([regex]::Escape("'$hex'")), $tcVal
        }

        # Fix import: add TC, remove COLORS
        if ($content -match "TC\('" -and $content -match 'import \{.*\} from .*AppTheme') {
            # Add TC if needed (import line exists)
            if ($content -notmatch "import.*\bTC\b.*from.*AppTheme") {
                # Add TC to existing import - find the closing } before 'from'
                $content = $content -replace "(import \{)(.*?)(\} from .*AppTheme')", 'import {$2, TC$3'
            }
            # Remove COLORS from import
            $content = $content -replace 'COLORS, ', ''
            $content = $content -replace ', COLORS', ''
            $content = $content -replace 'COLORS', '' -replace 'import \{ ,', 'import {' -replace 'import \{  ', 'import { '
        }

        if ($content -ne $original) {
            Set-Content $f.FullName $content -NoNewline
            Write-Host "Migrated: $dir/$($f.Name)"
        }
    }
}

Write-Host "Re-migration complete!"

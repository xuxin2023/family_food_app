# Phase 2f: Fix remaining hardcoded hex in non-AppTheme files
# Handle object properties, ternary expressions, shadow, etc.
Set-Location 'E:\APP\family_food_app'

$etsFiles = Get-ChildItem -Recurse -Filter '*.ets' -Path 'entry/src/main/ets' | Where-Object { $_.FullName -notmatch 'AppTheme\.ets$' }

# Extended hex-to-TC mapping (covering all hex values found in AppTheme.ets)
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
    '#4CAF50' = "TC('ACCENT_GREEN_4CAF')"
    '#66BB6A' = "TC('ACCENT_GREEN_66BB')"
    '#81C784' = "TC('ACCENT_GREEN_81C7')"
    '#8BC34A' = "TC('ACCENT_GREEN_8BC3')"
    '#AED581' = "TC('ACCENT_GREEN_AED5')"
    '#EF5350' = "TC('ACCENT_RED_EF53')"
    '#F44336' = "TC('ACCENT_RED_F443')"
    '#FFA726' = "TC('ACCENT_ORANGE_FFA7')"
    '#FF5722' = "TC('ACCENT_ORANGE')"
    '#FF9800' = "TC('ORANGE_ACCENT')"
    '#EF6C00' = "TC('ORANGE_DEEP')"
    '#F57C00' = "TC('ORANGE_AMBER')"
    '#FF8A65' = "TC('ORANGE_LIGHT_FF8A')"
    '#FFB74D' = "TC('ORANGE_LIGHT_FFB7')"
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
    '#F44336' = "TC('LEVEL_RED')"
    '#FFD0D0' = "TC('PINK_LIGHT_D0D0')"
    '#000000' = "TC('TEXT_PRIMARY')"
    # Additional shadow colors
    '#33000000' = "TC('SHADOW')"
    '#22000000' = "TC('SHADOW_LIGHT')"
    '#80000000' = "TC('OVERLAY')"
    # Additional from DarkTheme
    '#6B3A5E' = "TC('PRIMARY_LIGHT')"
    '#8B6F50' = "TC('SECONDARY')"
    '#4A9E6A' = "TC('SUCCESS')"
    '#B89040' = "TC('WARNING')"
    '#B85A5A' = "TC('ERROR')"
    '#D4B0C0' = "TC('PRIMARY_DARK')"
    '#8AADCC' = "TC('ACCENT_BLUE')"
    '#C8C0E0' = "TC('ACCENT_PURPLE')"
    '#E0E0E0' = "TC('TEXT_PRIMARY')"
    '#B0B0B0' = "TC('TEXT_SECONDARY')"
    '#808080' = "TC('TEXT_TERTIARY')"
    '#1C1C1C' = "TC('BG_PAGE')"
    '#2C2C2C' = "TC('BG_CARD')"
    '#3C3C3C' = "TC('BG_LIGHT')"
    '#444444' = "TC('BORDER')"
    '#222222' = "TC('DIVIDER')"
    '#FF7043' = "TC('ACCENT_ORANGE_FFA7')"
}

foreach ($f in $etsFiles) {
    $content = Get-Content $f.FullName -Raw
    $original = $content
    $needsImport = $false

    # Replace all hex patterns with TC() equivalents
    foreach ($hex in $hexMap.Keys) {
        $tcVal = $hexMap[$hex]
        # Simple string replacements for all contexts
        $content = $content -replace ([regex]::Escape("'$hex'")), $tcVal
        # Also handle double-quoted if any
        $content = $content -replace ([regex]::Escape('"' + $hex + '"')), $tcVal
    }

    # Add TC import if used but not imported
    if ($content -match "TC\('" -and $content -notmatch "import.*\bTC\b.*from.*AppTheme") {
        if ($content -match "import \{") {
            # Insert TC after the last import (simplified approach)
            $content = $content -replace "(import \{.*\} from '.*AppTheme';)", ($matches[1] -replace '\}', ', TC }')
        }
    }

    if ($content -ne $original) {
        Set-Content $f.FullName $content -NoNewline
        Write-Host "Fixed hex: $($f.Name)"
    }
}

Write-Host "Phase 2f complete!"

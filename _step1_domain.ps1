$ErrorActionPreference = 'Stop'
Set-Location 'E:\APP\family_food_app'
$root = 'entry/src/main/ets'

# Map of file patterns to their relative import path for AppConfig
$paths = @{
    'pages' = '../constants/AppConfig'
    'components' = '../constants/AppConfig'
    'utils' = '../constants/AppConfig'
    'service' = '../constants/AppConfig'
    'service/sync' = '../../constants/AppConfig'
    'service/health' = '../../constants/AppConfig'
    'service/share' = '../../constants/AppConfig'
    'service/ai' = '../../constants/AppConfig'
    'repository' = '../constants/AppConfig'
    'manager' = '../constants/AppConfig'
    'entryability' = '../constants/AppConfig'
}

$count = 0
$files = @(
    'pages/SubscriptionPage.ets',
    'pages/SettingsPage.ets',
    'pages/ScanPage.ets',
    'pages/RecipeDetailPage.ets',
    'pages/RecipeCommunityPage.ets',
    'pages/PrivacyDialogPage.ets',
    'pages/NutritionTrendPage.ets',
    'pages/HomePage.ets',
    'pages/FamilyGroupPage.ets',
    'pages/GroupFeedPage.ets',
    'pages/DietDiaryPage.ets',
    'pages/DashboardPage.ets',
    'pages/DeviceDashboardPage.ets',
    'pages/AiChatPage.ets',
    'components/ShareCard.ets',
    'components/LinkInputDialog.ets',
    'components/HomeMemberList.ets',
    'components/CredibilityCard.ets',
    'utils/AssetKeyManager.ets',
    'service/sync/SyncService.ets',
    'service/sync/CloudStorageProvider.ets',
    'service/health/ManualHealthSignalProvider.ets',
    'service/share/CopyTextProvider.ets',
    'service/ai/AiServiceBase.ets',
    'service/health/HwHealthSignalProvider.ets',
    'service/SubscriptionVerifyService.ets',
    'service/ShareImageService.ets',
    'service/ai/AiClient.ets',
    'service/RecipeCommunityService.ets',
    'service/PushNotificationService.ets',
    'service/ScanService.ets',
    'service/OpenFoodFactsService.ets',
    'service/PermissionManager.ets',
    'service/PreloadService.ets',
    'service/OnlineShoppingParser.ets',
    'service/OcrService.ets',
    'service/NetworkMonitorService.ets',
    'service/NutritionDomainService.ets',
    'service/MilestoneService.ets',
    'service/MemberManager.ets',
    'service/InspectionDataService.ets',
    'service/IntentRegistrationService.ets',
    'service/IapService.ets',
    'service/FamilyGroupService.ets',
    'service/FoodWidgetManager.ets',
    'service/ElderModeManager.ets',
    'service/DataService.ets',
    'service/DatabaseMigrationService.ets',
    'service/CommunityFoodService.ets',
    'service/CloudAuthService.ets',
    'service/AuthService.ets',
    'service/AnalyticsService.ets',
    'service/AiRecipeRecommenderService.ets',
    'service/AiWeeklyReportService.ets',
    'service/AiPolishService.ets',
    'service/AiNutritionistService.ets',
    'service/AiChatService.ets',
    'repository/RuleRepository.ets',
    'repository/RecipeRepository.ets',
    'repository/FoodRepository.ets',
    'repository/HistoryRepository.ets',
    'repository/FamilyRepository.ets',
    'repository/FamilyGroupRepository.ets',
    'manager/MemberManager.ets',
    'manager/BasketManager.ets',
    'entryability/app.ets',
    'ServiceManager.ets',
    'AppState.ets'
)

foreach ($relPath in $files) {
    $fullPath = Join-Path $root $relPath
    if (-not (Test-Path $fullPath)) {
        Write-Host "SKIP (not found): $relPath"
        continue
    }

    $content = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
    $modified = $false

    # Check if already migrated
    if ($content -match 'HILOG_DOMAIN\.DEFAULT') {
        Write-Host "SKIP (already done): $relPath"
        continue
    }

    # Determine import path
    $dir = Split-Path $relPath -Parent
    if ($dir -eq '') { $dir = '.' }
    $importPath = $paths[$dir]
    if (-not $importPath) {
        Write-Host "UNKNOWN dir: $dir for $relPath"
        continue
    }

    $importLine = "import { HILOG_DOMAIN } from '$importPath';"

    # Add import after any existing 'import { hilog' or at top of file near other imports
    # Strategy: insert after the last existing import line that starts with 'import'
    $lines = $content -split "`r`n"
    if ($lines.Count -lt 2) {
        $lines = $content -split "`n"
    }
    $lastImportIdx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*import\s') {
            $lastImportIdx = $i
        }
    }

    if ($lastImportIdx -ge 0) {
        $newLines = @()
        for ($i = 0; $i -le $lastImportIdx; $i++) {
            $newLines += $lines[$i]
        }
        $newLines += $importLine
        for ($i = $lastImportIdx + 1; $i -lt $lines.Count; $i++) {
            $newLines += $lines[$i]
        }
        $content = $newLines -join "`r`n"
    } else {
        Write-Host "WARN: no import found in $relPath"
        continue
    }

    # Replace const DOMAIN_ZERO = 0; → const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;
    if ($content -match 'const DOMAIN_ZERO\s*=\s*0\s*;') {
        $content = $content -replace 'const DOMAIN_ZERO\s*=\s*0\s*;', 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'
    } else {
        Write-Host "WARN: DOMAIN_ZERO pattern not found in $relPath after import insert"
    }

    [System.IO.File]::WriteAllText($fullPath, $content, [System.Text.UTF8Encoding]::new($false))
    $count++
    Write-Host "OK: $relPath"
}

Write-Host "=== Done: $count files updated ==="

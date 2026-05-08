$base = 'E:\APP\family_food_app\entry\src\main\ets'

# service files (31)
$svcFiles = @(
    'service\IapService.ets','service\OnlineShoppingParser.ets','service\PushNotificationService.ets',
    'service\ElderModeManager.ets','service\MilestoneService.ets','service\FoodWidgetManager.ets',
    'service\CloudAuthService.ets','service\AuthService.ets','service\RecipeCommunityService.ets',
    'service\FamilyGroupService.ets','service\InspectionDataService.ets','service\AiRecipeRecommenderService.ets',
    'service\DataService.ets','service\OpenFoodFactsService.ets','service\DatabaseMigrationService.ets',
    'service\AiChatService.ets','service\AiWeeklyReportService.ets','service\AiPolishService.ets',
    'service\PermissionManager.ets','service\AiNutritionistService.ets','service\NutritionDomainService.ets',
    'service\CommunityFoodService.ets','service\SubscriptionVerifyService.ets','service\AnalyticsService.ets',
    'service\OcrService.ets','service\MemberManager.ets','service\NetworkMonitorService.ets',
    'service\ShareImageService.ets','service\PreloadService.ets','service\IntentRegistrationService.ets',
    'service\ScanService.ets',
    'service\health\ManualHealthSignalProvider.ets','service\health\HwHealthSignalProvider.ets',
    'service\sync\SyncService.ets','service\sync\CloudStorageProvider.ets',
    'service\ai\AiServiceBase.ets','service\ai\AiClient.ets',
    'service\share\CopyTextProvider.ets'
)

# manager files (5)
$mgrFiles = @(
    'manager\RepositoryManager.ets','manager\MemberManager.ets','manager\GroupDomainService.ets',
    'manager\CrashMonitorManager.ets','manager\BasketManager.ets'
)

# repository files (6)
$repoFiles = @(
    'repository\RuleRepository.ets','repository\HistoryRepository.ets','repository\FamilyRepository.ets',
    'repository\FoodRepository.ets','repository\FamilyGroupRepository.ets','repository\RecipeRepository.ets'
)

# component files (4)
$compFiles = @(
    'components\CredibilityCard.ets','components\LinkInputDialog.ets',
    'components\HomeMemberList.ets','components\ShareCard.ets'
)

$allFiles = @()

# Group files by their import path depth
# Level 1 dirs (service,manager,repository,components): ../constants/AppConfig
foreach ($f in $svcFiles + $mgrFiles + $repoFiles + $compFiles) {
    $depth = ($f.ToCharArray() | Where-Object { $_ -eq '\' } | Measure-Object).Count
    # service/health/ -> 2 levels deep -> ../../constants/AppConfig
    # service/sync/ -> 2 levels deep -> ../../constants/AppConfig
    # service/ai/ -> 2 levels deep -> ../../constants/AppConfig
    # service/share/ -> 2 levels deep -> ../../constants/AppConfig
    # service/*.ets -> 1 level deep -> ../constants/AppConfig
    # manager/*.ets -> 1 level deep -> ../constants/AppConfig
    # repository/*.ets -> 1 level deep -> ../constants/AppConfig
    # components/*.ets -> 1 level deep -> ../constants/AppConfig
    if ($depth -ge 2) {
        $relPath = '../../constants/AppConfig'
    } else {
        $relPath = '../constants/AppConfig'
    }
    $fullPath = Join-Path $base $f
    if (Test-Path $fullPath) {
        $c = Get-Content $fullPath -Raw
        if ($c -match 'HILOG_DOMAIN') {
            Write-Host "SKIP (already has HILOG_DOMAIN): $f"
            continue
        }
        # Replace DOMAIN_ZERO definition
        $c = $c -replace 'const DOMAIN_ZERO = 0;', 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'
        $c = $c -replace 'const DOMAIN_ZERO = 0xFF00;', 'const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;'
        # Add import after hilog import
        $c = $c -replace "(import \{ hilog \} from '@kit.PerformanceAnalysisKit';)", ('$1' + "`r`nimport { HILOG_DOMAIN } from '$relPath';")
        Set-Content $fullPath $c -NoNewline
        Write-Host "DONE: $f"
    } else {
        Write-Host "MISSING: $f"
    }
}

Write-Host '=== ALL DONE ==='

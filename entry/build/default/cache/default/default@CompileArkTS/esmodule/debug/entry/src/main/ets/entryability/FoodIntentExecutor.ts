import type insightIntent from "@ohos:app.ability.insightIntent";
import InsightIntentExecutor from "@ohos:app.ability.InsightIntentExecutor";
import type window from "@ohos:window";
import hilog from "@ohos:hilog";
const TAG = 'FoodIntentExecutor';
const DOMAIN_ZERO = 0;
export default class FoodIntentExecutor extends InsightIntentExecutor {
    private static readonly SCAN_FOOD = 'ScanFood';
    private static readonly QUERY_FOOD_SAFETY = 'QueryFoodSafety';
    private static readonly VIEW_FAMILY_REPORT = 'ViewFamilyReport';
    private static readonly RECORD_MEAL = 'RecordMeal';
    async onExecuteInUIAbilityForegroundMode(name: string, param: Record<string, Object>, pageLoader: window.WindowStage): Promise<insightIntent.ExecuteResult> {
        hilog.info(DOMAIN_ZERO, TAG, 'Execute intent: %{public}s', name);
        switch (name) {
            case FoodIntentExecutor.SCAN_FOOD:
                return this.loadPage(pageLoader, 'pages/ScanPage');
            case FoodIntentExecutor.QUERY_FOOD_SAFETY:
                const foodName = param?.foodName as string || '';
                const queryParams: Record<string, Object> = { 'foodName': foodName };
                return this.loadPage(pageLoader, 'pages/ReportPage', queryParams);
            case FoodIntentExecutor.VIEW_FAMILY_REPORT:
                const memberId = param?.memberId as string || '';
                const reportParams: Record<string, Object> = { 'memberId': memberId };
                return this.loadPage(pageLoader, 'pages/WeeklyReportPage', reportParams);
            case FoodIntentExecutor.RECORD_MEAL:
                const scenario = param?.scenario as string || '';
                const balanceParams: Record<string, Object> = { 'scenario': scenario };
                return this.loadPage(pageLoader, 'pages/BalancePage', balanceParams);
            default:
                hilog.warn(DOMAIN_ZERO, TAG, 'Unknown intent: %{public}s', name);
                return this.errorResult('unknown intent');
        }
    }
    private async loadPage(pageLoader: window.WindowStage, pagePath: string, params?: Record<string, Object>): Promise<insightIntent.ExecuteResult> {
        try {
            if (params && Object.keys(params).length > 0) {
                const localStorage = new LocalStorage(params);
                await pageLoader.loadContent(pagePath, localStorage);
            }
            else {
                await pageLoader.loadContent(pagePath);
            }
            hilog.info(DOMAIN_ZERO, TAG, 'Page loaded: %{public}s', pagePath);
            return this.successResult();
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Load page failed: %{public}s', JSON.stringify(error));
            return this.errorResult('page load failed');
        }
    }
    private successResult(): insightIntent.ExecuteResult {
        return { code: 0, result: { message: 'succeed' } } as insightIntent.ExecuteResult;
    }
    private errorResult(msg: string): insightIntent.ExecuteResult {
        return { code: -1, result: { message: msg } } as insightIntent.ExecuteResult;
    }
}

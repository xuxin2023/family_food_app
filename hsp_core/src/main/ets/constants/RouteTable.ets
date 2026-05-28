import { JsonHelper } from '../utils/JsonHelper';

export class RouteTable {
  private static routeMap: Map<string, string> | null = null;

  static get ROUTE_MAP(): Map<string, string> {
    if (RouteTable.routeMap === null) {
      const m = new Map<string, string>();
      m.set('home', 'pages/MainTabsPage');
      m.set('scan', 'pages/ScanPage');
      m.set('report', 'pages/ReportPage');
      m.set('search', 'pages/OffSearchPage');
      m.set('favorites', 'pages/FavoritePage');
      m.set('shopping', 'pages/ShoppingListPage');
      m.set('dashboard', 'pages/DashboardPage');
      m.set('nutrition-target', 'pages/NutritionTargetPage');
      m.set('alternatives', 'pages/AlternativeFoodPage');
      m.set('meal-plan', 'pages/MealPlanPage');
      m.set('knowledge', 'pages/NutritionKnowledgePage');
      m.set('reminders', 'pages/ReminderRulePage');
      m.set('ai-chat', 'pages/AiChatPage');
      m.set('history', 'pages/HistoryPage');
      m.set('diet-diary', 'pages/DietDiaryPage');
      m.set('food-compare', 'pages/FoodComparePage');
      m.set('settings', 'pages/SettingsPage');
      m.set('weekly-report', 'pages/WeeklyReportPage');
      m.set('subscription', 'pages/SubscriptionPage');
      m.set('member', 'pages/MemberPage');
      m.set('balance', 'pages/BalancePage');
      m.set('basket-check', 'pages/BasketCheckPage');
      m.set('recipe-community', 'pages/RecipeCommunityPage');
      m.set('recipe-create', 'pages/RecipeCreatePage');
      m.set('family-group', 'pages/FamilyGroupPage');
      m.set('device-dashboard', 'pages/DeviceDashboardPage');
      m.set('cloud-sync-settings', 'pages/CloudSyncSettingsPage');
      m.set('nutrition-trend', 'pages/NutritionTrendPage');
      m.set('share', 'pages/SharePage');
      m.set('feedback', 'pages/FeedbackPage');
      m.set('homeSimple', 'pages/HomePage');
      m.set('memberEdit', 'pages/MemberEditPage');
      m.set('recipeDetail', 'pages/RecipeDetailPage');
      m.set('privacyDialog', 'pages/PrivacyDialogPage');
      m.set('v2Demo', 'pages/V2DemoPage');
      m.set('exerciseNutrition', 'pages/ExerciseNutritionPage');
      m.set('checkupReport', 'pages/CheckupReportPage');
      m.set('childHealth', 'pages/ChildHealthPage');
      m.set('personalizedRecommend', 'pages/PersonalizedRecommendPage');
      m.set('groupFeed', 'pages/GroupFeedPage');
      RouteTable.routeMap = m;
    }
    return RouteTable.routeMap;
  }

  static getPagePath(name: string): string {
    const path = RouteTable.ROUTE_MAP.get(name);
    return path !== undefined ? path : 'pages/MainTabsPage';
  }

  static hasRoute(name: string): boolean {
    return RouteTable.ROUTE_MAP.has(name);
  }

  static getAllRouteNames(): string[] {
    return Array.from(RouteTable.ROUTE_MAP.keys());
  }
}

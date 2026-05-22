// CloudDbSchema.ets
// 华为云数据库 Schema 定义 — CloudDB 对象类型与索引
// 配合 HuaweiCloudService 实现云数据持久化

export class CloudDbTableName {
  static readonly FAMILY_MEMBERS: string = 'family_members';
  static readonly FOOD_RECORDS: string = 'food_records';
  static readonly SCAN_HISTORY: string = 'scan_history';
  static readonly SUBSCRIPTIONS: string = 'subscriptions';
  static readonly COMMUNITY_RECIPES: string = 'community_recipes';
  static readonly RECIPE_COMMENTS: string = 'recipe_comments';
  static readonly GROUP_MEMBERS: string = 'cloud_group_members';
  static readonly NOTIFICATION_LOG: string = 'notification_log';
}

export class CloudDbField {
  static readonly ID: string = 'id';
  static readonly UID: string = 'uid';
  static readonly MEMBER_ID: string = 'member_id';
  static readonly CREATED_AT: string = 'created_at';
  static readonly UPDATED_AT: string = 'updated_at';
  static readonly DELETED: string = 'deleted';
}

export class FamilyMemberCloudObject {
  id: string = '';
  uid: string = '';
  nickname: string = '';
  ageGroup: string = '';
  healthGoals: string = '';
  allergens: string = '';
  dailyCalorieBudget: number = 2000;
  pregnancyStatus: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
}

export class FoodRecordCloudObject {
  id: string = '';
  memberId: string = '';
  barcode: string = '';
  foodName: string = '';
  recommendLevel: string = '';
  nutriScore: string = '';
  ecoScore: string = '';
  novaGroup: number = 0;
  scanTimestamp: number = 0;
  nutritionSnapshot: string = '';
  contributorUid: string = '';
}

export class SubscriptionCloudObject {
  id: string = '';
  uid: string = '';
  tier: string = '';
  startDate: number = 0;
  endDate: number = 0;
  autoRenew: boolean = false;
  purchaseToken: string = '';
  orderId: string = '';
  verified: boolean = false;
}

export class CommunityRecipeCloudObject {
  id: string = '';
  authorUid: string = '';
  title: string = '';
  description: string = '';
  category: string = '';
  difficulty: string = '';
  ingredients: string = '';
  steps: string = '';
  nutritionInfo: string = '';
  imageUrl: string = '';
  likeCount: number = 0;
  commentCount: number = 0;
  createdAt: number = 0;
}

export const CLOUD_DB_INDEXES: Record<string, string[]> = {
  [CloudDbTableName.FAMILY_MEMBERS]: ['uid', 'ageGroup'],
  [CloudDbTableName.FOOD_RECORDS]: ['member_id', 'barcode', 'scan_timestamp'],
  [CloudDbTableName.SCAN_HISTORY]: ['member_id', 'scan_timestamp'],
  [CloudDbTableName.SUBSCRIPTIONS]: ['uid', 'tier', 'end_date'],
  [CloudDbTableName.COMMUNITY_RECIPES]: ['author_uid', 'category', 'created_at'],
  [CloudDbTableName.RECIPE_COMMENTS]: ['recipe_id', 'created_at'],
};

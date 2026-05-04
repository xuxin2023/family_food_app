// Recipe.ets
// 食谱社区数据模型

/** 食谱难度等级 */
export enum RecipeDifficulty {
  EASY = 'easy',
  MEDIUM = 'medium',
  HARD = 'hard'
}

/** 食谱分类标签 */
export enum RecipeCategory {
  /** 早餐 */
  BREAKFAST = 'breakfast',
  /** 午餐 */
  LUNCH = 'lunch',
  /** 晚餐 */
  DINNER = 'dinner',
  /** 零食 */
  SNACK = 'snack',
  /** 饮品 */
  BEVERAGE = 'beverage',
  /** 甜品 */
  DESSERT = 'dessert',
  /** 汤羹 */
  SOUP = 'soup',
  /** 主食 */
  STAPLE = 'staple'
}

/** 适配人群标签 */
export enum DietTag {
  /** 儿童友好 */
  CHILD_FRIENDLY = 'child_friendly',
  /** 老人友好 */
  ELDER_FRIENDLY = 'elder_friendly',
  /** 低钠 */
  LOW_SODIUM = 'low_sodium',
  /** 低糖 */
  LOW_SUGAR = 'low_sugar',
  /** 低脂 */
  LOW_FAT = 'low_fat',
  /** 高蛋白 */
  HIGH_PROTEIN = 'high_protein',
  /** 素食 */
  VEGETARIAN = 'vegetarian',
  /** 无过敏原 */
  ALLERGEN_FREE = 'allergen_free'
}

/** 食谱食材项 */
export interface RecipeIngredient {
  /** 食材名称 */
  name: string;
  /** 用量 */
  amount: string;
  /** 可选食材替代 */
  alternative: string;
}

/** 食谱步骤 */
export interface RecipeStep {
  /** 步骤序号 */
  stepNumber: number;
  /** 步骤描述 */
  description: string;
  /** 步骤图片URL（可选） */
  imageUrl: string;
  /** 预计用时(分钟) */
  durationMinutes: number;
}

/** 食谱营养信息（每份） */
export interface RecipeNutrition {
  calories: number;
  protein: string;
  fat: string;
  carbohydrate: string;
  sodium: string;
  sugar: string;
  fiber: string;
}

/** 食谱社区帖子 */
export interface Recipe {
  /** 食谱ID */
  recipeId: string;
  /** 标题 */
  title: string;
  /** 描述/简介 */
  description: string;
  /** 封面图片URL */
  coverImageUrl: string;
  /** 发布者UID */
  authorUid: string;
  /** 发布者昵称 */
  authorName: string;
  /** 发布者头像 */
  authorAvatar: string;
  /** 分类 */
  category: RecipeCategory;
  /** 难度 */
  difficulty: RecipeDifficulty;
  /** 预计总用时(分钟) */
  totalMinutes: number;
  /** 份数 */
  servings: number;
  /** 食材列表 */
  ingredients: RecipeIngredient[];
  /** 步骤列表 */
  steps: RecipeStep[];
  /** 营养信息（可选） */
  nutrition: RecipeNutrition | null;
  /** 适配人群标签 */
  dietTags: DietTag[];
  /** 关联的本地食品ID（可选，关联扫描过的食品） */
  relatedFoodId: string;
  /** 是否来自群组分享 */
  fromGroupId: string;
  /** 创建时间戳(ms) */
  createdAt: number;
  /** 更新时间戳(ms) */
  updatedAt: number;
  /** 点赞数 */
  likeCount: number;
  /** 评论数 */
  commentCount: number;
  /** 收藏数 */
  bookmarkCount: number;
  /** 是否已审核（社区可见） */
  isApproved: boolean;
  /** 是否草稿 */
  isDraft: boolean;
}

/** 食谱评论 */
export interface RecipeComment {
  /** 评论ID */
  commentId: string;
  /** 食谱ID */
  recipeId: string;
  /** 评论者UID */
  authorUid: string;
  /** 评论者昵称 */
  authorName: string;
  /** 评论者头像 */
  authorAvatar: string;
  /** 评论内容 */
  content: string;
  /** 父评论ID（回复功能，空为一级评论） */
  parentId: string;
  /** 创建时间戳(ms) */
  createdAt: number;
  /** 点赞数 */
  likeCount: number;
  /** 是否已编辑 */
  isEdited: boolean;
}

/** 食谱点赞记录 */
export interface RecipeLike {
  /** 记录ID */
  id: string;
  /** 食谱ID */
  recipeId: string;
  /** 用户UID */
  uid: string;
  /** 创建时间戳(ms) */
  createdAt: number;
}

/** 食谱收藏记录 */
export interface RecipeBookmark {
  /** 记录ID */
  id: string;
  /** 食谱ID */
  recipeId: string;
  /** 用户UID */
  uid: string;
  /** 收藏时间戳(ms) */
  createdAt: number;
  /** 收藏备注标签 */
  note: string;
}

/** 食谱列表查询参数 */
export interface RecipeQueryParams {
  category?: RecipeCategory;
  difficulty?: RecipeDifficulty;
  dietTags?: DietTag[];
  authorUid?: string;
  sortBy?: 'latest' | 'popular' | 'trending';
  offset: number;
  limit: number;
}

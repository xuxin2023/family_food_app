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
  ALLERGEN_FREE = 'allergen_free',
  HIGH_FIBER = 'high_fiber',
  ORGANIC = 'organic',
  VEGAN = 'vegan',
  GLUTEN_FREE = 'gluten_free'
}

/** 食谱食材项 */
export class RecipeIngredient {
  /** 食材名称 */
  name: string = '';
  /** 用量 */
  amount: string = '';
  /** 可选食材替代 */
  alternative: string = '';
}

/** 食谱步骤 */
export class RecipeStep {
  /** 步骤序号 */
  stepNumber: number = 0;
  /** 步骤描述 */
  description: string = '';
  /** 步骤图片URL（可选） */
  imageUrl: string = '';
  /** 预计用时(分钟) */
  durationMinutes: number = 0;
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
export class Recipe {
  recipeId: string = '';
  title: string = '';
  description: string = '';
  coverImageUrl: string = '';
  authorUid: string = '';
  authorName: string = '';
  authorAvatar: string = '';
  category: RecipeCategory = RecipeCategory.SNACK;
  difficulty: RecipeDifficulty = RecipeDifficulty.EASY;
  totalMinutes: number = 0;
  servings: number = 1;
  ingredients: RecipeIngredient[] = [];
  steps: RecipeStep[] = [];
  nutrition: RecipeNutrition | null = null;
  dietTags: DietTag[] = [];
  relatedFoodId: string = '';
  fromGroupId: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
  likeCount: number = 0;
  commentCount: number = 0;
  bookmarkCount: number = 0;
  isApproved: boolean = false;
  isDraft: boolean = true;
}

/** 食谱评论 */
export class RecipeComment {
  commentId: string = '';
  recipeId: string = '';
  authorUid: string = '';
  authorName: string = '';
  authorAvatar: string = '';
  content: string = '';
  parentId: string = '';
  createdAt: number = 0;
  likeCount: number = 0;
  isEdited: boolean = false;
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
export class RecipeQueryParams {
  category?: RecipeCategory;
  difficulty?: RecipeDifficulty;
  dietTags?: DietTag[];
  authorUid?: string;
  sortBy?: 'latest' | 'popular' | 'trending';
  offset: number = 0;
  limit: number = 20;
}

export enum RecipeSortBy {
  LATEST = 'latest',
  POPULAR = 'popular',
  TRENDING = 'trending'
}

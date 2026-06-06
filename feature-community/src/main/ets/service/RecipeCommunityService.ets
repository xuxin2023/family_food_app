// RecipeCommunityService.ets
// 食谱社区服务 - 发布、浏览、评论、点赞、收藏

import { hilog } from '@kit.PerformanceAnalysisKit';
import { RecipeRepository } from '../repository/RecipeRepository';
import {
  Recipe, RecipeComment, RecipeIngredient, RecipeStep, RecipeNutrition, RecipeDifficulty, RecipeCategory, DietTag, RecipeQueryParams, CreateRecipeParams, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { AuthService } from 'hsp_service';

export interface RecipeValidationResult {
  valid: boolean;
  missingFields: string[];
  sensitiveHit: boolean;
}


const TAG = 'RecipeCommunityService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export { CreateRecipeParams } from 'hsp_core';

export class RecipeCommunityService {
  private recipeRepo: RecipeRepository;
  private authService: AuthService;

  constructor(recipeRepo: RecipeRepository, authService: AuthService) {
    this.recipeRepo = recipeRepo;
    this.authService = authService;
  }

  // ========== 食谱发布与管理 ==========

  private static readonly SENSITIVE_WORDS: string[] = [
    '广告', '代购', '加微信', '转账', '赌博', '色情', '暴力'
  ];

  validateRecipe(params: CreateRecipeParams): RecipeValidationResult {
    const missingFields: string[] = [];
    if (!params.title || params.title.trim().length === 0) missingFields.push('标题');
    if (!params.ingredients || params.ingredients.length === 0) missingFields.push('食材');
    if (!params.steps || params.steps.length === 0) missingFields.push('步骤');

    const allText = `${params.title ?? ''} ${params.description ?? ''}`;
    const sensitiveHit = RecipeCommunityService.SENSITIVE_WORDS.some(w => allText.includes(w));

    return { valid: missingFields.length === 0 && !sensitiveHit, missingFields, sensitiveHit };
  }

  /**
   * 创建食谱
   */
  async createRecipe(params: CreateRecipeParams): Promise<Recipe> {
    const validation = this.validateRecipe(params);
    if (!validation.valid) {
      if (validation.sensitiveHit) {
        throw new Error('内容包含不当信息，请修改后重新发布');
      }
      throw new Error(`请补充缺失字段：${validation.missingFields.join('、')}`);
    }
    const uid = this.authService.getUid();
    const user = this.authService.getCurrentUser();

    const now = Date.now();
    const recipe: Recipe = new Recipe()
    recipe.recipeId = `recipe_${now}_${Math.random().toString(36).substring(2, 8)}`;
    recipe.title = params.title;
    recipe.description = params.description;
    recipe.coverImageUrl = params.coverImageUrl;
    recipe.authorUid = uid;
    recipe.authorName = user?.isAnonymous ? '匿名用户' : uid.substring(0, 8);
    recipe.authorAvatar = '';
    recipe.category = params.category;
    recipe.difficulty = params.difficulty;
    recipe.totalMinutes = params.totalMinutes;
    recipe.servings = params.servings;
    recipe.ingredients = params.ingredients;
    recipe.steps = params.steps;
    recipe.nutrition = params.nutrition;
    recipe.dietTags = params.dietTags;
    recipe.relatedFoodId = params.relatedFoodId;
    recipe.fromGroupId = params.fromGroupId;
    recipe.createdAt = now;
    recipe.updatedAt = now;
    recipe.likeCount = 0;
    recipe.commentCount = 0;
    recipe.bookmarkCount = 0;
    recipe.isApproved = true;
    recipe.isDraft = params.isDraft;

    await this.recipeRepo.saveRecipe(recipe);
    hilog.info(DOMAIN_ZERO, TAG, 'Recipe created: %{public}s', recipe.recipeId);
    return recipe;
  }

  /**
   * 获取食谱详情
   */
  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    return await this.recipeRepo.getRecipe(recipeId);
  }

  /**
   * 更新食谱
   */
  async updateRecipe(recipeId: string, params: Record<string, Object>): Promise<void> {
    const uid = this.authService.getUid();
    const recipe = await this.recipeRepo.getRecipe(recipeId);
    if (!recipe) throw new Error('食谱不存在');
    if (recipe.authorUid !== uid) throw new Error('仅作者可以编辑食谱');

    const updates: Record<string, Object> = {};
    if (params['title'] !== undefined) updates['title'] = params['title'];
    if (params['description'] !== undefined) updates['description'] = params['description'];
    if (params['coverImageUrl'] !== undefined) updates['coverImageUrl'] = params['coverImageUrl'];
    if (params['category'] !== undefined) updates['category'] = params['category'];
    if (params['difficulty'] !== undefined) updates['difficulty'] = params['difficulty'];
    if (params['totalMinutes'] !== undefined) updates['totalMinutes'] = params['totalMinutes'];
    if (params['servings'] !== undefined) updates['servings'] = params['servings'];
    if (params['ingredients'] !== undefined) updates['ingredients'] = params['ingredients'];
    if (params['steps'] !== undefined) updates['steps'] = params['steps'];
    if (params['nutrition'] !== undefined) updates['nutrition'] = params['nutrition'];
    if (params['dietTags'] !== undefined) updates['dietTags'] = params['dietTags'];
    if (params['isDraft'] !== undefined) updates['isDraft'] = params['isDraft'];

    await this.recipeRepo.updateRecipe(recipeId, updates);
  }

  /**
   * 删除食谱
   */
  async deleteRecipe(recipeId: string): Promise<void> {
    const uid = this.authService.getUid();
    const recipe = await this.recipeRepo.getRecipe(recipeId);
    if (!recipe) throw new Error('食谱不存在');
    if (recipe.authorUid !== uid) throw new Error('仅作者可以删除食谱');
    await this.recipeRepo.deleteRecipe(recipeId);
  }

  // ========== 食谱浏览 ==========

  /**
   * 查询社区食谱（分页）
   */
  async queryRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    const category: string = (params.category as string) ?? '';
    const sortBy: string = (params.sortBy as string) ?? '';
    return await this.recipeRepo.queryApprovedRecipes(
      params.offset, params.limit,
      category, sortBy
    );
  }

  /**
   * 查询用户自己的食谱
   */
  async getMyRecipes(includeDrafts: boolean): Promise<Recipe[]> {
    const uid = this.authService.getUid();
    return await this.recipeRepo.queryUserRecipes(uid, includeDrafts);
  }

  /**
   * 查询群组食谱
   */
  async getGroupRecipes(groupId: string, offset: number, limit: number): Promise<Recipe[]> {
    return await this.recipeRepo.queryGroupRecipes(groupId, offset, limit);
  }

  // ========== 评论管理 ==========

  /**
   * 发表评论
   */
  async addComment(recipeId: string, content: string, parentId: string): Promise<RecipeComment> {
    const uid = this.authService.getUid();
    const user = this.authService.getCurrentUser();

    const comment: RecipeComment = new RecipeComment()
    comment.commentId = `cmt_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    comment.recipeId = recipeId;
    comment.authorUid = uid;
    comment.authorName = user?.isAnonymous ? '匿名用户' : uid.substring(0, 8);
    comment.authorAvatar = '';
    comment.content = content;
    comment.parentId = parentId;
    comment.createdAt = Date.now();
    comment.likeCount = 0;
    comment.isEdited = false;

    await this.recipeRepo.saveComment(comment);

    // 更新评论数
    const recipe = await this.recipeRepo.getRecipe(recipeId);
    if (recipe) {
      const updateData: Record<string, Object> = { 'commentCount': recipe.commentCount + 1 };
      await this.recipeRepo.updateRecipe(recipeId, updateData);
    }

    return comment;
  }

  /**
   * 获取食谱评论
   */
  async getComments(recipeId: string): Promise<RecipeComment[]> {
    return await this.recipeRepo.getComments(recipeId);
  }

  // ========== 点赞管理 ==========

  /**
   * 点赞/取消点赞
   * @returns true=已点赞, false=已取消
   */
  async toggleLike(recipeId: string): Promise<boolean> {
    const uid = this.authService.getUid();
    return await this.recipeRepo.toggleLike(recipeId, uid);
  }

  /**
   * 检查是否已点赞
   */
  async hasLiked(recipeId: string): Promise<boolean> {
    const uid = this.authService.getUid();
    return await this.recipeRepo.hasLiked(recipeId, uid);
  }

  // ========== 收藏管理 ==========

  /**
   * 收藏/取消收藏食谱
   * @returns true=已收藏, false=已取消
   */
  async toggleBookmark(recipeId: string, note: string): Promise<boolean> {
    const uid = this.authService.getUid();
    return await this.recipeRepo.toggleBookmark(recipeId, uid, note);
  }

  /**
   * 获取用户收藏的食谱ID列表
   */
  async getMyBookmarks(): Promise<string[]> {
    const uid = this.authService.getUid();
    return await this.recipeRepo.getUserBookmarks(uid);
  }

  /**
   * 检查是否已收藏
   */
  async hasBookmarked(recipeId: string): Promise<boolean> {
    const uid = this.authService.getUid();
    return await this.recipeRepo.hasBookmarked(recipeId, uid);
  }

  // ========== 热门/推荐食谱 ==========

  /**
   * 获取热门食谱（按点赞数排序）
   */
  async getPopularRecipes(offset: number, limit: number): Promise<Recipe[]> {
    return await this.recipeRepo.queryApprovedRecipes(offset, limit, '', 'popular');
  }

  /**
   * 获取最新食谱
   */
  async getLatestRecipes(offset: number, limit: number): Promise<Recipe[]> {
    return await this.recipeRepo.queryApprovedRecipes(offset, limit, '', '');
  }
}
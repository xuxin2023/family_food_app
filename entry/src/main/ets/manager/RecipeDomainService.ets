// RecipeDomainService.ets
// 食谱社区领域服务 - 从 AppState 剥离的食谱相关业务逻辑

import { CreateRecipeParams, RecipeCommunityService } from '../service/RecipeCommunityService';
import { Recipe, RecipeQueryParams, RecipeComment } from '../model/Recipe';

export class RecipeDomainService {
  private rs: RecipeCommunityService | null = null;

  constructor(recipeService: RecipeCommunityService | null) {
    this.rs = recipeService;
  }

  async createRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    if (!this.rs) return null;
    return this.rs.createRecipe(params);
  }

  async getRecipeRecommendations(params: RecipeQueryParams): Promise<Recipe[]> {
    if (!this.rs) return [];
    return this.rs.queryRecipes(params);
  }

  async queryCommunityRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    return this.getRecipeRecommendations(params);
  }

  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    if (!this.rs) return null;
    return this.rs.getRecipeDetail(recipeId);
  }

  async getRecipeComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.rs) return [];
    return this.rs.getComments(recipeId);
  }

  async hasLikedRecipe(recipeId: string): Promise<boolean> {
    if (!this.rs) return false;
    return this.rs.hasLiked(recipeId);
  }

  async toggleRecipeLike(recipeId: string): Promise<boolean> {
    if (!this.rs) return false;
    return this.rs.toggleLike(recipeId);
  }

  async toggleRecipeBookmark(recipeId: string, notes: string): Promise<boolean> {
    if (!this.rs) return false;
    return this.rs.toggleBookmark(recipeId, notes);
  }

  async addRecipeComment(recipeId: string, text: string, authorName: string): Promise<RecipeComment | null> {
    if (!this.rs) return null;
    return this.rs.addComment(recipeId, text, authorName);
  }

  async publishRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    return this.createRecipe(params);
  }
}

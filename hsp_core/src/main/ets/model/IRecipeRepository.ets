// IRecipeRepository.ets
// 食谱仓库公共接口 — 供 hsp-service 依赖反转，解耦对 feature-community 的直接依赖
// feature-community.RecipeRepository 实现此接口

import { Recipe } from './Recipe';
import { relationalStore } from '@kit.ArkData';

export interface IRecipeRepository {
  /** 初始化仓库，注入 RDB 存储 */
  init(rdbStore: relationalStore.RdbStore): void;

  /** 查询已审核通过的食谱列表 */
  queryApprovedRecipes(offset: number, limit: number, category?: string, sortBy?: string): Promise<Recipe[]>;

  /** 根据 ID 获取单个食谱 */
  getRecipe(recipeId: string): Promise<Recipe | null>;

  /** 判断用户是否已收藏某食谱 */
  hasBookmarked(recipeId: string, uid: string): Promise<boolean>;
}

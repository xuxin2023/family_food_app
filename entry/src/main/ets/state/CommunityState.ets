import { Recipe, FamilyGroup, GroupSummary, GroupFeed, RecipeComment, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CommunityState';

@ObservedV2
export class CommunityState {
  @Trace recipeList: Recipe[] = [];
  @Trace familyGroup: FamilyGroup | null = null;
  @Trace groupMembers: GroupSummary[] = [];
  @Trace groupFeed: GroupFeed[] = [];
  @Trace isSyncing: boolean = false;
  @Trace pendingRecipes: Recipe[] = [];

  setRecipeList(recipes: Recipe[]): void {
    this.recipeList = recipes;
  }

  setFamilyGroup(group: FamilyGroup | null): void {
    this.familyGroup = group;
  }

  addPendingRecipe(recipe: Recipe): void {
    this.pendingRecipes.push(recipe);
  }

  removePendingRecipe(recipeId: string): void {
    this.pendingRecipes = this.pendingRecipes.filter(r => r.recipeId !== recipeId);
  }

  getPendingRecipeCount(): number {
    return this.pendingRecipes.length;
  }
}

// RecipeRepository.ets - 食谱社区数据仓库 (API 23 refined)
import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  Recipe, RecipeComment, RecipeLike, RecipeBookmark, RecipeIngredient, RecipeStep, RecipeNutrition,
  RecipeDifficulty, RecipeCategory, DietTag, RecipeQueryParams, CreateRecipeParams, HILOG_DOMAIN_DEFAULT,
  IRecipeRepository
} from 'hsp_core';

const TAG = 'RecipeRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export class RecipeUpdate {
  likeCount: number = -1;
  bookmarkCount: number = -1;
  commentCount: number = -1;
  title: string = '';
  description: string = '';
  coverImageUrl: string = '';
  category: string = '';
  difficulty: string = '';
  totalMinutes: number = -1;
  servings: number = -1;
  ingredients: string[] = [];
  steps: string[] = [];
  nutrition: Object | null = null;
  dietTags: string[] = [];
  isApproved: boolean = false;
  isDraft: boolean = false;
}

const TABLE_RECIPE = 'recipe';
const TABLE_COMMENT = 'recipe_comment';
const TABLE_LIKE = 'recipe_like';
const TABLE_BOOKMARK = 'recipe_bookmark';

type ValueBucket = Record<string, string | number | null>;

export class RecipeRepository implements IRecipeRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  init(rdbStore: relationalStore.RdbStore): void {
    this.rdbStore = rdbStore;
  }

  async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    const store = this.rdbStore;
    try {
      const recipeSql = 'CREATE TABLE IF NOT EXISTS ' + TABLE_RECIPE + ' (' +
        'recipe_id TEXT PRIMARY KEY, ' +
        'title TEXT NOT NULL, ' +
        "description TEXT DEFAULT '', " +
        "cover_image_url TEXT DEFAULT '', " +
        'author_uid TEXT NOT NULL, ' +
        "author_name TEXT DEFAULT '', " +
        "author_avatar TEXT DEFAULT '', " +
        "category TEXT DEFAULT 'snack', " +
        "difficulty TEXT DEFAULT 'easy', " +
        'total_minutes INTEGER DEFAULT 0, ' +
        'servings INTEGER DEFAULT 1, ' +
        "ingredients TEXT DEFAULT '[]', " +
        "steps TEXT DEFAULT '[]', " +
        'nutrition TEXT, ' +
        "diet_tags TEXT DEFAULT '[]', " +
        "related_food_id TEXT DEFAULT '', " +
        "from_group_id TEXT DEFAULT '', " +
        'created_at INTEGER NOT NULL, ' +
        'updated_at INTEGER NOT NULL, ' +
        'like_count INTEGER DEFAULT 0, ' +
        'comment_count INTEGER DEFAULT 0, ' +
        'bookmark_count INTEGER DEFAULT 0, ' +
        'is_approved INTEGER DEFAULT 0, ' +
        'is_draft INTEGER DEFAULT 1' +
        ')';
      await store.executeSql(recipeSql);

      const commentSql = 'CREATE TABLE IF NOT EXISTS ' + TABLE_COMMENT + ' (' +
        'comment_id TEXT PRIMARY KEY, ' +
        'recipe_id TEXT NOT NULL, ' +
        'author_uid TEXT NOT NULL, ' +
        "author_name TEXT DEFAULT '', " +
        "author_avatar TEXT DEFAULT '', " +
        'content TEXT NOT NULL, ' +
        "parent_id TEXT DEFAULT '', " +
        'created_at INTEGER NOT NULL, ' +
        'like_count INTEGER DEFAULT 0, ' +
        'is_edited INTEGER DEFAULT 0' +
        ')';
      await store.executeSql(commentSql);

      const likeSql = 'CREATE TABLE IF NOT EXISTS ' + TABLE_LIKE + ' (' +
        'id TEXT PRIMARY KEY, ' +
        'recipe_id TEXT NOT NULL, ' +
        'uid TEXT NOT NULL, ' +
        'created_at INTEGER NOT NULL' +
        ')';
      await store.executeSql(likeSql);

      const bookmarkSql = 'CREATE TABLE IF NOT EXISTS ' + TABLE_BOOKMARK + ' (' +
        'id TEXT PRIMARY KEY, ' +
        'recipe_id TEXT NOT NULL, ' +
        'uid TEXT NOT NULL, ' +
        'created_at INTEGER NOT NULL, ' +
        "note TEXT DEFAULT ''" +
        ')';
      await store.executeSql(bookmarkSql);

      await store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_recipe_author ON ' + TABLE_RECIPE + ' (author_uid)'
      );
      await store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_recipe_category ON ' + TABLE_RECIPE + ' (category)'
      );
      await store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_recipe_created ON ' + TABLE_RECIPE + ' (created_at)'
      );
      await store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_comment_recipe ON ' + TABLE_COMMENT + ' (recipe_id, created_at)'
      );
      await store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_like_recipe ON ' + TABLE_LIKE + ' (recipe_id, uid)'
      );
      await store.executeSql(
        'CREATE INDEX IF NOT EXISTS idx_bookmark_user ON ' + TABLE_BOOKMARK + ' (uid)'
      );

      hilog.info(DOMAIN_ZERO, TAG, 'Recipe tables created');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'createTables failed: %{public}s', JSON.stringify(error));
    }
  }

  async saveRecipe(recipe: Recipe): Promise<void> {
    if (!this.rdbStore) { return; }
    const store = this.rdbStore;
    try {
      const bucket: ValueBucket = {
        'recipe_id': recipe.recipeId, 'title': recipe.title, 'description': recipe.description,
        'cover_image_url': recipe.coverImageUrl, 'author_uid': recipe.authorUid,
        'author_name': recipe.authorName, 'author_avatar': recipe.authorAvatar,
        'category': recipe.category, 'difficulty': recipe.difficulty,
        'total_minutes': recipe.totalMinutes, 'servings': recipe.servings,
        'ingredients': JSON.stringify(recipe.ingredients), 'steps': JSON.stringify(recipe.steps),
        'nutrition': recipe.nutrition ? JSON.stringify(recipe.nutrition) : null,
        'diet_tags': JSON.stringify(recipe.dietTags), 'related_food_id': recipe.relatedFoodId,
        'from_group_id': recipe.fromGroupId, 'created_at': recipe.createdAt,
        'updated_at': recipe.updatedAt, 'like_count': recipe.likeCount,
        'comment_count': recipe.commentCount, 'bookmark_count': recipe.bookmarkCount,
        'is_approved': recipe.isApproved ? 1 : 0, 'is_draft': recipe.isDraft ? 1 : 0
      };
      await store.insert(TABLE_RECIPE, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveRecipe failed: %{public}s', JSON.stringify(error));
    }
  }

  async getRecipe(recipeId: string): Promise<Recipe | null> {
    if (!this.rdbStore) { return null; }
    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('recipe_id', recipeId);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.query(predicates);
      if (resultSet.goToFirstRow()) { return this.parseRecipe(resultSet); }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getRecipe failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } }
    }
  }

  async queryApprovedRecipes(offset: number, limit: number, category: string = '', sortBy: string = ''): Promise<Recipe[]> {
    if (!this.rdbStore) { return []; }
    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('is_draft', 0);
    predicates.equalTo('is_approved', 1);
    if (category.length > 0) { predicates.equalTo('category', category as string); }
    if (sortBy === 'popular') { predicates.orderByDesc('like_count'); }
    else if (sortBy === 'trending') { predicates.orderByDesc('created_at'); }
    else { predicates.orderByDesc('created_at'); }
    return await this.queryRecipes(store, predicates, offset, limit);
  }

  async queryUserRecipes(uid: string, includeDrafts: boolean): Promise<Recipe[]> {
    if (!this.rdbStore) { return []; }
    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('author_uid', uid);
    if (!includeDrafts) { predicates.equalTo('is_draft', 0); }
    predicates.orderByDesc('created_at');
    return await this.queryRecipes(store, predicates, 0, 100);
  }

  async queryGroupRecipes(groupId: string, offset: number, limit: number): Promise<Recipe[]> {
    if (!this.rdbStore) { return []; }
    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('from_group_id', groupId);
    predicates.equalTo('is_draft', 0);
    predicates.orderByDesc('created_at');
    return await this.queryRecipes(store, predicates, offset, limit);
  }

  async updateRecipe(recipeId: string, updates: RecipeUpdate): Promise<void> {
    if (!this.rdbStore) { return; }
    const store = this.rdbStore;
    try {
      const bucket: ValueBucket = {};
      if (updates.title.length > 0 || updates.title !== undefined) { bucket['title'] = updates.title; }
      if (updates.description.length > 0 || updates.description !== undefined) { bucket['description'] = updates.description; }
      if (updates.coverImageUrl.length > 0 || updates.coverImageUrl !== undefined) { bucket['cover_image_url'] = updates.coverImageUrl; }
      if (updates.category.length > 0) { bucket['category'] = updates.category; }
      if (updates.difficulty.length > 0) { bucket['difficulty'] = updates.difficulty; }
      if (updates.totalMinutes >= 0) { bucket['total_minutes'] = updates.totalMinutes; }
      if (updates.servings >= 0) { bucket['servings'] = updates.servings; }
      if (updates.ingredients.length > 0) { bucket['ingredients'] = JSON.stringify(updates.ingredients); }
      if (updates.steps.length > 0) { bucket['steps'] = JSON.stringify(updates.steps); }
      if (updates.nutrition !== null && updates.nutrition !== undefined) { bucket['nutrition'] = JSON.stringify(updates.nutrition); }
      if (updates.dietTags.length > 0) { bucket['diet_tags'] = JSON.stringify(updates.dietTags); }
      if (updates.likeCount >= 0) { bucket['like_count'] = updates.likeCount; }
      if (updates.commentCount >= 0) { bucket['comment_count'] = updates.commentCount; }
      if (updates.bookmarkCount >= 0) { bucket['bookmark_count'] = updates.bookmarkCount; }
      if (updates.isApproved !== undefined) { bucket['is_approved'] = updates.isApproved ? 1 : 0; }
      if (updates.isDraft !== undefined) { bucket['is_draft'] = updates.isDraft ? 1 : 0; }
      bucket['updated_at'] = Date.now();
      const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
      predicates.equalTo('recipe_id', recipeId);
      await store.update(bucket, predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'updateRecipe failed: %{public}s', JSON.stringify(error));
    }
  }

  async deleteRecipe(recipeId: string): Promise<void> {
    if (!this.rdbStore) { return; }
    const store = this.rdbStore;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
      predicates.equalTo('recipe_id', recipeId);
      await store.delete(predicates);
    } catch (error) { hilog.error(DOMAIN_ZERO, TAG, 'deleteRecipe failed: %{public}s', JSON.stringify(error)); }
  }

  async saveComment(comment: RecipeComment): Promise<void> {
    if (!this.rdbStore) { return; }
    const store = this.rdbStore;
    try {
      const bucket: ValueBucket = {
        'comment_id': comment.commentId, 'recipe_id': comment.recipeId,
        'author_uid': comment.authorUid, 'author_name': comment.authorName,
        'author_avatar': comment.authorAvatar, 'content': comment.content,
        'parent_id': comment.parentId, 'created_at': comment.createdAt,
        'like_count': comment.likeCount, 'is_edited': comment.isEdited ? 1 : 0
      };
      await store.insert(TABLE_COMMENT, bucket);
    } catch (error) { hilog.error(DOMAIN_ZERO, TAG, 'saveComment failed: %{public}s', JSON.stringify(error)); }
  }

  async getComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.rdbStore) { return []; }
    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(TABLE_COMMENT);
    predicates.equalTo('recipe_id', recipeId);
    predicates.orderByAsc('created_at');
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.query(predicates);
      const comments: RecipeComment[] = [];
      while (resultSet.goToNextRow()) {
        const c: RecipeComment = new RecipeComment();
        try {
          c.commentId = resultSet.getString(resultSet.getColumnIndex('comment_id'));
          c.recipeId = resultSet.getString(resultSet.getColumnIndex('recipe_id'));
          c.authorUid = resultSet.getString(resultSet.getColumnIndex('author_uid'));
          c.authorName = resultSet.getString(resultSet.getColumnIndex('author_name')) || '';
          c.authorAvatar = resultSet.getString(resultSet.getColumnIndex('author_avatar')) || '';
          c.content = resultSet.getString(resultSet.getColumnIndex('content'));
          c.parentId = resultSet.getString(resultSet.getColumnIndex('parent_id')) || '';
          c.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
          c.likeCount = resultSet.getLong(resultSet.getColumnIndex('like_count'));
          c.isEdited = resultSet.getLong(resultSet.getColumnIndex('is_edited')) === 1;
        } catch (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'parseComment field error: %{public}s', JSON.stringify(err));
        }
        comments.push(c);
      }
      return comments;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getComments failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } }
    }
  }

  async toggleLike(recipeId: string, uid: string = 'self'): Promise<boolean> {
    if (!this.rdbStore) { return false; }
    const store = this.rdbStore;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_LIKE);
      predicates.equalTo('recipe_id', recipeId);
      predicates.equalTo('uid', uid);
      resultSet = await store.query(predicates);
      if (resultSet.goToFirstRow()) {
        let likeId = '';
        try {
          likeId = resultSet.getString(resultSet.getColumnIndex('id'));
        } catch (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'toggleLike getLikeId field error: %{public}s', JSON.stringify(err));
        }
        try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); }
        resultSet = null;
        const delPredicates = new relationalStore.RdbPredicates(TABLE_LIKE);
        delPredicates.equalTo('id', likeId);
        await store.delete(delPredicates);
        const recipe = await this.getRecipe(recipeId);
        if (recipe) {
          const updateLike: RecipeUpdate = new RecipeUpdate();
          updateLike.likeCount = Math.max(0, recipe.likeCount - 1);
          await this.updateRecipe(recipeId, updateLike);
        }
        return false;
      }
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } resultSet = null; }
      const likeBucket: ValueBucket = {
        'id': 'like_' + recipeId + '_' + uid + '_' + String(Date.now()),
        'recipe_id': recipeId, 'uid': uid, 'created_at': Date.now()
      };
      await store.insert(TABLE_LIKE, likeBucket);
      const recipe = await this.getRecipe(recipeId);
      if (recipe) {
        const updateLike2: RecipeUpdate = new RecipeUpdate();
        updateLike2.likeCount = recipe.likeCount + 1;
        await this.updateRecipe(recipeId, updateLike2);
      }
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'toggleLike failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } }
    }
  }

  async hasLiked(recipeId: string, uid: string = 'self'): Promise<boolean> {
    if (!this.rdbStore) { return false; }
    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(TABLE_LIKE);
    predicates.equalTo('recipe_id', recipeId);
    predicates.equalTo('uid', uid);
    let resultSet: relationalStore.ResultSet | null = null;
    try { resultSet = await store.query(predicates); return resultSet.goToFirstRow(); }
    catch (error) { hilog.error(DOMAIN_ZERO, TAG, 'hasLiked failed: %{public}s', JSON.stringify(error)); return false; }
    finally { if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } } }
  }

  async toggleBookmark(recipeId: string, uidOrNotes: string = 'self', note: string = ''): Promise<boolean> {
    let effectiveUid: string = 'self';
    let effectiveNote: string = '';
    if (uidOrNotes !== 'self' && note.length === 0) { effectiveNote = uidOrNotes; }
    else { effectiveUid = uidOrNotes; effectiveNote = note; }
    return this.toggleBookmarkInternal(recipeId, effectiveUid, effectiveNote);
  }

  private async toggleBookmarkInternal(recipeId: string, uid: string, note: string): Promise<boolean> {
    if (!this.rdbStore) { return false; }
    const store = this.rdbStore;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
      predicates.equalTo('recipe_id', recipeId);
      predicates.equalTo('uid', uid);
      resultSet = await store.query(predicates);
      if (resultSet.goToFirstRow()) {
        let bookmarkId = '';
        try {
          bookmarkId = resultSet.getString(resultSet.getColumnIndex('id'));
        } catch (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'toggleBookmark getBookmarkId field error: %{public}s', JSON.stringify(err));
        }
        try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); }
        resultSet = null;
        const delPredicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
        delPredicates.equalTo('id', bookmarkId);
        await store.delete(delPredicates);
        const recipe = await this.getRecipe(recipeId);
        if (recipe) {
          const updateBm: RecipeUpdate = new RecipeUpdate();
          updateBm.bookmarkCount = Math.max(0, recipe.bookmarkCount - 1);
          await this.updateRecipe(recipeId, updateBm);
        }
        return false;
      }
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } resultSet = null; }
      const bmBucket: ValueBucket = {
        'id': 'bm_' + recipeId + '_' + uid + '_' + String(Date.now()),
        'recipe_id': recipeId, 'uid': uid, 'created_at': Date.now(), 'note': note
      };
      await store.insert(TABLE_BOOKMARK, bmBucket);
      const recipe = await this.getRecipe(recipeId);
      if (recipe) {
        const updateBm2: RecipeUpdate = new RecipeUpdate();
        updateBm2.bookmarkCount = recipe.bookmarkCount + 1;
        await this.updateRecipe(recipeId, updateBm2);
      }
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'toggleBookmark failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } }
    }
  }

  async getUserBookmarks(uid: string): Promise<string[]> {
    if (!this.rdbStore) { return []; }
    const store = this.rdbStore;
    const predicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
    predicates.equalTo('uid', uid);
    predicates.orderByDesc('created_at');
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.query(predicates);
      const recipeIds: string[] = [];
      while (resultSet.goToNextRow()) {
        try {
          recipeIds.push(resultSet.getString(resultSet.getColumnIndex('recipe_id')));
        } catch (err) {
          hilog.warn(DOMAIN_ZERO, TAG, 'getUserBookmarks field error: %{public}s', JSON.stringify(err));
        }
      }
      return recipeIds;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getUserBookmarks failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } }
    }
  }

  async hasBookmarked(recipeId: string, uid: string): Promise<boolean> {
    if (!this.rdbStore) { return false; }
    const store = this.rdbStore;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
      predicates.equalTo('recipe_id', recipeId);
      predicates.equalTo('uid', uid);
      resultSet = await store.query(predicates);
      return resultSet.goToFirstRow();
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'hasBookmarked failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } }
    }
  }

  private async queryRecipes(store: relationalStore.RdbStore, predicates: relationalStore.RdbPredicates, offset: number, limit: number): Promise<Recipe[]> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await store.query(predicates);
      const recipes: Recipe[] = [];
      let index = 0;
      while (resultSet.goToNextRow()) {
        if (index >= offset && index < offset + limit) { recipes.push(this.parseRecipe(resultSet)); }
        index++;
      }
      return recipes;
    } catch (error) { hilog.error(DOMAIN_ZERO, TAG, 'queryRecipes failed: %{public}s', JSON.stringify(error)); return []; }
    finally { if (resultSet) { try { resultSet.close(); } catch (closeError) { hilog.warn(DOMAIN_ZERO, TAG, 'Exception: %{public}s', JSON.stringify(closeError)); } } }
  }

  private parseRecipe(resultSet: relationalStore.ResultSet): Recipe {
    const recipe: Recipe = new Recipe();
    try {
      recipe.recipeId = resultSet.getString(resultSet.getColumnIndex('recipe_id'));
      recipe.title = resultSet.getString(resultSet.getColumnIndex('title'));
      recipe.description = resultSet.getString(resultSet.getColumnIndex('description')) || '';
      recipe.coverImageUrl = resultSet.getString(resultSet.getColumnIndex('cover_image_url')) || '';
      recipe.authorUid = resultSet.getString(resultSet.getColumnIndex('author_uid'));
      recipe.authorName = resultSet.getString(resultSet.getColumnIndex('author_name')) || '';
      recipe.authorAvatar = resultSet.getString(resultSet.getColumnIndex('author_avatar')) || '';
      const categoryVal = resultSet.getString(resultSet.getColumnIndex('category'));
      recipe.category = (categoryVal || 'snack') as RecipeCategory;
      const difficultyVal = resultSet.getString(resultSet.getColumnIndex('difficulty'));
      recipe.difficulty = (difficultyVal || 'easy') as RecipeDifficulty;
      recipe.totalMinutes = resultSet.getLong(resultSet.getColumnIndex('total_minutes'));
      recipe.servings = resultSet.getLong(resultSet.getColumnIndex('servings'));
      const ingredientsRaw = resultSet.getString(resultSet.getColumnIndex('ingredients'));
      if (ingredientsRaw && ingredientsRaw.length > 0) { try { recipe.ingredients = JSON.parse(ingredientsRaw) as RecipeIngredient[]; } catch (_) { recipe.ingredients = []; } }
      const stepsRaw = resultSet.getString(resultSet.getColumnIndex('steps'));
      if (stepsRaw && stepsRaw.length > 0) { try { recipe.steps = JSON.parse(stepsRaw) as RecipeStep[]; } catch (_) { recipe.steps = []; } }
      const nutritionRaw = resultSet.getString(resultSet.getColumnIndex('nutrition'));
      if (nutritionRaw && nutritionRaw.length > 0) { try { recipe.nutrition = JSON.parse(nutritionRaw) as RecipeNutrition; } catch (_) { /* parse failed, keep default */ } }
      const dietTagsRaw = resultSet.getString(resultSet.getColumnIndex('diet_tags'));
      if (dietTagsRaw && dietTagsRaw.length > 0) { try { recipe.dietTags = JSON.parse(dietTagsRaw) as DietTag[]; } catch (_) { recipe.dietTags = []; } }
      recipe.relatedFoodId = resultSet.getString(resultSet.getColumnIndex('related_food_id')) || '';
      recipe.fromGroupId = resultSet.getString(resultSet.getColumnIndex('from_group_id')) || '';
      recipe.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      recipe.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
      recipe.likeCount = resultSet.getLong(resultSet.getColumnIndex('like_count'));
      recipe.commentCount = resultSet.getLong(resultSet.getColumnIndex('comment_count'));
      recipe.bookmarkCount = resultSet.getLong(resultSet.getColumnIndex('bookmark_count'));
      recipe.isApproved = resultSet.getLong(resultSet.getColumnIndex('is_approved')) === 1;
      recipe.isDraft = resultSet.getLong(resultSet.getColumnIndex('is_draft')) === 1;
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, 'parseRecipe field error: %{public}s', JSON.stringify(err));
    }
    return recipe;
  }
}

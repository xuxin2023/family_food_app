// RecipeRepository.ets
// 食谱社区数据仓库 - RdbStore (SQLite)

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  Recipe, RecipeComment, RecipeLike, RecipeBookmark, RecipeIngredient, RecipeStep, RecipeNutrition, RecipeDifficulty, RecipeCategory, DietTag, RecipeQueryParams, CreateRecipeParams, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';


const TAG = 'RecipeRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class RecipeUpdate {
  likeCount: number = -1;
  bookmarkCount: number = -1;
  commentCount: number = -1;
  title: string = '';
  description: string = '';
  coverImageUrl: string = '';
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

export class RecipeRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  init(rdbStore: relationalStore.RdbStore): void {
    this.rdbStore = rdbStore;
  }

  async createTables(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    try {
      const recipeSql = `CREATE TABLE IF NOT EXISTS ${TABLE_RECIPE} (
      recipe_id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT DEFAULT '',
      cover_image_url TEXT DEFAULT '',
      author_uid TEXT NOT NULL,
      author_name TEXT DEFAULT '',
      author_avatar TEXT DEFAULT '',
      category TEXT DEFAULT 'snack',
      difficulty TEXT DEFAULT 'easy',
      total_minutes INTEGER DEFAULT 0,
      servings INTEGER DEFAULT 1,
      ingredients TEXT DEFAULT '[]',
      steps TEXT DEFAULT '[]',
      nutrition TEXT,
      diet_tags TEXT DEFAULT '[]',
      related_food_id TEXT DEFAULT '',
      from_group_id TEXT DEFAULT '',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      like_count INTEGER DEFAULT 0,
      comment_count INTEGER DEFAULT 0,
      bookmark_count INTEGER DEFAULT 0,
      is_approved INTEGER DEFAULT 0,
      is_draft INTEGER DEFAULT 1
    )`;
      await this.rdbStore.executeSql(recipeSql);

      const commentSql = `CREATE TABLE IF NOT EXISTS ${TABLE_COMMENT} (
      comment_id TEXT PRIMARY KEY,
      recipe_id TEXT NOT NULL,
      author_uid TEXT NOT NULL,
      author_name TEXT DEFAULT '',
      author_avatar TEXT DEFAULT '',
      content TEXT NOT NULL,
      parent_id TEXT DEFAULT '',
      created_at INTEGER NOT NULL,
      like_count INTEGER DEFAULT 0,
      is_edited INTEGER DEFAULT 0
    )`;
      await this.rdbStore.executeSql(commentSql);

      const likeSql = `CREATE TABLE IF NOT EXISTS ${TABLE_LIKE} (
      id TEXT PRIMARY KEY,
      recipe_id TEXT NOT NULL,
      uid TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )`;
      await this.rdbStore.executeSql(likeSql);

      const bookmarkSql = `CREATE TABLE IF NOT EXISTS ${TABLE_BOOKMARK} (
      id TEXT PRIMARY KEY,
      recipe_id TEXT NOT NULL,
      uid TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      note TEXT DEFAULT ''
    )`;
      await this.rdbStore.executeSql(bookmarkSql);

      // 索引
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_recipe_author ON ${TABLE_RECIPE} (author_uid)`
      );
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_recipe_category ON ${TABLE_RECIPE} (category)`
      );
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_recipe_created ON ${TABLE_RECIPE} (created_at)`
      );
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_comment_recipe ON ${TABLE_COMMENT} (recipe_id, created_at)`
      );
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_like_recipe ON ${TABLE_LIKE} (recipe_id, uid)`
      );
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_bookmark_user ON ${TABLE_BOOKMARK} (uid)`
      );

      hilog.info(DOMAIN_ZERO, TAG, 'Recipe tables created');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'createTables failed: %{public}s', JSON.stringify(error));
    }
  }

  // ========== 食谱 CRUD ==========

  async saveRecipe(recipe: Recipe): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      const bucket = new relationalStore.ValuesBucket();
      bucket.put('recipe_id', recipe.recipeId);
      bucket.put('title', recipe.title);
      bucket.put('description', recipe.description);
      bucket.put('cover_image_url', recipe.coverImageUrl);
      bucket.put('author_uid', recipe.authorUid);
      bucket.put('author_name', recipe.authorName);
      bucket.put('author_avatar', recipe.authorAvatar);
      bucket.put('category', recipe.category);
      bucket.put('difficulty', recipe.difficulty);
      bucket.put('total_minutes', recipe.totalMinutes);
      bucket.put('servings', recipe.servings);
      bucket.put('ingredients', JSON.stringify(recipe.ingredients));
      bucket.put('steps', JSON.stringify(recipe.steps));
      bucket.put('nutrition', recipe.nutrition ? JSON.stringify(recipe.nutrition) : null);
      bucket.put('diet_tags', JSON.stringify(recipe.dietTags));
      bucket.put('related_food_id', recipe.relatedFoodId);
      bucket.put('from_group_id', recipe.fromGroupId);
      bucket.put('created_at', recipe.createdAt);
      bucket.put('updated_at', recipe.updatedAt);
      bucket.put('like_count', recipe.likeCount);
      bucket.put('comment_count', recipe.commentCount);
      bucket.put('bookmark_count', recipe.bookmarkCount);
      bucket.put('is_approved', recipe.isApproved ? 1 : 0);
      bucket.put('is_draft', recipe.isDraft ? 1 : 0);
      await this.rdbStore.insert(TABLE_RECIPE, bucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveRecipe failed: %{public}s', JSON.stringify(error));
    }
  }

  async getRecipe(recipeId: string): Promise<Recipe | null> {
    if (!this.rdbStore) {
      return null;
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('recipe_id', recipeId);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        return this.parseRecipe(resultSet);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getRecipe failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  /** 查询社区食谱（非草稿、已审核） */
  async queryApprovedRecipes(
    offset: number, limit: number,
    category: string = '', sortBy: string = ''
  ): Promise<Recipe[]> {
    if (!this.rdbStore) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('is_draft', 0);
    predicates.equalTo('is_approved', 1);
    if (category.length > 0) {
      predicates.equalTo('category', category as string);
    }
    if (sortBy === 'popular') {
      predicates.orderByDesc('like_count');
    } else if (sortBy === 'trending') {
      predicates.orderByDesc('created_at');
    } else {
      predicates.orderByDesc('created_at');
    }
    return await this.queryRecipes(predicates, offset, limit);
  }

  /** 查询用户自己的食谱 */
  async queryUserRecipes(uid: string, includeDrafts: boolean): Promise<Recipe[]> {
    if (!this.rdbStore) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('author_uid', uid);
    if (!includeDrafts) {
      predicates.equalTo('is_draft', 0);
    }
    predicates.orderByDesc('created_at');
    return await this.queryRecipes(predicates, 0, 100);
  }

  /** 查询群组食谱分享 */
  async queryGroupRecipes(groupId: string, offset: number, limit: number): Promise<Recipe[]> {
    if (!this.rdbStore) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('from_group_id', groupId);
    predicates.equalTo('is_draft', 0);
    predicates.orderByDesc('created_at');
    return await this.queryRecipes(predicates, offset, limit);
  }

  async updateRecipe(recipeId: string, updates: RecipeUpdate): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      const bucket = new relationalStore.ValuesBucket();
      if (updates.title !== undefined) {
        bucket.put('title', updates.title);
      }
      if (updates.description !== undefined) {
        bucket.put('description', updates.description);
      }
      if (updates.coverImageUrl !== undefined) {
        bucket.put('cover_image_url', updates.coverImageUrl);
      }
      if (updates.ingredients !== undefined) {
        bucket.put('ingredients', JSON.stringify(updates.ingredients));
      }
      if (updates.steps !== undefined) {
        bucket.put('steps', JSON.stringify(updates.steps));
      }
      if (updates.nutrition !== undefined) {
        bucket.put('nutrition', JSON.stringify(updates.nutrition));
      }
      if (updates.dietTags !== undefined) {
        bucket.put('diet_tags', JSON.stringify(updates.dietTags));
      }
      if (updates.likeCount !== undefined) {
        bucket.put('like_count', updates.likeCount);
      }
      if (updates.commentCount !== undefined) {
        bucket.put('comment_count', updates.commentCount);
      }
      if (updates.bookmarkCount !== undefined) {
        bucket.put('bookmark_count', updates.bookmarkCount);
      }
      if (updates.isApproved !== undefined) {
        bucket.put('is_approved', updates.isApproved ? 1 : 0);
      }
      if (updates.isDraft !== undefined) {
        bucket.put('is_draft', updates.isDraft ? 1 : 0);
      }
      bucket.put('updated_at', Date.now());

      const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
      predicates.equalTo('recipe_id', recipeId);
      await this.rdbStore.update(bucket, predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'updateRecipe failed: %{public}s', JSON.stringify(error));
    }
  }

  async deleteRecipe(recipeId: string): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
      predicates.equalTo('recipe_id', recipeId);
      await this.rdbStore.delete(predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'deleteRecipe failed: %{public}s', JSON.stringify(error));
    }
  }

  // ========== 评论管理 ==========

  async saveComment(comment: RecipeComment): Promise<void> {
    if (!this.rdbStore) {
      return;
    }
    try {
      const bucket = new relationalStore.ValuesBucket();
      bucket.put('comment_id', comment.commentId);
      bucket.put('recipe_id', comment.recipeId);
      bucket.put('author_uid', comment.authorUid);
      bucket.put('author_name', comment.authorName);
      bucket.put('author_avatar', comment.authorAvatar);
      bucket.put('content', comment.content);
      bucket.put('parent_id', comment.parentId);
      bucket.put('created_at', comment.createdAt);
      bucket.put('like_count', comment.likeCount);
      bucket.put('is_edited', comment.isEdited ? 1 : 0);
      await this.rdbStore.insert(TABLE_COMMENT, bucket);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveComment failed: %{public}s', JSON.stringify(error));
    }
  }

  async getComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.rdbStore) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_COMMENT);
    predicates.equalTo('recipe_id', recipeId);
    predicates.orderByAsc('created_at');
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const comments: RecipeComment[] = [];
      while (resultSet.goToNextRow()) {
        const c = new RecipeComment();
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
        comments.push(c);
      }
      return comments;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getComments failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  // ========== 点赞管理 ==========

  async toggleLike(recipeId: string, uid: string = 'self'): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_LIKE);
      predicates.equalTo('recipe_id', recipeId);
      predicates.equalTo('uid', uid);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        // 已点赞，取消
        const likeId = resultSet.getString(resultSet.getColumnIndex('id'));
        try { resultSet.close(); } catch (closeError) { /* safe */ }
        resultSet = null;
        const delPredicates = new relationalStore.RdbPredicates(TABLE_LIKE);
        delPredicates.equalTo('id', likeId);
        await this.rdbStore.delete(delPredicates);
        // 减少点赞数
        const recipe = await this.getRecipe(recipeId);
        if (recipe) {
          const updateLike = new RecipeUpdate(); updateLike.likeCount = Math.max(0, recipe.likeCount - 1);
          await this.updateRecipe(recipeId, updateLike);
        }
        return false;
      }
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
        resultSet = null;
      }

      // 未点赞，添加
      const likeBucket = new relationalStore.ValuesBucket();
      likeBucket.put('id', `like_${recipeId}_${uid}_${Date.now()}`);
      likeBucket.put('recipe_id', recipeId);
      likeBucket.put('uid', uid);
      likeBucket.put('created_at', Date.now());
      await this.rdbStore.insert(TABLE_LIKE, likeBucket);
      // 增加点赞数
      const recipe = await this.getRecipe(recipeId);
      if (recipe) {
        const updateLike2 = new RecipeUpdate(); updateLike2.likeCount = recipe.likeCount + 1;
        await this.updateRecipe(recipeId, updateLike2);
      }
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'toggleLike failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  async hasLiked(recipeId: string, uid: string = 'self'): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_LIKE);
    predicates.equalTo('recipe_id', recipeId);
    predicates.equalTo('uid', uid);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      return resultSet.goToFirstRow();
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'hasLiked failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  // ========== 收藏管理 ==========

  async toggleBookmark(recipeId: string, uidOrNotes: string = 'self', note: string = ''): Promise<boolean> {
    // 智能判断：第一个参数可能是 uid 或 notes
    let effectiveUid: string = 'self';
    let effectiveNote: string = '';
    if (uidOrNotes !== 'self' && note === '') {
      // 两个参数调用：toggleBookmark(recipeId, notes)
      effectiveNote = uidOrNotes;
    } else {
      effectiveUid = uidOrNotes;
      effectiveNote = note;
    }
    return this.toggleBookmarkInternal(recipeId, effectiveUid, effectiveNote);
  }

  private async toggleBookmarkInternal(recipeId: string, uid: string, note: string): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
      predicates.equalTo('recipe_id', recipeId);
      predicates.equalTo('uid', uid);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        // 已收藏，取消
        const bookmarkId = resultSet.getString(resultSet.getColumnIndex('id'));
        try { resultSet.close(); } catch (closeError) { /* safe */ }
        resultSet = null;
        const delPredicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
        delPredicates.equalTo('id', bookmarkId);
        await this.rdbStore.delete(delPredicates);
        const recipe = await this.getRecipe(recipeId);
        if (recipe) {
          const updateBm = new RecipeUpdate(); updateBm.bookmarkCount = Math.max(0, recipe.bookmarkCount - 1);
          await this.updateRecipe(recipeId, updateBm);
        }
        return false;
      }
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
        resultSet = null;
      }

      const bmBucket = new relationalStore.ValuesBucket();
      bmBucket.put('id', `bm_${recipeId}_${uid}_${Date.now()}`);
      bmBucket.put('recipe_id', recipeId);
      bmBucket.put('uid', uid);
      bmBucket.put('created_at', Date.now());
      bmBucket.put('note', note);
      await this.rdbStore.insert(TABLE_BOOKMARK, bmBucket);
      const recipe = await this.getRecipe(recipeId);
      if (recipe) {
        const updateBm2 = new RecipeUpdate(); updateBm2.bookmarkCount = recipe.bookmarkCount + 1;
        await this.updateRecipe(recipeId, updateBm2);
      }
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'toggleBookmark failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  async getUserBookmarks(uid: string): Promise<string[]> {
    if (!this.rdbStore) {
      return [];
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
    predicates.equalTo('uid', uid);
    predicates.orderByDesc('created_at');
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const recipeIds: string[] = [];
      while (resultSet.goToNextRow()) {
        recipeIds.push(resultSet.getString(resultSet.getColumnIndex('recipe_id')));
      }
      return recipeIds;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getUserBookmarks failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  async hasBookmarked(recipeId: string, uid: string): Promise<boolean> {
    if (!this.rdbStore) {
      return false;
    }
    const predicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
    predicates.equalTo('recipe_id', recipeId);
    predicates.equalTo('uid', uid);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      return resultSet.goToFirstRow();
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'hasBookmarked failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  // ========== 内部方法 ==========

  private parseRecipe(resultSet: relationalStore.ResultSet): Recipe {
    const recipe = new Recipe();
    recipe.recipeId = resultSet.getString(resultSet.getColumnIndex('recipe_id'));
    recipe.title = resultSet.getString(resultSet.getColumnIndex('title'));
    recipe.description = resultSet.getString(resultSet.getColumnIndex('description')) || '';
    recipe.coverImageUrl = resultSet.getString(resultSet.getColumnIndex('cover_image_url')) || '';
    recipe.authorUid = resultSet.getString(resultSet.getColumnIndex('author_uid'));
    recipe.authorName = resultSet.getString(resultSet.getColumnIndex('author_name')) || '';
    recipe.authorAvatar = resultSet.getString(resultSet.getColumnIndex('author_avatar')) || '';
    recipe.category = resultSet.getString(resultSet.getColumnIndex('category')) as RecipeCategory;
    recipe.difficulty = resultSet.getString(resultSet.getColumnIndex('difficulty')) as RecipeDifficulty;
    recipe.totalMinutes = resultSet.getLong(resultSet.getColumnIndex('total_minutes'));
    recipe.servings = resultSet.getLong(resultSet.getColumnIndex('servings'));
    recipe.ingredients = this.parseJSONArray<RecipeIngredient>(
      resultSet.getString(resultSet.getColumnIndex('ingredients')) || '[]');
    recipe.steps = this.parseJSONArray<RecipeStep>(
      resultSet.getString(resultSet.getColumnIndex('steps')) || '[]');
    const nutritionStr = resultSet.getString(resultSet.getColumnIndex('nutrition'));
    if (nutritionStr) {
      recipe.nutrition = this.parseJSON<RecipeNutrition>(nutritionStr);
    }
    recipe.dietTags = this.parseJSONArray<DietTag>(
      resultSet.getString(resultSet.getColumnIndex('diet_tags')) || '[]');
    recipe.relatedFoodId = resultSet.getString(resultSet.getColumnIndex('related_food_id')) || '';
    recipe.fromGroupId = resultSet.getString(resultSet.getColumnIndex('from_group_id')) || '';
    recipe.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    recipe.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    recipe.likeCount = resultSet.getLong(resultSet.getColumnIndex('like_count'));
    recipe.commentCount = resultSet.getLong(resultSet.getColumnIndex('comment_count'));
    recipe.bookmarkCount = resultSet.getLong(resultSet.getColumnIndex('bookmark_count'));
    recipe.isApproved = resultSet.getLong(resultSet.getColumnIndex('is_approved')) === 1;
    recipe.isDraft = resultSet.getLong(resultSet.getColumnIndex('is_draft')) === 1;
    return recipe;
  }

  private parseJSONArray<T>(jsonStr: string): T[] {
    try {
      return JSON.parse(jsonStr) as T[];
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'parseJSONArray failed: %{public}s', JSON.stringify(e));
      return [] as T[];
    }
  }

  private parseJSON<T>(jsonStr: string): T | null {
    try {
      return JSON.parse(jsonStr) as T;
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'parseJSON failed: %{public}s', JSON.stringify(e));
      return null;
    }
  }

  private async queryRecipes(
    predicates: relationalStore.RdbPredicates, offset: number, limit: number
  ): Promise<Recipe[]> {
    if (!this.rdbStore) {
      return [];
    }
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const recipes: Recipe[] = [];
      let currentIndex: number = 0;
      while (resultSet.goToNextRow()) {
        if (currentIndex >= offset && recipes.length < limit) {
          recipes.push(this.parseRecipe(resultSet));
        }
        currentIndex++;
      }
      return recipes;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'queryRecipes failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  // ========== AppState 兼容桥 ==========

  async createRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    const recipe = new Recipe();
    recipe.recipeId = 'r_' + Date.now().toString(36);
    recipe.title = params.title || '';
    recipe.description = params.description || '';
    recipe.coverImageUrl = params.coverImageUrl || '';
    recipe.authorUid = 'self';
    recipe.category = (params.category as RecipeCategory) || RecipeCategory.SNACK;
    recipe.difficulty = (params.difficulty as RecipeDifficulty) || RecipeDifficulty.EASY;
    recipe.totalMinutes = params.totalMinutes || 0;
    recipe.servings = params.servings || 1;
    recipe.ingredients = params.ingredients || [];
    recipe.steps = params.steps || [];
    recipe.dietTags = params.dietTags || [];
    recipe.createdAt = Date.now();
    recipe.updatedAt = Date.now();
    recipe.isDraft = false;
    recipe.isApproved = true;
    await this.saveRecipe(recipe);
    return this.getRecipe(recipe.recipeId);
  }

  async getRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    return this.queryApprovedRecipes(
      params.offset || 0, params.limit || 20, params.category || '', params.sortBy || ''
    );
  }

  async getRecipeById(recipeId: string): Promise<Recipe | null> {
    return this.getRecipe(recipeId);
  }

  async addComment(recipeId: string, text: string, authorName: string): Promise<RecipeComment | null> {
    const comment = new RecipeComment();
    comment.commentId = 'c_' + Date.now().toString(36);
    comment.recipeId = recipeId;
    comment.authorUid = 'self';
    comment.authorName = authorName;
    comment.content = text;
    comment.createdAt = Date.now();
    comment.likeCount = 0;
    comment.isEdited = false;
    comment.parentId = '';
    comment.authorAvatar = '';
    await this.saveComment(comment);
    return comment;
  }
}

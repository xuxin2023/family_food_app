// RecipeRepository.ets
// 食谱社区数据仓库 - RdbStore (SQLite)

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  Recipe, RecipeComment, RecipeLike, RecipeBookmark,
  RecipeIngredient, RecipeStep, RecipeNutrition,
  RecipeDifficulty, RecipeCategory, DietTag
} from '../model/Recipe';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'RecipeRepository';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

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
    if (!this.rdbStore) return;

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
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        recipe_id: recipe.recipeId,
        title: recipe.title,
        description: recipe.description,
        cover_image_url: recipe.coverImageUrl,
        author_uid: recipe.authorUid,
        author_name: recipe.authorName,
        author_avatar: recipe.authorAvatar,
        category: recipe.category,
        difficulty: recipe.difficulty,
        total_minutes: recipe.totalMinutes,
        servings: recipe.servings,
        ingredients: JSON.stringify(recipe.ingredients),
        steps: JSON.stringify(recipe.steps),
        nutrition: recipe.nutrition ? JSON.stringify(recipe.nutrition) : null,
        diet_tags: JSON.stringify(recipe.dietTags),
        related_food_id: recipe.relatedFoodId,
        from_group_id: recipe.fromGroupId,
        created_at: recipe.createdAt,
        updated_at: recipe.updatedAt,
        like_count: recipe.likeCount,
        comment_count: recipe.commentCount,
        bookmark_count: recipe.bookmarkCount,
        is_approved: recipe.isApproved ? 1 : 0,
        is_draft: recipe.isDraft ? 1 : 0
      };
      await this.rdbStore.insert(TABLE_RECIPE, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveRecipe failed: %{public}s', JSON.stringify(error));
    }
  }

  async getRecipe(recipeId: string): Promise<Recipe | null> {
    if (!this.rdbStore) return null;
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
        resultSet.close();
      }
    }
  }

  /** 查询社区食谱（非草稿、已审核） */
  async queryApprovedRecipes(
    offset: number, limit: number,
    category?: string, sortBy?: string
  ): Promise<Recipe[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('is_draft', 0);
    predicates.equalTo('is_approved', 1);
    if (category && category.length > 0) {
      predicates.equalTo('category', category);
    }
    if (sortBy === 'popular') {
      predicates.orderByDesc('like_count');
    } else if (sortBy === 'trending') {
      predicates.orderByDesc('created_at');
      // trending = 最近7天按点赞排序
    } else {
      predicates.orderByDesc('created_at');
    }
    return await this.queryRecipes(predicates, offset, limit);
  }

  /** 查询用户自己的食谱 */
  async queryUserRecipes(uid: string, includeDrafts: boolean): Promise<Recipe[]> {
    if (!this.rdbStore) return [];
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
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
    predicates.equalTo('from_group_id', groupId);
    predicates.equalTo('is_draft', 0);
    predicates.orderByDesc('created_at');
    return await this.queryRecipes(predicates, offset, limit);
  }

  async updateRecipe(recipeId: string, updates: Partial<Recipe>): Promise<void> {
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {};
      if (updates.title !== undefined) bucket['title'] = updates.title;
      if (updates.description !== undefined) bucket['description'] = updates.description;
      if (updates.coverImageUrl !== undefined) bucket['cover_image_url'] = updates.coverImageUrl;
      if (updates.ingredients !== undefined) bucket['ingredients'] = JSON.stringify(updates.ingredients);
      if (updates.steps !== undefined) bucket['steps'] = JSON.stringify(updates.steps);
      if (updates.nutrition !== undefined) bucket['nutrition'] = JSON.stringify(updates.nutrition);
      if (updates.dietTags !== undefined) bucket['diet_tags'] = JSON.stringify(updates.dietTags);
      if (updates.likeCount !== undefined) bucket['like_count'] = updates.likeCount;
      if (updates.commentCount !== undefined) bucket['comment_count'] = updates.commentCount;
      if (updates.bookmarkCount !== undefined) bucket['bookmark_count'] = updates.bookmarkCount;
      if (updates.isApproved !== undefined) bucket['is_approved'] = updates.isApproved ? 1 : 0;
      if (updates.isDraft !== undefined) bucket['is_draft'] = updates.isDraft ? 1 : 0;
      bucket['updated_at'] = Date.now();

      const predicates = new relationalStore.RdbPredicates(TABLE_RECIPE);
      predicates.equalTo('recipe_id', recipeId);
      await this.rdbStore.update(bucket, predicates);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'updateRecipe failed: %{public}s', JSON.stringify(error));
    }
  }

  async deleteRecipe(recipeId: string): Promise<void> {
    if (!this.rdbStore) return;
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
    if (!this.rdbStore) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        comment_id: comment.commentId,
        recipe_id: comment.recipeId,
        author_uid: comment.authorUid,
        author_name: comment.authorName,
        author_avatar: comment.authorAvatar,
        content: comment.content,
        parent_id: comment.parentId,
        created_at: comment.createdAt,
        like_count: comment.likeCount,
        is_edited: comment.isEdited ? 1 : 0
      };
      await this.rdbStore.insert(TABLE_COMMENT, bucket);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveComment failed: %{public}s', JSON.stringify(error));
    }
  }

  async getComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_COMMENT);
    predicates.equalTo('recipe_id', recipeId);
    predicates.orderByAsc('created_at');
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const comments: RecipeComment[] = [];
      while (resultSet.goToNextRow()) {
        comments.push({
          commentId: resultSet.getString(resultSet.getColumnIndex('comment_id')),
          recipeId: resultSet.getString(resultSet.getColumnIndex('recipe_id')),
          authorUid: resultSet.getString(resultSet.getColumnIndex('author_uid')),
          authorName: resultSet.getString(resultSet.getColumnIndex('author_name')) || '',
          authorAvatar: resultSet.getString(resultSet.getColumnIndex('author_avatar')) || '',
          content: resultSet.getString(resultSet.getColumnIndex('content')),
          parentId: resultSet.getString(resultSet.getColumnIndex('parent_id')) || '',
          createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
          likeCount: resultSet.getLong(resultSet.getColumnIndex('like_count')),
          isEdited: resultSet.getLong(resultSet.getColumnIndex('is_edited')) === 1
        });
      }
      return comments;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getComments failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  // ========== 点赞管理 ==========

  async toggleLike(recipeId: string, uid: string): Promise<boolean> {
    if (!this.rdbStore) return false;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      // 检查是否已点赞
      const predicates = new relationalStore.RdbPredicates(TABLE_LIKE);
      predicates.equalTo('recipe_id', recipeId);
      predicates.equalTo('uid', uid);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        // 已点赞，取消
        const likeId = resultSet.getString(resultSet.getColumnIndex('id'));
        resultSet.close();
        resultSet = null;
        const delPredicates = new relationalStore.RdbPredicates(TABLE_LIKE);
        delPredicates.equalTo('id', likeId);
        await this.rdbStore.delete(delPredicates);
        // 减少点赞数
        const recipe = await this.getRecipe(recipeId);
        if (recipe) {
          await this.updateRecipe(recipeId, { likeCount: Math.max(0, recipe.likeCount - 1) });
        }
        return false;
      }
      if (resultSet) {
        resultSet.close();
        resultSet = null;
      }

      // 未点赞，添加
      const like: RecipeLike = {
        id: `like_${recipeId}_${uid}_${Date.now()}`,
        recipeId: recipeId,
        uid: uid,
        createdAt: Date.now()
      };
      const bucket: relationalStore.ValuesBucket = {
        id: like.id,
        recipe_id: like.recipeId,
        uid: like.uid,
        created_at: like.createdAt
      };
      await this.rdbStore.insert(TABLE_LIKE, bucket);
      // 增加点赞数
      const recipe = await this.getRecipe(recipeId);
      if (recipe) {
        await this.updateRecipe(recipeId, { likeCount: recipe.likeCount + 1 });
      }
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'toggleLike failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async hasLiked(recipeId: string, uid: string): Promise<boolean> {
    if (!this.rdbStore) return false;
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
        resultSet.close();
      }
    }
  }

  // ========== 收藏管理 ==========

  async toggleBookmark(recipeId: string, uid: string, note: string): Promise<boolean> {
    if (!this.rdbStore) return false;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const predicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
      predicates.equalTo('recipe_id', recipeId);
      predicates.equalTo('uid', uid);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        // 已收藏，取消
        const bookmarkId = resultSet.getString(resultSet.getColumnIndex('id'));
        resultSet.close();
        resultSet = null;
        const delPredicates = new relationalStore.RdbPredicates(TABLE_BOOKMARK);
        delPredicates.equalTo('id', bookmarkId);
        await this.rdbStore.delete(delPredicates);
        const recipe = await this.getRecipe(recipeId);
        if (recipe) {
          await this.updateRecipe(recipeId, { bookmarkCount: Math.max(0, recipe.bookmarkCount - 1) });
        }
        return false;
      }
      if (resultSet) {
        resultSet.close();
        resultSet = null;
      }

      const bookmark: RecipeBookmark = {
        id: `bm_${recipeId}_${uid}_${Date.now()}`,
        recipeId: recipeId,
        uid: uid,
        createdAt: Date.now(),
        note: note
      };
      const bucket: relationalStore.ValuesBucket = {
        id: bookmark.id,
        recipe_id: bookmark.recipeId,
        uid: bookmark.uid,
        created_at: bookmark.createdAt,
        note: bookmark.note
      };
      await this.rdbStore.insert(TABLE_BOOKMARK, bucket);
      const recipe = await this.getRecipe(recipeId);
      if (recipe) {
        await this.updateRecipe(recipeId, { bookmarkCount: recipe.bookmarkCount + 1 });
      }
      return true;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'toggleBookmark failed: %{public}s', JSON.stringify(error));
      return false;
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  async getUserBookmarks(uid: string): Promise<string[]> {
    if (!this.rdbStore) return [];
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
        resultSet.close();
      }
    }
  }

  async hasBookmarked(recipeId: string, uid: string): Promise<boolean> {
    if (!this.rdbStore) return false;
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
        resultSet.close();
      }
    }
  }

  // ========== 内部方法 ==========

  private parseRecipe(resultSet: relationalStore.ResultSet): Recipe {
    const parseJSON = (str: string, defaultVal: object): object => {
      try { return JSON.parse(str); } catch (e) { return defaultVal; }
    };

    const nutritionStr = resultSet.getString(resultSet.getColumnIndex('nutrition'));

    const defaultArr: object[] = JSON.parse('[]') as object[];
    const defaultObj: object = JSON.parse('{}') as object;
    return {
      recipeId: resultSet.getString(resultSet.getColumnIndex('recipe_id')),
      title: resultSet.getString(resultSet.getColumnIndex('title')),
      description: resultSet.getString(resultSet.getColumnIndex('description')) || '',
      coverImageUrl: resultSet.getString(resultSet.getColumnIndex('cover_image_url')) || '',
      authorUid: resultSet.getString(resultSet.getColumnIndex('author_uid')),
      authorName: resultSet.getString(resultSet.getColumnIndex('author_name')) || '',
      authorAvatar: resultSet.getString(resultSet.getColumnIndex('author_avatar')) || '',
      category: resultSet.getString(resultSet.getColumnIndex('category')) as RecipeCategory,
      difficulty: resultSet.getString(resultSet.getColumnIndex('difficulty')) as RecipeDifficulty,
      totalMinutes: resultSet.getLong(resultSet.getColumnIndex('total_minutes')),
      servings: resultSet.getLong(resultSet.getColumnIndex('servings')),
      ingredients: parseJSON(resultSet.getString(resultSet.getColumnIndex('ingredients')) || '[]', defaultArr) as RecipeIngredient[],
      steps: parseJSON(resultSet.getString(resultSet.getColumnIndex('steps')) || '[]', defaultArr) as RecipeStep[],
      nutrition: nutritionStr ? parseJSON(nutritionStr, defaultObj) as RecipeNutrition : null,
      dietTags: parseJSON(resultSet.getString(resultSet.getColumnIndex('diet_tags')) || '[]', defaultArr) as DietTag[],
      relatedFoodId: resultSet.getString(resultSet.getColumnIndex('related_food_id')) || '',
      fromGroupId: resultSet.getString(resultSet.getColumnIndex('from_group_id')) || '',
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at')),
      likeCount: resultSet.getLong(resultSet.getColumnIndex('like_count')),
      commentCount: resultSet.getLong(resultSet.getColumnIndex('comment_count')),
      bookmarkCount: resultSet.getLong(resultSet.getColumnIndex('bookmark_count')),
      isApproved: resultSet.getLong(resultSet.getColumnIndex('is_approved')) === 1,
      isDraft: resultSet.getLong(resultSet.getColumnIndex('is_draft')) === 1
    };
  }

  private async queryRecipes(
    predicates: relationalStore.RdbPredicates,
    offset: number, limit: number
  ): Promise<Recipe[]> {
    if (!this.rdbStore) return [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const recipes: Recipe[] = [];
      let currentIndex = 0;
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
        resultSet.close();
      }
    }
  }
}
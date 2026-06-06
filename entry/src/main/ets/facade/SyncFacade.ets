import {
  GroupSummary, GroupFeed, FeedType, Recipe, RecipeQueryParams,
  RecipeComment, CreateRecipeParams, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { ServiceManager } from '../ServiceManager';
import { SyncService, SyncEvent } from 'hsp_service';
import { FamilyGroupService, CreateGroupParams } from 'feature_community';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SyncFacade';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

/**
 * 同步与社区业务门面
 *
 * 统一封装家庭群组管理、动态发布、扫码分享、
 * 食谱社区（创建/查询/评论/点赞/收藏）等操作，
 * 对UI层提供简洁的API入口。
 *
 * @since 1.0.0
 */
export class SyncFacade {
  private readonly services: ServiceManager;

  constructor(services: ServiceManager) {
    this.services = services;
  }

  onSyncEvent(callback: (event: SyncEvent) => void): void {
    this.services.onSyncEvent(callback);
  }

  /**
   * 获取我的家庭群组列表
   *
   * @returns 群组摘要列表，服务未初始化返回空数组
   */
  async getMyGroups(): Promise<GroupSummary[]> {
    if (!this.services.groupService) return [];
    return this.services.groupService.getMyGroups();
  }

  /**
   * 创建家庭群组
   *
   * @param name - 群组名称
   * @returns 群组摘要
   * @throws Error 群组服务未初始化时抛出
   */
  async createFamilyGroup(name: string): Promise<GroupSummary> {
    if (!this.services.groupService) {
      throw new Error('Group service not initialized');
    }
    const params: CreateGroupParams = new CreateGroupParams()
    params.groupName = name;
    params.description = '';
    params.ownerName = '';
    return this.services.groupService.createGroup(params);
  }

  async getOrCreateGroupSummary(): Promise<GroupSummary | null> {
    if (!this.services.groupService) return null;
    const groups = await this.services.groupService.getMyGroups();
    return groups.length > 0 ? groups[0] : null;
  }

  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    if (!this.services.groupService) return [];
    return this.services.groupService.getGroupFeeds(groupId, offset, limit);
  }

  async postFeed(groupId: string, content: string, feedType: FeedType, mediaUri?: string): Promise<void> {
    if (!this.services.groupService) throw new Error('Group service not initialized');
    await this.services.groupService.postFeed(groupId, content, feedType, mediaUri);
  }

  async joinFamilyGroup(code: string): Promise<GroupSummary> {
    if (!this.services.groupService) throw new Error('Group service not initialized');
    return this.services.groupService.joinGroupByCode(code, 'Family Member');
  }

  /**
   * 分享扫码结果到群组
   *
   * @param groupId - 群组ID
   * @param foodName - 食品名称
   * @param foodId - 食品ID
   * @param nutriScore - NutriScore评分
   * @param summary - 摘要文本
   * @param memberResults - 成员评估结果文本
   * @returns Promise<void>
   */
  async shareFoodScanToGroup(
    groupId: string, foodName: string, foodId: string,
    nutriScore: number, summary: string, memberResults: string
  ): Promise<void> {
    if (!this.services.groupService) return;
    await this.services.groupService.shareFoodScan(groupId, foodName, foodId, nutriScore, summary, memberResults);
  }

  async createRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    if (!this.services.recipeCommunityService) return null;
    return this.services.recipeCommunityService.createRecipe(params);
  }

  async getRecipeRecommendations(params: RecipeQueryParams): Promise<Recipe[]> {
    if (!this.services.recipeCommunityService) return [];
    return this.services.recipeCommunityService.queryRecipes(params);
  }

  async queryCommunityRecipes(params: RecipeQueryParams): Promise<Recipe[]> {
    if (!this.services.recipeCommunityService) return [];
    return this.services.recipeCommunityService.queryRecipes(params);
  }

  async getRecipeDetail(recipeId: string): Promise<Recipe | null> {
    if (!this.services.recipeCommunityService) return null;
    return this.services.recipeCommunityService.getRecipeDetail(recipeId);
  }

  async getRecipeComments(recipeId: string): Promise<RecipeComment[]> {
    if (!this.services.recipeCommunityService) return [];
    return this.services.recipeCommunityService.getComments(recipeId);
  }

  async hasLikedRecipe(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return this.services.recipeCommunityService.hasLiked(recipeId);
  }

  async toggleRecipeLike(recipeId: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return this.services.recipeCommunityService.toggleLike(recipeId);
  }

  async toggleRecipeBookmark(recipeId: string, _notes: string): Promise<boolean> {
    if (!this.services.recipeCommunityService) return false;
    return this.services.recipeCommunityService.toggleBookmark(recipeId, _notes);
  }

  async addRecipeComment(recipeId: string, text: string, _authorName: string): Promise<RecipeComment | null> {
    if (!this.services.recipeCommunityService) return null;
    return this.services.recipeCommunityService.addComment(recipeId, text, _authorName);
  }

  async publishRecipe(params: CreateRecipeParams): Promise<Recipe | null> {
    return this.createRecipe(params);
  }
}

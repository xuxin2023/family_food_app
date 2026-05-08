// GroupDomainService.ets
// 群组领域服务 - �?AppState 剥离的群组相关业务逻辑

import { GroupSummary, GroupFeed, FeedType } from '../model/FamilyGroup';
import { FamilyGroupService } from '../service/FamilyGroupService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'GroupDomainService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class GroupDomainService {
  private groupService_: FamilyGroupService | null = null;

  constructor(groupService: FamilyGroupService | null) {
    this.groupService_ = groupService;
  }

  private get gs(): FamilyGroupService | null { return this.groupService_; }

  async getMyGroups(): Promise<GroupSummary[]> {
    if (!this.gs) return [];
    return this.gs.getMyGroups();
  }

  async createFamilyGroup(name: string): Promise<GroupSummary> {
    if (!this.gs) {
      throw new Error('Group service not initialized');
    }
    return this.gs.createGroup({ groupName: name, description: '', ownerName: '' });
  }

  async getOrCreateGroupSummary(): Promise<GroupSummary | null> {
    if (!this.gs) {
      return null;
    }
    const groups = await this.gs.getMyGroups();
    return groups.length > 0 ? groups[0] : null;
  }

  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    if (!this.gs) return [];
    return this.gs.getGroupFeeds(groupId, offset, limit);
  }

  async postFeed(groupId: string, content: string, feedType: FeedType, mediaUri?: string): Promise<void> {
    if (!this.gs) {
      hilog.warn(DOMAIN_ZERO, TAG, 'postFeed: groupService not initialized');
      return;
    }
    await this.gs.shareFoodScan(groupId, content, '', 0, mediaUri || '', '');
    hilog.info(DOMAIN_ZERO, TAG, 'postFeed success for group: %{public}s', groupId);
  }

  async joinFamilyGroup(code: string): Promise<GroupSummary> {
    if (!this.gs) throw new Error('Group service not initialized');
    return this.gs.joinGroupByCode(code, 'Family Member');
  }

  async shareFoodScanToGroup(
    groupId: string, foodName: string, foodId: string,
    nutriScore: number, summary: string, memberResults: string
  ): Promise<void> {
    if (!this.gs) return;
    await this.gs.shareFoodScan(groupId, foodName, foodId, nutriScore, summary, memberResults);
  }
}

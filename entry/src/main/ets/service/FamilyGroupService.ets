// FamilyGroupService.ets
// 家庭群组服务 - 创建、加入、成员管理、群组动态

import { hilog } from '@kit.PerformanceAnalysisKit';
import { FamilyGroupRepository } from '../repository/FamilyGroupRepository';
import {
  FamilyGroup, GroupMember, JoinRequest, GroupFeed,
  GroupRole, JoinMethod, JoinRequestStatus, FeedType,
  FoodScanFeedContent
} from '../model/FamilyGroup';
import { AuthService } from './AuthService';
import { FamilyProfile } from '../model/FamilyProfile';
import { GROUP_CONFIG } from '../constants/AppConfig';

const TAG = 'FamilyGroupService';
const DOMAIN_ZERO = 0;

/** 邀请码字符集 */
const INVITE_CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const INVITE_CODE_LENGTH = GROUP_CONFIG.INVITE_CODE_LENGTH;

/** 免费版群组创建限制 */
const FREE_GROUP_LIMIT = GROUP_CONFIG.FREE_GROUP_LIMIT;
const FREE_MEMBER_LIMIT = GROUP_CONFIG.FREE_GROUP_MEMBER_LIMIT;

export interface CreateGroupParams {
  groupName: string;
  description: string;
  ownerName: string;
}

export interface GroupSummary {
  group: FamilyGroup;
  members: GroupMember[];
  myRole: GroupRole;
}

export class FamilyGroupService {
  private groupRepo: FamilyGroupRepository;
  private authService: AuthService;

  constructor(groupRepo: FamilyGroupRepository, authService: AuthService) {
    this.groupRepo = groupRepo;
    this.authService = authService;
  }

  // ========== 群组创建与管理 ==========

  /**
   * 创建家庭群组
   */
  async createGroup(params: CreateGroupParams): Promise<GroupSummary> {
    const uid = this.authService.getUid();
    if (uid.length === 0) {
      throw new Error('请先登录后再创建家庭群组');
    }

    const groupId = `group_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const inviteCode = this.generateInviteCode();
    const now = Date.now();

    const group: FamilyGroup = {
      groupId: groupId,
      groupName: params.groupName,
      groupAvatar: '',
      description: params.description,
      ownerUid: uid,
      ownerName: params.ownerName,
      inviteCode: inviteCode,
      maxMembers: FREE_MEMBER_LIMIT,
      memberCount: 1,
      createdAt: now,
      updatedAt: now,
      isArchived: false
    };

    // 保存群组
    await this.groupRepo.saveGroup(group);

    // 添加创建者为群主
    const ownerMember: GroupMember = {
      id: `gm_${groupId}_${uid}`,
      groupId: groupId,
      uid: uid,
      displayName: params.ownerName,
      role: GroupRole.OWNER,
      joinMethod: JoinMethod.MANUAL,
      joinedAt: now,
      lastActiveAt: now,
      isLeft: false,
      localMemberId: ''
    };
    await this.groupRepo.addMember(ownerMember);

    hilog.info(DOMAIN_ZERO, TAG, 'Group created: %{public}s', groupId);

    return {
      group: group,
      members: [ownerMember],
      myRole: GroupRole.OWNER
    };
  }

  /**
   * 通过邀请码加入群组
   */
  async joinGroupByCode(inviteCode: string, displayName: string): Promise<GroupSummary> {
    const uid = this.authService.getUid();
    if (uid.length === 0) {
      throw new Error('请先登录后再加入家庭群组');
    }

    const group = await this.groupRepo.getGroupByInviteCode(inviteCode);
    if (!group) {
      throw new Error('邀请码无效，请检查后重新输入');
    }

    if (group.isArchived) {
      throw new Error('该群组已归档，无法加入');
    }

    // 检查是否已是成员
    const existingMember = await this.groupRepo.getMemberInGroup(group.groupId, uid);
    if (existingMember) {
      throw new Error('您已是该群组的成员');
    }

    // 检查成员上限
    if (group.memberCount >= group.maxMembers) {
      throw new Error('群组成员已满，请联系群主升级');
    }

    const now = Date.now();
    const member: GroupMember = {
      id: `gm_${group.groupId}_${uid}`,
      groupId: group.groupId,
      uid: uid,
      displayName: displayName,
      role: GroupRole.MEMBER,
      joinMethod: JoinMethod.LINK,
      joinedAt: now,
      lastActiveAt: now,
      isLeft: false,
      localMemberId: ''
    };

    await this.groupRepo.addMember(member);
    await this.groupRepo.updateGroup(group.groupId, {
      memberCount: group.memberCount + 1
    });

    // 发送系统动态
    await this.addSystemFeed(group.groupId, uid, displayName, `${displayName} 加入了群组`);

    const members = await this.groupRepo.getGroupMembers(group.groupId);

    hilog.info(DOMAIN_ZERO, TAG, 'User %{public}s joined group %{public}s', uid, group.groupId);

    return {
      group: {
        groupId: group.groupId,
        groupName: group.groupName,
        groupAvatar: group.groupAvatar,
        description: group.description,
        ownerUid: group.ownerUid,
        ownerName: group.ownerName,
        inviteCode: group.inviteCode,
        maxMembers: group.maxMembers,
        memberCount: group.memberCount + 1,
        createdAt: group.createdAt,
        updatedAt: Date.now(),
        isArchived: group.isArchived
      },
      members: members,
      myRole: GroupRole.MEMBER
    };
  }

  /**
   * 获取用户加入的群组列表（含成员信息）
   */
  async getMyGroups(): Promise<GroupSummary[]> {
    const uid = this.authService.getUid();
    if (uid.length === 0) return [];

    const myMemberships = await this.groupRepo.getMemberGroups(uid);
    const summaries: GroupSummary[] = [];

    for (const membership of myMemberships) {
      const group = await this.groupRepo.getGroup(membership.groupId);
      if (group && !group.isArchived) {
        const members = await this.groupRepo.getGroupMembers(group.groupId);
        summaries.push({
          group: group,
          members: members,
          myRole: membership.role
        });
      }
    }

    return summaries;
  }

  /**
   * 获取群组详情
   */
  async getGroupDetail(groupId: string): Promise<GroupSummary | null> {
    const uid = this.authService.getUid();
    const group = await this.groupRepo.getGroup(groupId);
    if (!group) return null;

    const members = await this.groupRepo.getGroupMembers(groupId);
    const myMembership = await this.groupRepo.getMemberInGroup(groupId, uid);

    return {
      group: group,
      members: members,
      myRole: myMembership?.role || GroupRole.MEMBER
    };
  }

  /**
   * 离开群组
   */
  async leaveGroup(groupId: string): Promise<void> {
    const uid = this.authService.getUid();
    const group = await this.groupRepo.getGroup(groupId);
    if (!group) throw new Error('群组不存在');

    if (group.ownerUid === uid) {
      throw new Error('群主不能离开群组，请先转让群主或删除群组');
    }

    await this.groupRepo.removeMember(groupId, uid);
    await this.groupRepo.updateGroup(groupId, {
      memberCount: Math.max(0, group.memberCount - 1)
    });
  }

  /**
   * 删除群组（仅群主）
   */
  async deleteGroup(groupId: string): Promise<void> {
    const uid = this.authService.getUid();
    const group = await this.groupRepo.getGroup(groupId);
    if (!group) throw new Error('群组不存在');
    if (group.ownerUid !== uid) throw new Error('仅群主可以删除群组');

    await this.groupRepo.updateGroup(groupId, { isArchived: true });
  }

  // ========== 成员管理 ==========

  /**
   * 移除成员（群主/管理员）
   */
  async removeMember(groupId: string, targetUid: string): Promise<void> {
    const uid = this.authService.getUid();
    const myMembership = await this.groupRepo.getMemberInGroup(groupId, uid);
    if (!myMembership || (myMembership.role !== GroupRole.OWNER && myMembership.role !== GroupRole.ADMIN)) {
      throw new Error('没有权限移除成员');
    }

    const group = await this.groupRepo.getGroup(groupId);
    if (!group) throw new Error('群组不存在');

    await this.groupRepo.removeMember(groupId, targetUid);
    await this.groupRepo.updateGroup(groupId, {
      memberCount: Math.max(0, group.memberCount - 1)
    });
  }

  /**
   * 设置管理员（仅群主）
   */
  async setAdmin(groupId: string, targetUid: string): Promise<void> {
    const uid = this.authService.getUid();
    const group = await this.groupRepo.getGroup(groupId);
    if (!group) throw new Error('群组不存在');
    if (group.ownerUid !== uid) throw new Error('仅群主可以设置管理员');

    await this.groupRepo.updateMemberRole(groupId, targetUid, GroupRole.ADMIN);
  }

  /**
   * 取消管理员（仅群主）
   */
  async removeAdmin(groupId: string, targetUid: string): Promise<void> {
    const uid = this.authService.getUid();
    const group = await this.groupRepo.getGroup(groupId);
    if (!group) throw new Error('群组不存在');
    if (group.ownerUid !== uid) throw new Error('仅群主可以取消管理员');

    await this.groupRepo.updateMemberRole(groupId, targetUid, GroupRole.MEMBER);
  }

  // ========== 群组动态 ==========

  /**
   * 添加食品扫描分享到群组动态
   */
  async shareFoodScan(
    groupId: string,
    foodName: string,
    foodId: string,
    nutriScore: number,
    summary: string,
    memberResults: string
  ): Promise<void> {
    const uid = this.authService.getUid();
    const member = await this.groupRepo.getMemberInGroup(groupId, uid);
    if (!member) throw new Error('您不是该群组成员');

    const content: FoodScanFeedContent = {
      foodName: foodName,
      foodId: foodId,
      nutriScore: nutriScore,
      summary: summary,
      memberResults: memberResults
    };

    const feed: GroupFeed = {
      feedId: `feed_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`,
      groupId: groupId,
      feedType: FeedType.FOOD_SCAN_SHARE,
      senderUid: uid,
      senderName: member.displayName,
      content: JSON.stringify(content),
      createdAt: Date.now(),
      commentCount: 0,
      likeCount: 0
    };

    await this.groupRepo.saveFeed(feed);
  }

  /**
   * 获取群组动态
   */
  async getGroupFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    return await this.groupRepo.getFeeds(groupId, offset, limit);
  }

  /**
   * 删除动态（仅发送者或群主/管理员）
   */
  async deleteFeed(feedId: string): Promise<void> {
    const uid = this.authService.getUid();
    // TODO: 权限检查需要查询feed的所属群组和角色
    await this.groupRepo.deleteFeed(feedId);
  }

  // ========== 获取群组的邀请码 ==========

  async getInviteCode(groupId: string): Promise<string> {
    const group = await this.groupRepo.getGroup(groupId);
    if (!group) throw new Error('群组不存在');
    return group.inviteCode;
  }

  // ========== 内部方法 ==========

  private generateInviteCode(): string {
    let code = '';
    for (let i = 0; i < INVITE_CODE_LENGTH; i++) {
      code += INVITE_CODE_CHARS.charAt(Math.floor(Math.random() * INVITE_CODE_CHARS.length));
    }
    return code;
  }

  private async addSystemFeed(
    groupId: string, senderUid: string, senderName: string, message: string
  ): Promise<void> {
    const feed: GroupFeed = {
      feedId: `feed_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`,
      groupId: groupId,
      feedType: FeedType.SYSTEM,
      senderUid: senderUid,
      senderName: senderName,
      content: message,
      createdAt: Date.now(),
      commentCount: 0,
      likeCount: 0
    };
    await this.groupRepo.saveFeed(feed);
  }
}

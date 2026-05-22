// FamilyGroupRepository.ets
// 家庭群组数据仓库 - RdbStore (SQLite)

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  FamilyGroup, GroupMember, JoinRequest, GroupFeed, GroupSummary, GroupRole, JoinMethod, JoinRequestStatus, FeedType, HILOG_DOMAIN
} from 'hsp_core';


const TAG = 'FamilyGroupRepository';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface CreateGroupParams {
  name: string;
}

/** 群组表名 */
const TABLE_GROUP = 'family_group';
/** 群组成员表名 */
const TABLE_GROUP_MEMBER = 'group_member';
/** 加群申请表名 */
const TABLE_JOIN_REQUEST = 'join_request';
/** 群组动态表名 */
const TABLE_GROUP_FEED = 'group_feed';

export class FamilyGroupRepository {
  private rdbStore: relationalStore.RdbStore | null = null;

  init(rdbStore: relationalStore.RdbStore): void {
    this.rdbStore = rdbStore;
  }

  async createTables(): Promise<void> {
    if (!this.rdbStore) return;

    const groupSql = `CREATE TABLE IF NOT EXISTS ${TABLE_GROUP} (
      group_id TEXT PRIMARY KEY,
      group_name TEXT NOT NULL,
      group_avatar TEXT DEFAULT '',
      description TEXT DEFAULT '',
      owner_uid TEXT NOT NULL,
      owner_name TEXT DEFAULT '',
      invite_code TEXT NOT NULL,
      max_members INTEGER DEFAULT 10,
      member_count INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      is_archived INTEGER DEFAULT 0
    )`;
    await this.rdbStore.executeSql(groupSql);

    const memberSql = `CREATE TABLE IF NOT EXISTS ${TABLE_GROUP_MEMBER} (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      uid TEXT NOT NULL,
      display_name TEXT DEFAULT '',
      role TEXT NOT NULL DEFAULT 'member',
      join_method TEXT DEFAULT 'manual',
      joined_at INTEGER NOT NULL,
      last_active_at INTEGER NOT NULL,
      is_left INTEGER DEFAULT 0,
      local_member_id TEXT DEFAULT ''
    )`;
    await this.rdbStore.executeSql(memberSql);

    const requestSql = `CREATE TABLE IF NOT EXISTS ${TABLE_JOIN_REQUEST} (
      request_id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      requester_uid TEXT NOT NULL,
      requester_name TEXT DEFAULT '',
      message TEXT DEFAULT '',
      status TEXT DEFAULT 'pending',
      requested_at INTEGER NOT NULL,
      reviewed_at INTEGER DEFAULT 0,
      reviewer_uid TEXT DEFAULT ''
    )`;
    await this.rdbStore.executeSql(requestSql);

    const feedSql = `CREATE TABLE IF NOT EXISTS ${TABLE_GROUP_FEED} (
      feed_id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      feed_type TEXT NOT NULL,
      sender_uid TEXT NOT NULL,
      sender_name TEXT DEFAULT '',
      content TEXT DEFAULT '',
      created_at INTEGER NOT NULL,
      comment_count INTEGER DEFAULT 0,
      like_count INTEGER DEFAULT 0
    )`;
    await this.rdbStore.executeSql(feedSql);

    // 创建索引
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_member_group ON ${TABLE_GROUP_MEMBER} (group_id, uid)`
    );
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_feed_group ON ${TABLE_GROUP_FEED} (group_id, created_at)`
    );
    await this.rdbStore.executeSql(
      `CREATE INDEX IF NOT EXISTS idx_request_group ON ${TABLE_JOIN_REQUEST} (group_id, status)`
    );

    hilog.info(DOMAIN_ZERO, TAG, 'Group tables created');
  }

  // ========== 群组 CRUD ==========

  async saveGroup(group: FamilyGroup): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = {
      group_id: group.groupId,
      group_name: group.groupName,
      group_avatar: group.groupAvatar,
      description: group.description,
      owner_uid: group.ownerUid,
      owner_name: group.ownerName,
      invite_code: group.inviteCode,
      max_members: group.maxMembers,
      member_count: group.memberCount,
      created_at: group.createdAt,
      updated_at: group.updatedAt,
      is_archived: group.isArchived ? 1 : 0
    };
    await this.rdbStore.insert(TABLE_GROUP, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async getGroup(groupId: string): Promise<FamilyGroup | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
    predicates.equalTo('group_id', groupId);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        return this.parseGroup(resultSet);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getGroup failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  async getGroupByInviteCode(inviteCode: string): Promise<FamilyGroup | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
    predicates.equalTo('invite_code', inviteCode);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        return this.parseGroup(resultSet);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getGroupByInviteCode failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  async getOwnedGroups(uid: string): Promise<FamilyGroup[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
    predicates.equalTo('owner_uid', uid);
    predicates.equalTo('is_archived', 0);
    predicates.orderByDesc('updated_at');
    return await this.queryGroups(predicates);
  }

  async updateGroup(groupId: string, updates: Partial<FamilyGroup>): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = {};
    if (updates.groupName !== undefined) bucket['group_name'] = updates.groupName;
    if (updates.description !== undefined) bucket['description'] = updates.description;
    if (updates.groupAvatar !== undefined) bucket['group_avatar'] = updates.groupAvatar;
    if (updates.memberCount !== undefined) bucket['member_count'] = updates.memberCount;
    if (updates.isArchived !== undefined) bucket['is_archived'] = updates.isArchived ? 1 : 0;
    bucket['updated_at'] = Date.now();

    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
    predicates.equalTo('group_id', groupId);
    await this.rdbStore.update(bucket, predicates);
  }

  async deleteGroup(groupId: string): Promise<void> {
    if (!this.rdbStore) return;
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
    predicates.equalTo('group_id', groupId);
    await this.rdbStore.delete(predicates);
  }

  // ========== 群组成员管理 ==========

  async addMember(member: GroupMember): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = {
      id: member.id,
      group_id: member.groupId,
      uid: member.uid,
      display_name: member.displayName,
      role: member.role,
      join_method: member.joinMethod,
      joined_at: member.joinedAt,
      last_active_at: member.lastActiveAt,
      is_left: member.isLeft ? 1 : 0,
      local_member_id: member.localMemberId
    };
    await this.rdbStore.insert(TABLE_GROUP_MEMBER, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async getGroupMembers(groupId: string): Promise<GroupMember[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
    predicates.equalTo('group_id', groupId);
    predicates.equalTo('is_left', 0);
    predicates.orderByAsc('joined_at');
    return await this.queryMembers(predicates);
  }

  async getMemberGroups(uid: string): Promise<GroupMember[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
    predicates.equalTo('uid', uid);
    predicates.equalTo('is_left', 0);
    predicates.orderByDesc('last_active_at');
    return await this.queryMembers(predicates);
  }

  async getMemberInGroup(groupId: string, uid: string): Promise<GroupMember | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
    predicates.equalTo('group_id', groupId);
    predicates.equalTo('uid', uid);
    predicates.equalTo('is_left', 0);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        return this.parseMember(resultSet);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getMemberInGroup failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  async updateMemberRole(groupId: string, uid: string, role: GroupRole): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = { role: role };
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
    predicates.equalTo('group_id', groupId);
    predicates.equalTo('uid', uid);
    await this.rdbStore.update(bucket, predicates);
  }

  async removeMember(groupId: string, uid: string): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = {
      is_left: 1,
      last_active_at: Date.now()
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
    predicates.equalTo('group_id', groupId);
    predicates.equalTo('uid', uid);
    await this.rdbStore.update(bucket, predicates);
  }

  async updateLastActive(groupId: string, uid: string): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = { last_active_at: Date.now() };
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
    predicates.equalTo('group_id', groupId);
    predicates.equalTo('uid', uid);
    await this.rdbStore.update(bucket, predicates);
  }

  // ========== 加群申请 ==========

  async saveJoinRequest(request: JoinRequest): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = {
      request_id: request.requestId,
      group_id: request.groupId,
      requester_uid: request.requesterUid,
      requester_name: request.requesterName,
      message: request.message,
      status: request.status,
      requested_at: request.requestedAt,
      reviewed_at: request.reviewedAt,
      reviewer_uid: request.reviewerUid
    };
    await this.rdbStore.insert(TABLE_JOIN_REQUEST, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async getPendingRequests(groupId: string): Promise<JoinRequest[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_JOIN_REQUEST);
    predicates.equalTo('group_id', groupId);
    predicates.equalTo('status', JoinRequestStatus.PENDING);
    predicates.orderByDesc('requested_at');
    return await this.queryRequests(predicates);
  }

  async updateRequestStatus(requestId: string, status: JoinRequestStatus, reviewerUid: string): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = {
      status: status,
      reviewed_at: Date.now(),
      reviewer_uid: reviewerUid
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_JOIN_REQUEST);
    predicates.equalTo('request_id', requestId);
    await this.rdbStore.update(bucket, predicates);
  }

  // ========== 群组动态 ==========

  async saveFeed(feed: GroupFeed): Promise<void> {
    if (!this.rdbStore) return;
    const bucket: relationalStore.ValuesBucket = {
      feed_id: feed.feedId,
      group_id: feed.groupId,
      feed_type: feed.feedType,
      sender_uid: feed.senderUid,
      sender_name: feed.senderName,
      content: feed.content,
      created_at: feed.createdAt,
      comment_count: feed.commentCount,
      like_count: feed.likeCount
    };
    await this.rdbStore.insert(TABLE_GROUP_FEED, bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
  }

  async getFeeds(groupId: string, offset: number, limit: number): Promise<GroupFeed[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_FEED);
    predicates.equalTo('group_id', groupId);
    predicates.orderByDesc('created_at');
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const feeds: GroupFeed[] = [];
      let currentIndex = 0;
      while (resultSet.goToNextRow()) {
        if (currentIndex >= offset && feeds.length < limit) {
          feeds.push(this.parseFeed(resultSet));
        }
        currentIndex++;
      }
      return feeds;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getFeeds failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  async deleteFeed(feedId: string): Promise<void> {
    if (!this.rdbStore) return;
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_FEED);
    predicates.equalTo('feed_id', feedId);
    await this.rdbStore.delete(predicates);
  }

  // ========== 便捷方法（供 AppState 使用） ==========

  async getMyGroups(): Promise<GroupSummary[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
    predicates.equalTo('is_archived', 0);
    predicates.orderByDesc('updated_at');
    const groups = await this.queryGroups(predicates);
    const results: GroupSummary[] = [];
    for (const g of groups) {
      const s = new GroupSummary();
      s.groupId = g.groupId;
      s.groupName = g.groupName;
      s.memberCount = g.memberCount;
      s.inviteCode = g.inviteCode;
      results.push(s);
    }
    return results;
  }

  async createGroup(params: CreateGroupParams): Promise<GroupSummary> {
    const id = 'g_' + Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
    const code = 'INV_' + Math.random().toString(36).substring(2, 10).toUpperCase();
    const group = new FamilyGroup();
    group.groupId = id;
    group.groupName = params.name;
    group.inviteCode = code;
    group.ownerUid = 'self';
    group.createdAt = Date.now();
    group.updatedAt = Date.now();
    group.memberCount = 1;
    group.maxMembers = 20;
    await this.saveGroup(group);
    const s = new GroupSummary();
    s.groupId = id;
    s.groupName = params.name;
    s.memberCount = 1;
    s.inviteCode = code;
    return s;
  }

  async joinGroup(code: string): Promise<GroupSummary> {
    const group = await this.getGroupByInviteCode(code);
    if (!group) throw new Error('群组不存在或邀请码无效');
    group.memberCount++;
    group.updatedAt = Date.now();
    await this.updateGroup(group.groupId, { memberCount: group.memberCount });
    const s = new GroupSummary();
    s.groupId = group.groupId;
    s.groupName = group.groupName;
    s.memberCount = group.memberCount;
    s.inviteCode = group.inviteCode;
    return s;
  }

  /**
   * 保存动态（简化版 — 兼容 AppState postFeed/saveFeed）
   */
  async saveFeedSimple(groupId: string, feed: GroupFeed): Promise<void> {
    if (!this.rdbStore) return;
    const f = new GroupFeed();
    f.feedId = 'fd_' + Date.now().toString(36) + Math.random().toString(36).substring(2, 8);
    f.groupId = groupId;
    f.feedType = feed.feedType || FeedType.TEXT;
    f.senderUid = feed.senderUid || 'self';
    f.senderName = feed.senderName || '我';
    f.content = feed.content || '';
    f.createdAt = Date.now();
    await this.saveFeed(f);
  }

  /**
   * 根据 feedId 查询单条动态
   */
  async getFeedById(feedId: string): Promise<GroupFeed | null> {
    if (!this.rdbStore) return null;
    const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_FEED);
    predicates.equalTo('feed_id', feedId);
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToFirstRow()) {
        return this.parseFeed(resultSet);
      }
      return null;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'getFeedById failed: %{public}s', JSON.stringify(error));
      return null;
    } finally {
      if (resultSet) { try { resultSet.close(); } catch (closeError) { /* safe */ } }
    }
  }

  // ========== 内部解析方法 ==========

  private parseGroup(resultSet: relationalStore.ResultSet): FamilyGroup {
    const g = new FamilyGroup();
    g.groupId = resultSet.getString(resultSet.getColumnIndex('group_id'));
    g.groupName = resultSet.getString(resultSet.getColumnIndex('group_name'));
    g.groupAvatar = resultSet.getString(resultSet.getColumnIndex('group_avatar')) || '';
    g.description = resultSet.getString(resultSet.getColumnIndex('description')) || '';
    g.ownerUid = resultSet.getString(resultSet.getColumnIndex('owner_uid'));
    g.ownerName = resultSet.getString(resultSet.getColumnIndex('owner_name')) || '';
    g.inviteCode = resultSet.getString(resultSet.getColumnIndex('invite_code'));
    g.maxMembers = resultSet.getLong(resultSet.getColumnIndex('max_members'));
    g.memberCount = resultSet.getLong(resultSet.getColumnIndex('member_count'));
    g.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    g.updatedAt = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    g.isArchived = resultSet.getLong(resultSet.getColumnIndex('is_archived')) === 1;
    return g;
  }

  private async queryGroups(predicates: relationalStore.RdbPredicates): Promise<FamilyGroup[]> {
    if (!this.rdbStore) return [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const groups: FamilyGroup[] = [];
      while (resultSet.goToNextRow()) {
        groups.push(this.parseGroup(resultSet));
      }
      return groups;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'queryGroups failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  private parseMember(resultSet: relationalStore.ResultSet): GroupMember {
    return {
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      groupId: resultSet.getString(resultSet.getColumnIndex('group_id')),
      uid: resultSet.getString(resultSet.getColumnIndex('uid')),
      displayName: resultSet.getString(resultSet.getColumnIndex('display_name')) || '',
      role: resultSet.getString(resultSet.getColumnIndex('role')) as GroupRole,
      joinMethod: resultSet.getString(resultSet.getColumnIndex('join_method')) as JoinMethod,
      joinedAt: resultSet.getLong(resultSet.getColumnIndex('joined_at')),
      lastActiveAt: resultSet.getLong(resultSet.getColumnIndex('last_active_at')),
      isLeft: resultSet.getLong(resultSet.getColumnIndex('is_left')) === 1,
      localMemberId: resultSet.getString(resultSet.getColumnIndex('local_member_id')) || ''
    };
  }

  private async queryMembers(predicates: relationalStore.RdbPredicates): Promise<GroupMember[]> {
    if (!this.rdbStore) return [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const members: GroupMember[] = [];
      while (resultSet.goToNextRow()) {
        members.push(this.parseMember(resultSet));
      }
      return members;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'queryMembers failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  private parseRequest(resultSet: relationalStore.ResultSet): JoinRequest {
    return {
      requestId: resultSet.getString(resultSet.getColumnIndex('request_id')),
      groupId: resultSet.getString(resultSet.getColumnIndex('group_id')),
      requesterUid: resultSet.getString(resultSet.getColumnIndex('requester_uid')),
      requesterName: resultSet.getString(resultSet.getColumnIndex('requester_name')) || '',
      message: resultSet.getString(resultSet.getColumnIndex('message')) || '',
      status: resultSet.getString(resultSet.getColumnIndex('status')) as JoinRequestStatus,
      requestedAt: resultSet.getLong(resultSet.getColumnIndex('requested_at')),
      reviewedAt: resultSet.getLong(resultSet.getColumnIndex('reviewed_at')),
      reviewerUid: resultSet.getString(resultSet.getColumnIndex('reviewer_uid')) || ''
    };
  }

  private async queryRequests(predicates: relationalStore.RdbPredicates): Promise<JoinRequest[]> {
    if (!this.rdbStore) return [];
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      resultSet = await this.rdbStore.query(predicates);
      const requests: JoinRequest[] = [];
      while (resultSet.goToNextRow()) {
        requests.push(this.parseRequest(resultSet));
      }
      return requests;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'queryRequests failed: %{public}s', JSON.stringify(error));
      return [];
    } finally {
      if (resultSet) {
        try { resultSet.close(); } catch (closeError) { /* safe */ }
      }
    }
  }

  private parseFeed(resultSet: relationalStore.ResultSet): GroupFeed {
    const feed = new GroupFeed();
    feed.feedId = resultSet.getString(resultSet.getColumnIndex('feed_id'));
    feed.groupId = resultSet.getString(resultSet.getColumnIndex('group_id'));
    feed.feedType = resultSet.getString(resultSet.getColumnIndex('feed_type')) as FeedType;
    feed.senderUid = resultSet.getString(resultSet.getColumnIndex('sender_uid'));
    feed.senderName = resultSet.getString(resultSet.getColumnIndex('sender_name')) || '';
    feed.content = resultSet.getString(resultSet.getColumnIndex('content')) || '';
    feed.createdAt = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    feed.commentCount = resultSet.getLong(resultSet.getColumnIndex('comment_count'));
    feed.likeCount = resultSet.getLong(resultSet.getColumnIndex('like_count'));
    return feed;
  }
}
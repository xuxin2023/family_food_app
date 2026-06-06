// FamilyGroupRepository.ets
// 家庭群组数据仓库 - RdbStore (SQLite)

import { relationalStore } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  FamilyGroup, GroupMember, JoinRequest, GroupFeed, GroupSummary, GroupRole, JoinMethod, JoinRequestStatus, FeedType, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';


const TAG = 'FamilyGroupRepository';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

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
    try {
      if (!this.rdbStore) return;

      const groupDef = [
        'group_id TEXT PRIMARY KEY',
        'group_name TEXT NOT NULL',
        'group_avatar TEXT DEFAULT \'\'',
        'description TEXT DEFAULT \'\'',
        'owner_uid TEXT NOT NULL',
        'owner_name TEXT DEFAULT \'\'',
        'invite_code TEXT NOT NULL',
        'max_members INTEGER DEFAULT 10',
        'member_count INTEGER DEFAULT 0',
        'created_at INTEGER NOT NULL',
        'updated_at INTEGER NOT NULL',
        'is_archived INTEGER DEFAULT 0'
      ].join(', ');
      await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_GROUP} (${groupDef})`);

      const memberDef = [
        'id TEXT PRIMARY KEY',
        'group_id TEXT NOT NULL',
        'uid TEXT NOT NULL',
        'display_name TEXT DEFAULT \'\'',
        'role TEXT NOT NULL DEFAULT \'member\'',
        'join_method TEXT DEFAULT \'manual\'',
        'joined_at INTEGER NOT NULL',
        'last_active_at INTEGER NOT NULL',
        'is_left INTEGER DEFAULT 0',
        'local_member_id TEXT DEFAULT \'\''
      ].join(', ');
      await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_GROUP_MEMBER} (${memberDef})`);

      const requestDef = [
        'request_id TEXT PRIMARY KEY',
        'group_id TEXT NOT NULL',
        'requester_uid TEXT NOT NULL',
        'requester_name TEXT DEFAULT \'\'',
        'message TEXT DEFAULT \'\'',
        'status TEXT DEFAULT \'pending\'',
        'requested_at INTEGER NOT NULL',
        'reviewed_at INTEGER DEFAULT 0',
        'reviewer_uid TEXT DEFAULT \'\''
      ].join(', ');
      await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_JOIN_REQUEST} (${requestDef})`);

      const feedDef = [
        'feed_id TEXT PRIMARY KEY',
        'group_id TEXT NOT NULL',
        'feed_type TEXT NOT NULL',
        'sender_uid TEXT NOT NULL',
        'sender_name TEXT DEFAULT \'\'',
        'content TEXT DEFAULT \'\'',
        'created_at INTEGER NOT NULL',
        'comment_count INTEGER DEFAULT 0',
        'like_count INTEGER DEFAULT 0'
      ].join(', ');
      await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${TABLE_GROUP_FEED} (${feedDef})`);

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
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'createTables failed: %{public}s', JSON.stringify(e));
      return;
    }
  }

  // ========== 群组 CRUD ==========

  async saveGroup(group: FamilyGroup): Promise<void> {
    try {
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
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveGroup failed: %{public}s', JSON.stringify(e));
      return;
    }
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

  async updateGroup(groupId: string, updates: Record<string, Object>): Promise<void> {
    try {
      if (!this.rdbStore) return;
      const bucket: relationalStore.ValuesBucket = {};
      if (updates['groupName'] !== undefined) bucket['group_name'] = updates['groupName'] as relationalStore.ValueType;
      if (updates['description'] !== undefined) bucket['description'] = updates['description'] as relationalStore.ValueType;
      if (updates['groupAvatar'] !== undefined) bucket['group_avatar'] = updates['groupAvatar'] as relationalStore.ValueType;
      if (updates['memberCount'] !== undefined) bucket['member_count'] = updates['memberCount'] as relationalStore.ValueType;
      if (updates['isArchived'] !== undefined) bucket['is_archived'] = (updates['isArchived'] as boolean) ? 1 : 0;
      bucket['updated_at'] = Date.now();

      const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
      predicates.equalTo('group_id', groupId);
      await this.rdbStore.update(bucket, predicates);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'updateGroup failed: %{public}s', JSON.stringify(e));
      return;
    }
  }

  async deleteGroup(groupId: string): Promise<void> {
    try {
      if (!this.rdbStore) return;
      const predicates = new relationalStore.RdbPredicates(TABLE_GROUP);
      predicates.equalTo('group_id', groupId);
      await this.rdbStore.delete(predicates);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'deleteGroup failed: %{public}s', JSON.stringify(e));
      return;
    }
  }

  // ========== 群组成员管理 ==========

  async addMember(member: GroupMember): Promise<void> {
    try {
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
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'addMember failed: %{public}s', JSON.stringify(e));
      return;
    }
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
    try {
      if (!this.rdbStore) return;
      const bucket: relationalStore.ValuesBucket = { role: role };
      const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
      predicates.equalTo('group_id', groupId);
      predicates.equalTo('uid', uid);
      await this.rdbStore.update(bucket, predicates);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'updateMemberRole failed: %{public}s', JSON.stringify(e));
      return;
    }
  }

  async removeMember(groupId: string, uid: string): Promise<void> {
    try {
      if (!this.rdbStore) return;
      const bucket: relationalStore.ValuesBucket = {
        is_left: 1,
        last_active_at: Date.now()
      };
      const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
      predicates.equalTo('group_id', groupId);
      predicates.equalTo('uid', uid);
      await this.rdbStore.update(bucket, predicates);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'removeMember failed: %{public}s', JSON.stringify(e));
      return;
    }
  }

  async updateLastActive(groupId: string, uid: string): Promise<void> {
    try {
      if (!this.rdbStore) return;
      const bucket: relationalStore.ValuesBucket = { last_active_at: Date.now() };
      const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_MEMBER);
      predicates.equalTo('group_id', groupId);
      predicates.equalTo('uid', uid);
      await this.rdbStore.update(bucket, predicates);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'updateLastActive failed: %{public}s', JSON.stringify(e));
      return;
    }
  }

  // ========== 加群申请 ==========

  async saveJoinRequest(request: JoinRequest): Promise<void> {
    try {
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
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveJoinRequest failed: %{public}s', JSON.stringify(e));
      return;
    }
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
    try {
      if (!this.rdbStore) return;
      const bucket: relationalStore.ValuesBucket = {
        status: status,
        reviewed_at: Date.now(),
        reviewer_uid: reviewerUid
      };
      const predicates = new relationalStore.RdbPredicates(TABLE_JOIN_REQUEST);
      predicates.equalTo('request_id', requestId);
      await this.rdbStore.update(bucket, predicates);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'updateRequestStatus failed: %{public}s', JSON.stringify(e));
      return;
    }
  }

  // ========== 群组动态 ==========

  async saveFeed(feed: GroupFeed): Promise<void> {
    try {
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
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveFeed failed: %{public}s', JSON.stringify(e));
      return;
    }
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
    try {
      if (!this.rdbStore) return;
      const predicates = new relationalStore.RdbPredicates(TABLE_GROUP_FEED);
      predicates.equalTo('feed_id', feedId);
      await this.rdbStore.delete(predicates);
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'deleteFeed failed: %{public}s', JSON.stringify(e));
      return;
    }
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
    try {
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
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'createGroup failed: %{public}s', JSON.stringify(e));
      throw new Error(String(e));
    }
  }

  async joinGroup(code: string): Promise<GroupSummary> {
    try {
      const group = await this.getGroupByInviteCode(code);
      if (!group) throw new Error('群组不存在或邀请码无效');
      group.memberCount++;
      group.updatedAt = Date.now();
      const mcUpdate: Record<string, Object> = { 'memberCount': group.memberCount };
      await this.updateGroup(group.groupId, mcUpdate);
      const s = new GroupSummary();
      s.groupId = group.groupId;
      s.groupName = group.groupName;
      s.memberCount = group.memberCount;
      s.inviteCode = group.inviteCode;
      return s;
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'joinGroup failed: %{public}s', JSON.stringify(e));
      throw new Error(String(e));
    }
  }

  /**
   * 保存动态（简化版 — 兼容 AppState postFeed/saveFeed）
   */
  async saveFeedSimple(groupId: string, feed: GroupFeed): Promise<void> {
    try {
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
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveFeedSimple failed: %{public}s', JSON.stringify(e));
      return;
    }
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

  private safeGetString(rs: relationalStore.ResultSet, col: string): string {
    try { return String(rs.getString(rs.getColumnIndex(col))); } catch (e) { return ''; }
  }
  private safeGetLong(rs: relationalStore.ResultSet, col: string): number {
    try { return Number(rs.getLong(rs.getColumnIndex(col))); } catch (e) { return 0; }
  }
  private safeGetDouble(rs: relationalStore.ResultSet, col: string): number {
    try { return Number(rs.getDouble(rs.getColumnIndex(col))); } catch (e) { return 0; }
  }

  private parseGroup(resultSet: relationalStore.ResultSet): FamilyGroup {
    const g = new FamilyGroup();
    g.groupId = this.safeGetString(resultSet, 'group_id');
    g.groupName = this.safeGetString(resultSet, 'group_name');
    g.groupAvatar = this.safeGetString(resultSet, 'group_avatar');
    g.description = this.safeGetString(resultSet, 'description');
    g.ownerUid = this.safeGetString(resultSet, 'owner_uid');
    g.ownerName = this.safeGetString(resultSet, 'owner_name');
    g.inviteCode = this.safeGetString(resultSet, 'invite_code');
    g.maxMembers = this.safeGetLong(resultSet, 'max_members');
    g.memberCount = this.safeGetLong(resultSet, 'member_count');
    g.createdAt = this.safeGetLong(resultSet, 'created_at');
    g.updatedAt = this.safeGetLong(resultSet, 'updated_at');
    g.isArchived = this.safeGetLong(resultSet, 'is_archived') === 1;
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
    const m = new GroupMember()
    m.id = this.safeGetString(resultSet, 'id')
    m.groupId = this.safeGetString(resultSet, 'group_id')
    m.uid = this.safeGetString(resultSet, 'uid')
    m.displayName = this.safeGetString(resultSet, 'display_name')
    m.role = this.safeGetString(resultSet, 'role') as GroupRole
    m.joinMethod = this.safeGetString(resultSet, 'join_method') as JoinMethod
    m.joinedAt = this.safeGetLong(resultSet, 'joined_at')
    m.lastActiveAt = this.safeGetLong(resultSet, 'last_active_at')
    m.isLeft = this.safeGetLong(resultSet, 'is_left') === 1
    m.localMemberId = this.safeGetString(resultSet, 'local_member_id')
    return m
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
    const r = new JoinRequest()
    r.requestId = this.safeGetString(resultSet, 'request_id')
    r.groupId = this.safeGetString(resultSet, 'group_id')
    r.requesterUid = this.safeGetString(resultSet, 'requester_uid')
    r.requesterName = this.safeGetString(resultSet, 'requester_name')
    r.message = this.safeGetString(resultSet, 'message')
    r.status = this.safeGetString(resultSet, 'status') as JoinRequestStatus
    r.requestedAt = this.safeGetLong(resultSet, 'requested_at')
    r.reviewedAt = this.safeGetLong(resultSet, 'reviewed_at')
    r.reviewerUid = this.safeGetString(resultSet, 'reviewer_uid')
    return r
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
    feed.feedId = this.safeGetString(resultSet, 'feed_id');
    feed.groupId = this.safeGetString(resultSet, 'group_id');
    feed.feedType = this.safeGetString(resultSet, 'feed_type') as FeedType;
    feed.senderUid = this.safeGetString(resultSet, 'sender_uid');
    feed.senderName = this.safeGetString(resultSet, 'sender_name');
    feed.content = this.safeGetString(resultSet, 'content');
    feed.createdAt = this.safeGetLong(resultSet, 'created_at');
    feed.commentCount = this.safeGetLong(resultSet, 'comment_count');
    feed.likeCount = this.safeGetLong(resultSet, 'like_count');
    return feed;
  }
}
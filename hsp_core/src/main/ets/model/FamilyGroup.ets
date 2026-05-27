// FamilyGroup.ets
// 家庭群组数据模型

/** 群组成员角色 */
export enum GroupRole {
  /** 群主/创建者 */
  OWNER = 'owner',
  /** 管理员 */
  ADMIN = 'admin',
  /** 普通成员 */
  MEMBER = 'member'
}

/** 加入方式 */
export enum JoinMethod {
  /** 链接邀请 */
  LINK = 'link',
  /** 扫码加入 */
  QR_CODE = 'qr_code',
  /** 手动添加 */
  MANUAL = 'manual'
}

/** 审核状态 */
export enum JoinRequestStatus {
  /** 待审核 */
  PENDING = 'pending',
  /** 已通过 */
  APPROVED = 'approved',
  /** 已拒绝 */
  REJECTED = 'rejected'
}

/** 动态类型 */
export enum FeedType {
  /** 食谱分享 */
  RECIPE_SHARE = 'recipe_share',
  /** 食物扫描分享 */
  FOOD_SCAN_SHARE = 'food_scan_share',
  /** 周报分享 */
  WEEKLY_REPORT = 'weekly_report',
  /** 系统消息 */
  SYSTEM = 'system',
  /** 纯文本动态 */
  TEXT = 'text',
  /** 食品扫描 */
  FOOD_SCAN = 'food_scan'
}

/** 家庭群组 */
export class FamilyGroup {
  groupId: string = '';
  groupName: string = '';
  groupAvatar: string = '';
  description: string = '';
  ownerUid: string = '';
  ownerName: string = '';
  inviteCode: string = '';
  maxMembers: number = 10;
  memberCount: number = 0;
  createdAt: number = 0;
  updatedAt: number = 0;
  isArchived: boolean = false;
}

/** 群组成员 */
export class GroupMember {
  id: string = '';
  groupId: string = '';
  uid: string = '';
  displayName: string = '';
  role: GroupRole = GroupRole.MEMBER;
  joinMethod: JoinMethod = JoinMethod.MANUAL;
  joinedAt: number = 0;
  lastActiveAt: number = 0;
  isLeft: boolean = false;
  localMemberId: string = '';
}

/** 加群申请 */
export class JoinRequest {
  requestId: string = '';
  groupId: string = '';
  requesterUid: string = '';
  requesterName: string = '';
  message: string = '';
  status: JoinRequestStatus = JoinRequestStatus.PENDING;
  requestedAt: number = 0;
  reviewedAt: number = 0;
  reviewerUid: string = '';
}

/** 群组动态 */
export class GroupFeed {
  feedId: string = '';
  groupId: string = '';
  feedType: FeedType = FeedType.SYSTEM;
  // 兼容别名
  get type(): FeedType { return this.feedType; }
  set type(v: FeedType) { this.feedType = v; }
  senderUid: string = '';
  senderName: string = '';
  content: string = '';
  mediaUri: string = '';
  createdAt: number = 0;
  commentCount: number = 0;
  likeCount: number = 0;
}

/** 群组动态 — 食品扫描分享内容 */
export class FoodScanFeedContent {
  foodName: string = '';
  foodId: string = '';
  nutriScore: number = 0;
  summary: string = '';
  memberResults: string = '';
}

/** 群组动态 — 食谱分享内容 */
export interface RecipeFeedContent {
  recipeId: string;
  recipeName: string;
  imageUrl: string;
  summary: string;
}

/** 群组摘要（供 AppState 列表使用） */
export class GroupSummary {
  groupId: string = '';
  groupName: string = '';
  memberCount: number = 0;
  inviteCode: string = '';
  members: GroupMember[] = [];
  myRole: GroupRole = GroupRole.MEMBER;

  get group(): string { return this.groupName; }
  set group(v: string) { this.groupName = v; }
}

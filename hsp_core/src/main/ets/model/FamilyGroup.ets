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
export interface GroupMember {
  /** 成员记录ID */
  id: string;
  /** 群组ID */
  groupId: string;
  /** 用户UID */
  uid: string;
  /** 在该群组的昵称 */
  displayName: string;
  /** 角色 */
  role: GroupRole;
  /** 加入方式 */
  joinMethod: JoinMethod;
  /** 加入时间戳(ms) */
  joinedAt: number;
  /** 最后活跃时间戳(ms) */
  lastActiveAt: number;
  /** 是否已退出群组 */
  isLeft: boolean;
  /** 本地家庭成员memberId映射（可选，关联本地成员） */
  localMemberId: string;
}

/** 加群申请 */
export interface JoinRequest {
  /** 申请ID */
  requestId: string;
  /** 群组ID */
  groupId: string;
  /** 申请人UID */
  requesterUid: string;
  /** 申请人昵称 */
  requesterName: string;
  /** 申请附言 */
  message: string;
  /** 审核状态 */
  status: JoinRequestStatus;
  /** 申请时间戳(ms) */
  requestedAt: number;
  /** 审核时间戳(ms) */
  reviewedAt: number;
  /** 审核人UID */
  reviewerUid: string;
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
export interface FoodScanFeedContent {
  foodName: string;
  foodId: string;
  nutriScore: number;
  summary: string;
  memberResults: string;
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

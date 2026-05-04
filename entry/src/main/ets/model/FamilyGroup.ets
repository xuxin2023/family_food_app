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
  SYSTEM = 'system'
}

/** 家庭群组 */
export interface FamilyGroup {
  /** 群组ID */
  groupId: string;
  /** 群组名称 */
  groupName: string;
  /** 群组头像URL（可为空使用默认） */
  groupAvatar: string;
  /** 群组描述 */
  description: string;
  /** 创建者UID */
  ownerUid: string;
  /** 创建者昵称 */
  ownerName: string;
  /** 邀请码（用于加入群组） */
  inviteCode: string;
  /** 成员上限（基于订阅等级） */
  maxMembers: number;
  /** 当前成员数 */
  memberCount: number;
  /** 创建时间戳(ms) */
  createdAt: number;
  /** 更新时间戳(ms) */
  updatedAt: number;
  /** 是否已归档 */
  isArchived: boolean;
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
export interface GroupFeed {
  /** 动态ID */
  feedId: string;
  /** 群组ID */
  groupId: string;
  /** 动态类型 */
  feedType: FeedType;
  /** 发送者UID */
  senderUid: string;
  /** 发送者显示名称 */
  senderName: string;
  /** 动态内容（JSON字符串，具体结构由feedType决定） */
  content: string;
  /** 发布时间戳(ms) */
  createdAt: number;
  /** 评论数 */
  commentCount: number;
  /** 点赞数 */
  likeCount: number;
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

/** 群组摘要（含成员信息） */
export interface GroupSummary {
  group: FamilyGroup;
  members: GroupMember[];
  myRole: GroupRole;
}

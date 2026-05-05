// AiChat.ets
// AI 对话消息模型 — 支持多轮对话的聊天数据结构和预设提示

/**
 * 消息角色
 */
export enum ChatRole {
  /** 用户消息 */
  USER = 'user',
  /** AI 助手消息 */
  ASSISTANT = 'assistant',
  /** 系统提示（不显示在聊天中） */
  SYSTEM = 'system'
}

/**
 * 消息发送状态
 */
export enum MessageStatus {
  /** 发送中 */
  SENDING = 'sending',
  /** 发送成功 */
  SENT = 'sent',
  /** 发送失败 */
  FAILED = 'failed'
}

/**
 * 单条聊天消息
 */
export class ChatMessage {
  /** 唯一 ID */
  id: string = '';
  /** 消息内容 */
  content: string = '';
  /** 角色 */
  role: ChatRole = ChatRole.USER;
  /** 时间戳 */
  timestamp: number = 0;
  /** 发送状态（仅用户消息） */
  status: MessageStatus = MessageStatus.SENT;

  constructor(id: string, content: string, role: ChatRole, timestamp: number) {
    this.id = id;
    this.content = content;
    this.role = role;
    this.timestamp = timestamp;
  }
}

/**
 * 对话会话
 */
export class ChatSession {
  /** 会话 ID */
  sessionId: string = '';
  /** 会话标题（AI 自动生成的摘要或默认文字） */
  title: string = '';
  /** 成员 ID（关联的家庭成员） */
  memberId: string = '';
  /** 消息列表 */
  messages: ChatMessage[] = [];
  /** 创建时间 */
  createdAt: number = 0;
  /** 最后活跃时间 */
  lastActiveAt: number = 0;
}

/**
 * 预设快捷提问列表
 * 用户在对话页可直接点选提问，降低使用门槛
 */
export const QUICK_QUESTIONS: string[] = [
  '今天我的饮食营养均衡吗？',
  '帮我推荐一份低盐晚餐',
  '我适合吃什么零食？',
  '最近钠摄入是不是太多了？',
  '怎么提高蛋白质摄入？',
  '控糖期间能吃什么水果？'
];

/**
 * 生成消息 ID
 */
export function generateMessageId(): string {
  return `msg_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
}

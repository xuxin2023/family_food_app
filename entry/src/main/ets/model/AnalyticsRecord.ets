// 埋点数据模型
// 定义所有埋点事件的结构和类型枚举

/**
 * 埋点事件接口
 */
export interface AnalyticsEvent {
  eventId: string
  eventType: string
  timestamp: number
  properties: Record<string, string | number | boolean>
  sessionId: string
}

/**
 * 事件类型枚举
 */
export enum EventType {
  PAGE_VIEW = 'page_view',
  SCAN = 'scan',
  SHARE = 'share',
  MEAL_BALANCE = 'meal_balance',
  MEMBER_EDIT = 'member_edit',
  SUBSCRIPTION = 'subscription',
  SCORE_VIEW = 'score_view',
  ALTERNATIVE_CLICK = 'alternative_click'
}

/**
 * 埋点数据库表字段名（保持与 DB 列名一致）
 */
export const ANALYTICS_TABLE_NAME = 'analytics_events';

export const ANALYTICS_COLUMNS = {
  ID: 'id',
  EVENT_ID: 'event_id',
  EVENT_TYPE: 'event_type',
  TIMESTAMP: 'timestamp',
  PROPERTIES: 'properties',
  SESSION_ID: 'session_id',
  USER_ID: 'user_id',
  USER_TIER: 'user_tier',
  MEMBER_COUNT: 'member_count'
} as const;

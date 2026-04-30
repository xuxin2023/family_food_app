// 埋点数据模型
// 定义所有埋点事件的结构和类型枚举

export interface AnalyticsEvent {
  eventId: string
  eventType: string
  timestamp: number
  properties: Record<string, string | number | boolean>
  sessionId: string
}

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

export const ANALYTICS_TABLE_NAME = 'analytics_events';

export class AnalyticsColumns {
  ID: string = 'id';
  EVENT_ID: string = 'event_id';
  EVENT_TYPE: string = 'event_type';
  TIMESTAMP: string = 'timestamp';
  PROPERTIES: string = 'properties';
  SESSION_ID: string = 'session_id';
  USER_ID: string = 'user_id';
  USER_TIER: string = 'user_tier';
  MEMBER_COUNT: string = 'member_count';
}

export const ANALYTICS_COLUMNS = new AnalyticsColumns();

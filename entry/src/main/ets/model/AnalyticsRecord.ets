// 埋点数据模型

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

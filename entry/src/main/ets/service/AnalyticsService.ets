// 埋点统计服务 - 记录用户行为与增长指标

import { hilog } from '@kit.PerformanceAnalysisKit';
import { AnalyticsEvent, EventType } from '../model/AnalyticsRecord';

const TAG = 'AnalyticsService';
const DOMAIN_ZERO = 0;

let analyticsServiceInstance: AnalyticsService | null = null;

export class AnalyticsService {
  private sessionId: string = '';
  private userId: string = '';
  private healthGoals: string[] = [];
  private userTier: string = 'free';
  private memberCount: number = 1;
  private eventQueue: AnalyticsEvent[] = [];

  static getInstance(): AnalyticsService {
    if (analyticsServiceInstance === null) {
      analyticsServiceInstance = new AnalyticsService();
    }
    return analyticsServiceInstance;
  }

  /**
   * 初始化（生成会话ID）
   */
  init(): void {
    if (this.sessionId.length === 0) {
      this.sessionId = `sess_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
    }
  }

  // ==================== 事件追踪 ====================

  /**
   * 扫码行为追踪
   */
  trackScan(productName: string, memberCount: number, scanType: string): void {
    this.init();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: EventType.SCAN,
      timestamp: Date.now(),
      properties: {
        'product_name': productName,
        'member_count': memberCount,
        'scan_type': scanType
      },
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  /**
   * 分享行为追踪
   */
  trackShare(platform: string, cardType: string): void {
    this.init();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: EventType.SHARE,
      timestamp: Date.now(),
      properties: {
        'platform': platform,
        'card_type': cardType
      },
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  /**
   * 美食平衡使用追踪
   */
  trackMealBalance(scene: string): void {
    this.init();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: EventType.MEAL_BALANCE,
      timestamp: Date.now(),
      properties: {
        'scene': scene
      },
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  /**
   * 成员管理行为追踪
   */
  trackMemberEdit(memberId: string, action: string): void {
    this.init();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: EventType.MEMBER_EDIT,
      timestamp: Date.now(),
      properties: {
        'member_id': memberId,
        'action': action
      },
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  /**
   * 页面浏览追踪
   */
  trackPageView(pageName: string): void {
    this.init();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: EventType.PAGE_VIEW,
      timestamp: Date.now(),
      properties: {
        'page_name': pageName
      },
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  /**
   * 评分查看追踪
   */
  trackScoreView(foodName: string, score: number): void {
    this.init();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: EventType.SCORE_VIEW,
      timestamp: Date.now(),
      properties: {
        'food_name': foodName,
        'score': score
      },
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  /**
   * 替代品点击追踪
   */
  trackAlternativeClick(foodName: string, alternativeName: string, scoreDiff: number): void {
    this.init();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: EventType.ALTERNATIVE_CLICK,
      timestamp: Date.now(),
      properties: {
        'food_name': foodName,
        'alternative_name': alternativeName,
        'score_diff': scoreDiff
      },
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  // ==================== 用户画像追踪 ====================

  /**
   * 用户标识
   */
  identifyUser(userId: string, healthGoals: string[]): void {
    this.userId = userId;
    this.healthGoals = healthGoals;
    hilog.info(DOMAIN_ZERO, TAG, 'User identified: %{public}s, goals: %{public}s',
      userId, JSON.stringify(healthGoals));
  }

  /**
   * 会员等级
   */
  setUserTier(tier: string): void {
    this.userTier = tier;
    hilog.info(DOMAIN_ZERO, TAG, 'User tier set: %{public}s', tier);
  }

  /**
   * 家庭成员数更新
   */
  updateMemberCount(count: number): void {
    this.memberCount = count;
    hilog.info(DOMAIN_ZERO, TAG, 'Member count updated: %{public}d', count);
  }

  // ==================== 内部方法 ====================

  /**
   * 生成事件ID
   */
  private generateEventId(): string {
    return `evt_${Date.now()}_${Math.floor(Math.random() * 9999)}`;
  }

  /**
   * 入队并异步上报
   */
  private enqueue(event: AnalyticsEvent): void {
    this.eventQueue.push(event);
    this.flush();
  }

  /**
   * 异步上报（当前HAP调试阶段仅输出日志）
   */
  private flush(): void {
    if (this.eventQueue.length > 0) {
      const batch = this.eventQueue.splice(0, this.eventQueue.length);
      for (const event of batch) {
        hilog.info(DOMAIN_ZERO, TAG,
          '[Analytics] eventType=%{public}s eventId=%{public}s ts=%{public}d props=%{public}s',
          event.eventType, event.eventId, event.timestamp, JSON.stringify(event.properties));
      }
    }
  }
}

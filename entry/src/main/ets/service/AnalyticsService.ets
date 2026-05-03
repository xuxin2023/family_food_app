// 埋点统计服务 - 记录用户行为与增长指标
// 使用关系型数据库本地持久化，支持批量写入和定时上报

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import {
  AnalyticsEvent,
  EventType,
  ANALYTICS_TABLE_NAME,
  ANALYTICS_COLUMNS
} from '../model/AnalyticsRecord';

const TAG = 'AnalyticsService';
const DOMAIN_ZERO = 0;

/** 内存队列最大容量，达到此数量触发自动 flush */
const FLUSH_BATCH_SIZE = 30;

/** 自动 flush 的间隔（毫秒） */
const FLUSH_INTERVAL_MS = 5 * 60 * 1000; // 5 分钟

let analyticsServiceInstance: AnalyticsService | null = null;

export class AnalyticsService {
  private sessionId: string = '';
  private userId: string = '';
  private healthGoals: string[] = [];
  private userTier: string = 'free';
  private memberCount: number = 1;
  private eventQueue: AnalyticsEvent[] = [];
  private rdbStore: relationalStore.RdbStore | null = null;
  private dbReady: boolean = false;
  private flushTimerId: number = -1;

  static getInstance(): AnalyticsService {
    if (analyticsServiceInstance === null) {
      analyticsServiceInstance = new AnalyticsService();
    }
    return analyticsServiceInstance;
  }

  /**
   * 初始化（必须在应用启动时调用一次）
   * @param context 应用上下文，用于创建数据库
   */
  async init(context: common.Context): Promise<void> {
    // 生成会话ID
    if (this.sessionId.length === 0) {
      this.sessionId = `sess_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
    }

    try {
      // 创建或打开事件数据库
      const rdbConfig: relationalStore.StoreConfig = {
        name: 'analytics.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };
      this.rdbStore = await relationalStore.getRdbStore(context, rdbConfig);

      // 创建事件表
      await this.rdbStore.executeSql(`CREATE TABLE IF NOT EXISTS ${ANALYTICS_TABLE_NAME} (
        ${ANALYTICS_COLUMNS.ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${ANALYTICS_COLUMNS.EVENT_ID} TEXT NOT NULL,
        ${ANALYTICS_COLUMNS.EVENT_TYPE} TEXT NOT NULL,
        ${ANALYTICS_COLUMNS.TIMESTAMP} INTEGER NOT NULL,
        ${ANALYTICS_COLUMNS.PROPERTIES} TEXT,
        ${ANALYTICS_COLUMNS.SESSION_ID} TEXT,
        ${ANALYTICS_COLUMNS.USER_ID} TEXT,
        ${ANALYTICS_COLUMNS.USER_TIER} TEXT,
        ${ANALYTICS_COLUMNS.MEMBER_COUNT} INTEGER
      )`);

      // 创建索引（按事件类型和时间戳查询优化）
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_event_type ON ${ANALYTICS_TABLE_NAME} (${ANALYTICS_COLUMNS.EVENT_TYPE})`
      );
      await this.rdbStore.executeSql(
        `CREATE INDEX IF NOT EXISTS idx_timestamp ON ${ANALYTICS_TABLE_NAME} (${ANALYTICS_COLUMNS.TIMESTAMP})`
      );

      this.dbReady = true;
      hilog.info(DOMAIN_ZERO, TAG, 'Analytics DB initialized');

      // 启动定时 flush 定时器
      this.startFlushTimer();
    } catch (error) {
      this.dbReady = false;
      hilog.error(DOMAIN_ZERO, TAG, 'Init analytics DB failed: %{public}s', JSON.stringify(error));
    }
  }

  // ==================== 事件追踪方法 ====================

  /**
   * 核心追踪方法
   * @param type 事件类型（推荐使用 EventType 枚举值）
   * @param properties 事件自定义属性
   */
  trackEvent(type: string, properties: Record<string, string | number | boolean>): void {
    this.ensureSession();
    const event: AnalyticsEvent = {
      eventId: this.generateEventId(),
      eventType: type,
      timestamp: Date.now(),
      properties: properties,
      sessionId: this.sessionId
    };
    this.enqueue(event);
  }

  /**
   * 扫码行为追踪
   */
  trackScan(productName: string, memberCount: number, scanType: string): void {
    this.trackEvent(EventType.SCAN, {
      'product_name': productName,
      'member_count': memberCount,
      'scan_type': scanType
    });
  }

  /**
   * 分享行为追踪
   */
  trackShare(platform: string, cardType: string): void {
    this.trackEvent(EventType.SHARE, {
      'platform': platform,
      'card_type': cardType
    });
  }

  /**
   * 美食平衡使用追踪
   */
  trackMealBalance(scene: string): void {
    this.trackEvent(EventType.MEAL_BALANCE, {
      'scene': scene
    });
  }

  /**
   * 成员管理行为追踪
   */
  trackMemberEdit(memberId: string, action: string): void {
    this.trackEvent(EventType.MEMBER_EDIT, {
      'member_id': memberId,
      'action': action
    });
  }

  /**
   * 页面浏览追踪
   */
  trackPageView(pageName: string): void {
    this.trackEvent(EventType.PAGE_VIEW, {
      'page_name': pageName
    });
  }

  /**
   * 评分查看追踪
   */
  trackScoreView(foodName: string, score: number): void {
    this.trackEvent(EventType.SCORE_VIEW, {
      'food_name': foodName,
      'score': score
    });
  }

  /**
   * 替代品点击追踪
   */
  trackAlternativeClick(foodName: string, alternativeName: string, scoreDiff: number): void {
    this.trackEvent(EventType.ALTERNATIVE_CLICK, {
      'food_name': foodName,
      'alternative_name': alternativeName,
      'score_diff': scoreDiff
    });
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
   * 会员等级设置
   */
  setUserTier(tier: string): void {
    this.userTier = tier;
    hilog.info(DOMAIN_ZERO, TAG, 'User tier set: %{public}s', tier);
    this.trackEvent(EventType.SUBSCRIPTION, {
      'tier': tier,
      'action': 'set_tier'
    });
  }

  /**
   * 家庭成员数更新
   */
  updateMemberCount(count: number): void {
    this.memberCount = count;
    hilog.info(DOMAIN_ZERO, TAG, 'Member count updated: %{public}d', count);
  }

  /**
   * 获取家庭成员数
   */
  getMemberCount(): number {
    return this.memberCount;
  }

  // ==================== 批量写入 ====================

  /**
   * 将内存队列中的事件批量写入本地数据库
   */
  async flush(): Promise<void> {
    if (this.eventQueue.length === 0) {
      return;
    }

    const batch = this.eventQueue.splice(0, this.eventQueue.length);

    if (!this.dbReady || this.rdbStore === null) {
      // 数据库不可用，回退到日志输出
      for (const event of batch) {
        hilog.info(DOMAIN_ZERO, TAG,
          '[Analytics Fallback] eventType=%{public}s eventId=%{public}s ts=%{public}d props=%{public}s',
          event.eventType, event.eventId, event.timestamp, JSON.stringify(event.properties));
      }
      return;
    }

    try {
      // 批量插入
      await this.rdbStore.beginTransaction();
      for (const event of batch) {
        const valueBucket: relationalStore.ValuesBucket = {
          'event_id': event.eventId,
          'event_type': event.eventType,
          'timestamp': event.timestamp,
          'properties': JSON.stringify(event.properties),
          'session_id': event.sessionId,
          'user_id': this.userId,
          'user_tier': this.userTier,
          'member_count': this.memberCount
        };
        await this.rdbStore.insert(ANALYTICS_TABLE_NAME, valueBucket);
      }
      await this.rdbStore.commit();
      hilog.info(DOMAIN_ZERO, TAG, 'Flushed %{public}d events to DB', batch.length);
    } catch (error) {
      // 回滚事务
      try {
        await this.rdbStore.rollBack();
      } catch (_rollbackError) {
        // 静默处理回滚失败
      }
      hilog.error(DOMAIN_ZERO, TAG, 'Batch flush failed: %{public}s', JSON.stringify(error));
      // 失败时将事件放回队列前端，避免丢失
      this.eventQueue = [...batch, ...this.eventQueue];
    }
  }

  /**
   * 查询历史事件（用于调试/周报）
   */
  async queryEvents(
    type?: string,
    startTime?: number,
    endTime?: number,
    limit: number = 100
  ): Promise<AnalyticsEvent[]> {
    if (!this.dbReady || this.rdbStore === null) {
      return [];
    }

    try {
      const predicates = new relationalStore.RdbPredicates(ANALYTICS_TABLE_NAME);

      if (type !== undefined && type.length > 0) {
        predicates.equalTo(ANALYTICS_COLUMNS.EVENT_TYPE, type);
      }
      if (startTime !== undefined) {
        predicates.greaterThanOrEqualTo(ANALYTICS_COLUMNS.TIMESTAMP, startTime);
      }
      if (endTime !== undefined) {
        predicates.lessThanOrEqualTo(ANALYTICS_COLUMNS.TIMESTAMP, endTime);
      }

      predicates.orderByDesc(ANALYTICS_COLUMNS.TIMESTAMP);
      predicates.limitAs(limit);

      const resultSet = await this.rdbStore.query(predicates);
      const events: AnalyticsEvent[] = [];

      while (resultSet.goToNextRow()) {
        const event: AnalyticsEvent = {
          eventId: resultSet.getString(resultSet.getColumnIndex(ANALYTICS_COLUMNS.EVENT_ID)),
          eventType: resultSet.getString(resultSet.getColumnIndex(ANALYTICS_COLUMNS.EVENT_TYPE)),
          timestamp: resultSet.getLong(resultSet.getColumnIndex(ANALYTICS_COLUMNS.TIMESTAMP)),
          properties: this.parseProperties(
            resultSet.getString(resultSet.getColumnIndex(ANALYTICS_COLUMNS.PROPERTIES))
          ),
          sessionId: resultSet.getString(resultSet.getColumnIndex(ANALYTICS_COLUMNS.SESSION_ID))
        };
        events.push(event);
      }

      resultSet.close();
      return events;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Query events failed: %{public}s', JSON.stringify(error));
      return [];
    }
  }

  /**
   * 获取事件数量统计（按类型分组）
   */
  async getEventCounts(
    startTime?: number,
    endTime?: number
  ): Promise<Record<string, number>> {
    if (!this.dbReady || this.rdbStore === null) {
      return {};
    }

    try {
      let sql = `SELECT ${ANALYTICS_COLUMNS.EVENT_TYPE}, COUNT(*) as cnt FROM ${ANALYTICS_TABLE_NAME} WHERE 1=1`;
      const args: number[] = [];

      if (startTime !== undefined) {
        sql += ` AND ${ANALYTICS_COLUMNS.TIMESTAMP} >= ?`;
        args.push(startTime);
      }
      if (endTime !== undefined) {
        sql += ` AND ${ANALYTICS_COLUMNS.TIMESTAMP} <= ?`;
        args.push(endTime);
      }

      sql += ' GROUP BY event_type';

      const resultSet = await this.rdbStore.querySql(sql, args);
      const counts: Record<string, number> = {};

      while (resultSet.goToNextRow()) {
        const eventType = resultSet.getString(0);
        const count = resultSet.getLong(1);
        counts[eventType] = count;
      }

      resultSet.close();
      return counts;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Get event counts failed: %{public}s', JSON.stringify(error));
      return {};
    }
  }

  /**
   * 清理旧数据（保留最近 90 天）
   */
  async cleanOldData(retentionDays: number = 90): Promise<number> {
    if (!this.dbReady || this.rdbStore === null) {
      return 0;
    }

    const cutoffTime = Date.now() - retentionDays * 24 * 60 * 60 * 1000;
    try {
      const predicates = new relationalStore.RdbPredicates(ANALYTICS_TABLE_NAME);
      predicates.lessThan(ANALYTICS_COLUMNS.TIMESTAMP, cutoffTime);
      const deletedRows = await this.rdbStore.delete(predicates);
      hilog.info(DOMAIN_ZERO, TAG, 'Cleaned %{public}d old events', deletedRows);
      return deletedRows;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'Clean old data failed: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * 析构（应用退出时调用）
   */
  async destroy(): Promise<void> {
    // 停止定时器
    if (this.flushTimerId !== -1) {
      try {
        clearTimeout(this.flushTimerId);
      } catch (_e) {
        // ignore clearTimeout error
      }
      this.flushTimerId = -1;
    }
    // 刷出剩余队列
    await this.flush();
    this.rdbStore = null;
    this.dbReady = false;
    hilog.info(DOMAIN_ZERO, TAG, 'AnalyticsService destroyed');
  }

  // ==================== 内部方法 ====================

  /**
   * 确保会话已初始化
   */
  private ensureSession(): void {
    if (this.sessionId.length === 0) {
      this.sessionId = `sess_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
    }
  }

  /**
   * 生成事件ID
   */
  private generateEventId(): string {
    return `evt_${Date.now()}_${Math.floor(Math.random() * 9999)}`;
  }

  /**
   * 入队事件，队列满时自动 flush
   */
  private enqueue(event: AnalyticsEvent): void {
    this.eventQueue.push(event);
    hilog.info(DOMAIN_ZERO, TAG, '[Analytics] eventType=%{public}s eventId=%{public}s ts=%{public}d props=%{public}s',
      event.eventType, event.eventId, event.timestamp, JSON.stringify(event.properties));

    // 队列达到阈值时自动写入
    if (this.eventQueue.length >= FLUSH_BATCH_SIZE) {
      this.flush();
    }
  }

  /**
   * 启动定时 flush 定时器
   */
  private startFlushTimer(): void {
    if (this.flushTimerId !== -1) {
      try {
        clearTimeout(this.flushTimerId);
      } catch (_e) {
        // ignore clearTimeout error
      }
    }
    this.flushTimerId = setInterval(() => {
      this.flush();
    }, FLUSH_INTERVAL_MS);
  }

  /**
   * 解析 properties 字段 JSON 字符串
   */
  private parseProperties(jsonStr: string): Record<string, string | number | boolean> {
    if (jsonStr === null || jsonStr.length === 0) {
      return {};
    }
    try {
      return JSON.parse(jsonStr) as Record<string, string | number | boolean>;
    } catch {
      return {};
    }
  }
}

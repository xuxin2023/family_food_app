// 里程碑服务 - 用户行为成就系统
// 基于 AnalyticsService 的事件统计，自动检测和展示用户里程碑

import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { AnalyticsService } from './AnalyticsService';
import { EventType } from '../model/AnalyticsRecord';
import { HILOG_DOMAIN } from '../constants/AppConfig';

const TAG = 'MilestoneService';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export interface Milestone {
  name: string;
  title: string;
  description: string;
  icon: string;
  progress: number;       // 0 ~ 100 百分比
  current: number;        // 当前值
  target: number;         // 目标值
  achieved: boolean;
  acknowledged: boolean;
}

let milestoneServiceInstance: MilestoneService | null = null;

export class MilestoneService {
  private milestones: Milestone[] = [];
  private context: common.Context | null = null;
  private analyticsService: AnalyticsService = AnalyticsService.getInstance();

  static getInstance(): MilestoneService {
    if (milestoneServiceInstance === null) {
      milestoneServiceInstance = new MilestoneService();
    }
    return milestoneServiceInstance;
  }

  /**
   * 初始化
   */
  async init(context: common.Context): Promise<void> {
    this.context = context;
    await this.loadAcknowledgedStatus();
    hilog.info(DOMAIN_ZERO, TAG, 'MilestoneService initialized');
  }

  /**
   * 检查所有里程碑
   * 返回所有里程碑的最新状态
   */
  async checkMilestones(): Promise<Milestone[]> {
    const countMap = await this.collectEventCounts();
    const memberCount = AnalyticsService.getInstance().getMemberCount();

    // 计算连续使用天数
    const streakDays = await this.calculateStreakDays(countMap);

    // 定义六个里程碑
    const allMilestones: Milestone[] = [
      {
        name: 'first_scan',
        title: '初次探索',
        description: '首次扫码，开启饮食新视角',
        icon: '🔍',
        progress: Math.min(100, Math.round((countMap.get('scan') || 0) / 1 * 100)),
        current: Math.min(1, countMap.get('scan') || 0),
        target: 1,
        achieved: (countMap.get('scan') || 0) >= 1,
        acknowledged: false
      },
      {
        name: 'family_guardian',
        title: '家庭守护者',
        description: '为全家人建立独立健康档案',
        icon: '👨‍👩‍👧‍👦',
        progress: Math.min(100, Math.round(memberCount / 4 * 100)),
        current: memberCount,
        target: 4,
        achieved: memberCount >= 4,
        acknowledged: false
      },
      {
        name: 'scan_master',
        title: '扫码达人',
        description: '累计扫描50次，阅食无数',
        icon: '📱',
        progress: Math.min(100, Math.round((countMap.get('scan') || 0) / 50 * 100)),
        current: countMap.get('scan') || 0,
        target: 50,
        achieved: (countMap.get('scan') || 0) >= 50,
        acknowledged: false
      },
      {
        name: 'balance_pro',
        title: '平衡大师',
        description: '美食平衡10次，懂吃更会搭',
        icon: '⚖️',
        progress: Math.min(100, Math.round((countMap.get(EventType.MEAL_BALANCE) || 0) / 10 * 100)),
        current: countMap.get(EventType.MEAL_BALANCE) || 0,
        target: 10,
        achieved: (countMap.get(EventType.MEAL_BALANCE) || 0) >= 10,
        acknowledged: false
      },
      {
        name: 'share_leader',
        title: '分享先锋',
        description: '分享卡片5次，关爱传递',
        icon: '📤',
        progress: Math.min(100, Math.round((countMap.get(EventType.SHARE) || 0) / 5 * 100)),
        current: countMap.get(EventType.SHARE) || 0,
        target: 5,
        achieved: (countMap.get(EventType.SHARE) || 0) >= 5,
        acknowledged: false
      },
      {
        name: 'weekly_streak',
        title: '连续打卡',
        description: '连续7天使用，饮食自律达人',
        icon: '🔥',
        progress: Math.min(100, Math.round(streakDays / 7 * 100)),
        current: streakDays,
        target: 7,
        achieved: streakDays >= 7,
        acknowledged: false
      }
    ];

    // 恢复已确认状态
    for (const ms of allMilestones) {
      const saved = this.milestones.find(m => m.name === ms.name);
      if (saved) {
        ms.acknowledged = saved.acknowledged;
      }
    }

    this.milestones = allMilestones;

    // 自动弹 Toast 提示新达成的里程碑
    await this.autoNotifyNewMilestones();

    return this.milestones;
  }

  /**
   * 获取指定里程碑的进度百分比
   */
  getProgressPercent(milestoneName: string): number {
    const ms = this.milestones.find(m => m.name === milestoneName);
    return ms ? ms.progress : 0;
  }

  /**
   * 标记里程碑已确认
   */
  async acknowledgeMilestone(milestoneName: string): Promise<void> {
    const ms = this.milestones.find(m => m.name === milestoneName);
    if (ms) {
      ms.acknowledged = true;
      await this.saveAcknowledgedStatus();
      hilog.info(DOMAIN_ZERO, TAG, 'Milestone acknowledged: %{public}s', milestoneName);
    }
  }

  /**
   * 获取未确认的已达成里程碑列表
   */
  getUnacknowledgedMilestones(): Milestone[] {
    return this.milestones.filter(m => m.achieved && !m.acknowledged);
  }

  /**
   * 确认所有达成里程碑
   */
  async acknowledgeAll(): Promise<void> {
    for (const ms of this.milestones) {
      if (ms.achieved) {
        ms.acknowledged = true;
      }
    }
    await this.saveAcknowledgedStatus();
  }

  // ==================== 内部方法 ====================

  /**
   * 从 AnalyticsService 的查询接口收集各类事件计数
   */
  private async collectEventCounts(): Promise<Map<string, number>> {
    const countMap: Map<string, number> = new Map();

    try {
      // 查询 scan 事件（通过 EventType.SCAN）
      const scanCounts = await this.analyticsService.getEventCounts();
      const keys: string[] = Object.keys(scanCounts);
      for (let i = 0; i < keys.length; i++) {
        countMap.set(keys[i], scanCounts[keys[i]]);
      }

      // 额外查询 share 事件
      const shareEvents = await this.analyticsService.queryEvents(EventType.SHARE);
      countMap.set(EventType.SHARE, Math.max(countMap.get(EventType.SHARE) || 0, shareEvents.length));

      // 额外查询 meal_balance 事件
      const balanceEvents = await this.analyticsService.queryEvents(EventType.MEAL_BALANCE);
      countMap.set(EventType.MEAL_BALANCE, Math.max(countMap.get(EventType.MEAL_BALANCE) || 0, balanceEvents.length));
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'collectEventCounts failed: %{public}s', JSON.stringify(error));
    }

    return countMap;
  }

  /**
   * 计算连续使用天数（基于 page_view 记录）
   */
  private async calculateStreakDays(countMap: Map<string, number>): Promise<number> {
    try {
      const pageViewEvents = await this.analyticsService.queryEvents(EventType.PAGE_VIEW);
      if (pageViewEvents.length === 0) {
        return 0;
      }

      // 提取所有有使用的日期（去重）
      const activeDates: Set<string> = new Set();
      for (const event of pageViewEvents) {
        const dateStr = this.timestampToDateStr(event.timestamp);
        activeDates.add(dateStr);
      }

      // 计算从今天开始的连续天数
      const today = this.timestampToDateStr(Date.now());
      if (!activeDates.has(today)) {
        return 0; // 今天没用过，连续为0
      }

      let streak = 0;
      const currentDate = new Date();
      while (true) {
        const dateStr = this.timestampToDateStr(currentDate.getTime());
        if (activeDates.has(dateStr)) {
          streak++;
          currentDate.setDate(currentDate.getDate() - 1);
        } else {
          break;
        }
      }

      return streak;
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'calculateStreakDays failed: %{public}s', JSON.stringify(error));
      return 0;
    }
  }

  /**
   * 自动弹 Toast 提示新达成的里程碑
   */
  private async autoNotifyNewMilestones(): Promise<void> {
    const unacknowledged = this.getUnacknowledgedMilestones();
    if (unacknowledged.length === 0) {
      return;
    }

    // 按进度从高到低排序，只弹进度最高的前两个
    unacknowledged.sort((a, b) => b.progress - a.progress);
    const top = unacknowledged.slice(0, 2);

    for (const ms of top) {
      // 简单延迟，避免 Toast 堆叠
      const idx = top.indexOf(ms);
      if (idx > 0) {
        await this.sleep(800);
      }
      try {
        promptAction.showToast({
          message: `🎉 恭喜达成「${ms.title}」！${ms.description}`,
          duration: 3000
        });
      } catch (_) {
        hilog.warn(DOMAIN_ZERO, TAG, 'showToast failed for milestone: %{public}s', ms.name);
      }
      // 默认自动标记为已确认（避免重复弹窗）
      await this.acknowledgeMilestone(ms.name);
    }
  }

  /**
   * 从 preferences 加载已确认状态
   */
  private async loadAcknowledgedStatus(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'milestone_prefs');
      const names = ['first_scan', 'family_guardian', 'scan_master', 'balance_pro', 'share_leader', 'weekly_streak'];
      this.milestones = [];
      for (const name of names) {
        const ack = prefs.getSync(name, false) as boolean;
        this.milestones.push({
          name: name,
          title: '',
          description: '',
          icon: '',
          progress: 0,
          current: 0,
          target: 1,
          achieved: false,
          acknowledged: ack
        });
      }
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadAcknowledgedStatus failed: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 保存已确认状态到 preferences
   */
  private async saveAcknowledgedStatus(): Promise<void> {
    if (!this.context) return;
    try {
      const prefs = await preferences.getPreferences(this.context, 'milestone_prefs');
      for (const ms of this.milestones) {
        prefs.putSync(ms.name, ms.acknowledged);
      }
      await prefs.flush();
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'saveAcknowledgedStatus failed: %{public}s', JSON.stringify(error));
    }
  }

  private timestampToDateStr(ts: number): string {
    const d = new Date(ts);
    return `${d.getFullYear()}-${(d.getMonth() + 1).toString().padStart(2, '0')}-${d.getDate().toString().padStart(2, '0')}`;
  }

  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }
}
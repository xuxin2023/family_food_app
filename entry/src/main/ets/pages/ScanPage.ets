// ScanPage.ets
// 扫描页 - V2 体验升级版

import {
  ToastHelper, safePushUrl, getPageParams, FoodLabel, FamilyProfile, HealthSignal, Throttler, PaywallTrigger,
  TIER_DAILY_SCAN_LIMIT, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON, SCAN_CONFIG,
  HILOG_DOMAIN_DEFAULT, SCORE_COLORS, EnhancedFoodRecommendation, AccessibilityUtil, TodayIntakeInput, DeviceAdapter,
  Breakpoint, PerformanceMonitor, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive,
  ThemeColors, ThemeMode, HapticHelper
} from 'hsp_core';
import { FoodInputResult, IRemoteLookupProvider } from 'feature_scan';
import { BatchScanService, BatchScanResult } from 'hsp_service';
import { common } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { scanBarcode, scanCore } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppState } from '../AppState';
import { PermissionGuideDialog, NutriScoreBadge, PaywallDialog } from 'feature_scan';
import { BackButton } from '../components/BackButton';
import { ScanResultCard } from '../components/ScanResultCard';
import { ScanEditPanel } from '../components/ScanEditPanel';
import { ScanModeSelector } from '../components/ScanModeSelector';
import { AddToShoppingListButton } from '../components/AddToShoppingListButton';
import { FoodDeepAnalysisSheet } from '../components/FoodDeepAnalysisSheet';
import { BatchScanSheet } from '../components/BatchScanSheet';
import { GlassCard, GlassDepth } from '../components/GlassCard';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TAG = 'ScanPage';

enum ScanPhase {
  IDLE = 'idle',
  RECOGNIZING = 'recognizing',
  DB_QUERYING = 'db_querying',
  API_QUERYING = 'api_querying',
  SCORING = 'scoring',
  DONE = 'done',
  TIMEOUT = 'timeout',
  ERROR = 'error'
}

class EditPanelData {
  foodName: string = '';
  sodium: string = '0';
  sugar: string = '0';
  calories: string = '0';
  fat: string = '0';
  carbohydrate: string = '0';
  protein: string = '0';
  ingredients: string = '';
  manufacturer: string = '';
  scNumber: string = '';
  principal: string = '';
  trustee: string = '';
}

@ObservedV2
class ScanViewModel {
  @Trace scanPhase: ScanPhase = ScanPhase.IDLE;
  @Trace foodLabel: FoodLabel = new FoodLabel();
  @Trace showEditPanel: boolean = false;
  @Trace scanLimitReached: boolean = false;
  @Trace remainingScans: number = 3;
  @Trace recognizedText: string = '';
  @Trace recognitionHint: ResourceStr = '';
  @Trace ocrConfidence: number = 1;
  @Trace isOffline: boolean = false;
  @Trace frequentItems: FoodLabel[] = [];
  @Trace recentScans: FoodLabel[] = [];
  @Trace scoreReady: boolean = false;
  @Trace nutriScore: number = 50;
  @Trace detailLoading: boolean = false;
  @Trace showPaywallDialog: boolean = false;
  @Trace paywallTrigger: PaywallTrigger | null = null;
  @Trace editPanel: EditPanelData = new EditPanelData();
  @Trace retryCount: number = 0;
  @Trace continuousMode: boolean = false;
  @Trace batchResults: FoodLabel[] = [];
  @Trace lastError: string = '';
  @Trace showErrorBanner: boolean = false;
  @Trace isLoadingRetry: boolean = false;
  @Trace permissionDenied: boolean = false;
  @Trace showPermissionGuide: boolean = false;
  @Trace currentBreakpoint: string = 'md';
  @Trace scanMode: string = 'camera';
}

@Entry
@ComponentV2
export struct ScanPage {
  @Local vm: ScanViewModel = new ScanViewModel();
  @Local showDeepAnalysis: boolean = false;
  @Local showBatchScan: boolean = false;

  private memberId: string = '';
  private appState: AppState = AppState.getInstance();
  private foodInputService = this.appState.foodInput;
  private batchScanService: BatchScanService = new BatchScanService();
  private autoScanTimer: number = -1;
  private retryTimer: number = -1;
  private scoreTimer: number = -1;
  private componentActive: boolean = true;
  private scanThrottler: Throttler = new Throttler(500);
  private tracker: PageResourceTracker = createPageTracker('ScanPage');

  // ==================== 生命周期 ====================

  private themeRef: ThemeReactive = themeReactive

  async aboutToAppear() {
    this.tracker.onAppear();
    PerformanceMonitor.getInstance().pageEnter('ScanPage');
    try {
      const params = getPageParams();
      if (params !== undefined) {
        const mid = params.get('memberId');
        if (typeof mid === 'string') {
          this.memberId = mid;
        }
      }
      this.checkNetworkStatus();
      this.refreshScanQuota();
      this.loadFrequentItems();
      this.loadRecentScans();
      this.triggerAutoScan();
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed');
    }
  }

  onPageShow() {
  }

  private resetScan(): void {
    this.vm.foodLabel = new FoodLabel();
    this.vm.scanPhase = ScanPhase.IDLE;
    this.vm.scanMode = 'barcode';
    this.autoScanTimer = -1;
    this.retryTimer = -1;
    this.vm.recognitionHint = $r('app.string.first_time_hint');
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear();
    PerformanceMonitor.getInstance().pageLeave('ScanPage');
    this.componentActive = false;
    if (this.autoScanTimer !== -1) {
      try { clearTimeout(this.autoScanTimer); } catch (_e) { }
      this.autoScanTimer = -1;
    }
    if (this.retryTimer !== -1) {
      try { clearTimeout(this.retryTimer); } catch (_e) { }
      this.retryTimer = -1;
    }
    if (this.scoreTimer !== -1) {
      try { clearTimeout(this.scoreTimer); } catch (_e) { }
      this.scoreTimer = -1;
    }
  }

  // ==================== 数据加载 ====================

  private checkNetworkStatus(): void {
    const online: boolean = this.appState.network.isOnline;
    this.vm.isOffline = !online;
  }

  private refreshScanQuota(): void {
    try {
      const member = this.appState.member;
      if (member && member.memberStatus) {
        const limit = TIER_DAILY_SCAN_LIMIT.get(member.memberStatus.tier) ?? 3;
        const used = member.memberStatus.scansRemainingToday ?? 0;
        this.vm.remainingScans = Math.max(0, limit - used);
        this.vm.scanLimitReached = this.vm.remainingScans <= 0;
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'refreshScanQuota failed');
    }
  }

  private triggerAutoScan(): void {
    if (this.vm.scanLimitReached) { return; }
    // 不再自动扫码，等待用户点击按钮
    this.vm.scanPhase = ScanPhase.IDLE;
    this.vm.recognitionHint = $r('app.string.first_time_hint');
  }

  private async loadFrequentItems(): Promise<void> {
    try {
      const records = await this.appState.getRecentScanHistory(50);
      const foodIds: string[] = [];
      for (const record of records) {
        if (record.foodId && foodIds.indexOf(record.foodId) < 0) {
          foodIds.push(record.foodId);
        }
      }
      const foodMap = await this.appState.findFoodByIds(foodIds);
      const items: FoodLabel[] = [];
      for (const foodId of foodIds) {
        const foodLabel = foodMap.get(foodId);
        if (foodLabel && foodLabel.foodName.length > 0) {
          items.push(foodLabel);
          if (items.length >= 8) { break; }
        }
      }
      this.vm.frequentItems = items;
    } catch (_error) {
      hilog.warn(DOMAIN_ZERO, TAG, '预加载高频商品失败');
    }
  }

  private async loadRecentScans(): Promise<void> {
    try {
      const records = await this.appState.getRecentScanHistory(SCAN_CONFIG.RECENT_SCAN_SHOW_COUNT);
      const foodIds = records.map(r => r.foodId).filter(id => id.length > 0);
      const foodMap = await this.appState.findFoodByIds(foodIds);
      const items: FoodLabel[] = [];
      for (const record of records) {
        const foodLabel = foodMap.get(record.foodId);
        if (foodLabel && foodLabel.foodName.length > 0) {
          items.push(foodLabel);
        }
      }
      this.vm.recentScans = items;
    } catch (_error) {
      hilog.warn(DOMAIN_ZERO, TAG, '加载最近扫描记录失败');
    }
  }

  // ==================== 核心扫描 ====================

  private startRecognition(): void {
    if (this.vm.scanLimitReached) {
      this.vm.showPaywallDialog = true;
      return;
    }
    this.vm.scanPhase = ScanPhase.RECOGNIZING;
    this.vm.recognitionHint = '正在识别...';
    this.doBarcodeScan();
  }

  private async doBarcodeScan(): Promise<void> {
    try {
      const context = getContext(this) as common.Context;
      const result = await this.foodInputService.scanBarcode(context);

      if (!this.componentActive) return;

      if (result && result.foodLabel && result.foodLabel.foodId.length > 0) {
        // 扫码成功，获取到食品信息
        this.vm.foodLabel = result.foodLabel;
        this.vm.recognizedText = result.recognizedText;
        this.vm.recognitionHint = result.hint;
        this.vm.ocrConfidence = result.confidence;

        if (result.foodLabel.foodName !== '条码商品（待补充）') {
          // 命中数据库，直接显示结果
          this.vm.scanPhase = ScanPhase.DONE;
          await this.calculateScoreForCurrentLabel();
          this.vibrateSuccess();
        } else {
          // 仅识别到条码，需要手动补全
          this.vm.scanPhase = ScanPhase.DONE;
          this.vm.recognitionHint = '条码已识别，请补全食品信息';
          this.loadEditFormFromLabel();
        }
      } else {
        // 扫码取消或失败
        this.vm.scanPhase = ScanPhase.IDLE;
        this.vm.recognitionHint = $r('app.string.scan_manual_hint');
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'doBarcodeScan failed: %{public}s', JSON.stringify(e));
      if (this.componentActive) {
        this.vm.scanPhase = ScanPhase.ERROR;
        this.vm.lastError = '扫码失败，请重试';
        this.vm.showErrorBanner = true;
        this.vibrateError();
      }
    }
  }

  private vibrateSuccess(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 40 }, { id: 0, usage: 'notification' });
      setTimeout(() => {
        try {
          vibrator.startVibration({ type: 'time', duration: 60 }, { id: 0, usage: 'notification' });
        } catch (_e) { }
      }, 80)
    } catch (_e) {
      // 震动失败不影响流程
    }
  }

  private vibrateError(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 200 }, { id: 0, usage: 'notification' });
    } catch (_e) {
    }
  }

  private isRecognizing(): boolean {
    return this.vm.scanPhase === ScanPhase.RECOGNIZING ||
      this.vm.scanPhase === ScanPhase.DB_QUERYING ||
      this.vm.scanPhase === ScanPhase.API_QUERYING;
  }

  private async calculateScoreForCurrentLabel(): Promise<void> {
    if (this.vm.foodLabel.foodId.length === 0) { return; }
    this.vm.detailLoading = true;
    try {
      const score: number = await this.appState.calculateNutriScore(this.vm.foodLabel);
      this.vm.nutriScore = score;
      this.vm.scoreReady = true;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'calculateScore failed');
    } finally {
      this.vm.detailLoading = false;
    }
  }

  private startManualEntry(): void {
    if (this.vm.scanLimitReached) {
      this.vm.showPaywallDialog = true;
      return;
    }
    this.vm.showEditPanel = true;
  }

  private loadEditFormFromLabel(): void {
    const label = this.vm.foodLabel;
    const n = label.nutrition;
    this.vm.editPanel.foodName = label.foodName;
    this.vm.editPanel.sodium = String(n.sodium);
    this.vm.editPanel.sugar = String(n.sugar);
    this.vm.editPanel.calories = String(n.calories);
    this.vm.editPanel.fat = String(n.fat);
    this.vm.editPanel.carbohydrate = String(n.carbohydrate);
    this.vm.editPanel.protein = String(n.protein);
    this.vm.showEditPanel = true;
  }

  private applyEditFormToLabel(): void {
    const p = this.vm.editPanel;
    this.vm.foodLabel.foodName = p.foodName;
    const n = this.vm.foodLabel.nutrition;
    n.sodium = parseFloat(p.sodium) || 0;
    n.sugar = parseFloat(p.sugar) || 0;
    n.calories = parseFloat(p.calories) || 0;
    n.fat = parseFloat(p.fat) || 0;
    n.carbohydrate = parseFloat(p.carbohydrate) || 0;
    n.protein = parseFloat(p.protein) || 0;
    this.vm.showEditPanel = false;
    this.calculateScoreForCurrentLabel();
  }

  private async persistCurrentFoodLabel(showToast: boolean): Promise<void> {
    if (!this.vm.foodLabel.foodId || this.vm.foodLabel.foodId.length === 0) { return; }
    try {
      await this.appState.saveFoodLabel(this.vm.foodLabel);
      if (showToast) { ToastHelper.show(this.getUIContext(), '保存成功'); }
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, TAG, 'persistFoodLabel failed');
    }
  }

  private async saveDraft(): Promise<void> {
    try {
      await this.appState.saveFoodLabel(this.vm.foodLabel);
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveDraft failed');
    }
  }

  private viewReport(): void {
    if (this.vm.foodLabel.foodId.length > 0) {
      const navParams: Record<string, Object> = { 'foodId': this.vm.foodLabel.foodId } as Record<string, Object>;
      safePushUrl('pages/ReportPage', navParams);
    }
  }

  // ==================== UI ====================

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#1A1410', 0.0], ['#231C16', 0.5], ['#0F0C0A', 1.0]] };
    }
    return { angle: 180, colors: [['#FBF9F6', 0.0], ['#F7F4F0', 1.0]] };
  }

  private getGradeAccentColor(score: number): string {
    if (score >= 80) return SCORE_COLORS.GRADE_A;
    if (score >= 60) return SCORE_COLORS.GRADE_B;
    if (score >= 40) return SCORE_COLORS.GRADE_C;
    if (score >= 20) return SCORE_COLORS.GRADE_D;
    return SCORE_COLORS.GRADE_E;
  }

  private getGradeNumberColor(score: number): string {
    if (score >= 80) return '#43A047';
    if (score >= 60) return '#7CB342';
    if (score >= 40) return '#F9A825';
    if (score >= 20) return '#FF9800';
    return '#E53935';
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          // 渐变头部
          Row() {
            BackButton({ fontColor: COLORS.WHITE })
            Blank()
            if (this.vm.foodLabel.foodId.length > 0) {
              Row() {
                Text($r('app.string.barcode_detected'))
                  .fontSize(11)
                  .fontColor(COLORS.WHITE)
              }
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .backgroundColor(this.isDark ? '#1FFFFFFF' : '#33FFFFFF')
              .borderRadius(12)
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 56, bottom: 12 })
          .linearGradient({
            angle: 165,
            colors: [['#C56542', 0.0], ['#E07856', 0.5], ['#F2A78D', 1.0]]
          })
          .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 24, bottomRight: 24 })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

          ScanModeSelector({
            scanMode: this.vm.scanMode,
            onModeChange: (mode: string) => { this.vm.scanMode = mode; }
          })

          Row() {
            Button($r('app.string.scan_batch_scan'))
              .height(32)
              .fontSize(13)
              .backgroundColor(COLORS.BG_CARD)
              .fontColor(COLORS.PRIMARY)
              .borderRadius(RADIUS.LG)
              .padding({ left: 16, right: 16 })
              .accessibilityLevel('yes')
                .accessibilityText('批量扫描')
                .onClick(() => { HapticHelper.light(); this.showBatchScan = true; })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .padding({ right: SPACING.LG })
          .margin({ bottom: SPACING.SM })

          // 错误横幅
          if (this.vm.showErrorBanner) {
            Row() {
              Text(this.vm.lastError)
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.LEVEL_RED)
                .layoutWeight(1)
              Text('重试')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.PRIMARY)
                .accessibilityLevel('yes')
                .accessibilityText('重试扫描')
                .onClick(() => { HapticHelper.light(); this.vm.showErrorBanner = false; this.startRecognition(); })
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG, top: 8, bottom: 8 })
            .backgroundColor(COLORS.BG_WARM_ORANGE)
            .borderRadius(RADIUS.SM)
            .margin({ bottom: SPACING.SM })
          }

          // 扫描次数
          if ((this.appState.member?.memberStatus?.scansRemainingToday ?? -1) >= 0) {
            Row() {
              if (this.vm.scanLimitReached) {
                Text($r('app.string.scan_today_used_up'))
                  .fontSize(FONT_SIZE.SMALL).fontColor(COLORS.LEVEL_RED)
              } else {
                Text('今日剩余：' + this.vm.remainingScans.toString() + ' 次')
                  .fontSize(FONT_SIZE.SMALL).fontColor(COLORS.WARNING)
              }
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG })
            .margin({ bottom: SPACING.MD })
          }

          // 扫描结果卡片
          GlassCard({
            depth: GlassDepth.ELEVATED,
            radiusVal: RADIUS.XL,
            paddingVal: 0,
            marginVal: { left: SPACING.LG, right: SPACING.LG },
            glowColor: '#22E8826C',
            accentColor: this.vm.scoreReady ? this.getGradeAccentColor(this.vm.nutriScore) : ''
          }) {
            ScanResultCard({
              scanPhase: this.vm.scanPhase as ScanPhase,
              foodLabel: this.vm.foodLabel,
              scoreReady: this.vm.scoreReady,
              nutriScore: this.vm.nutriScore,
              detailLoading: this.vm.detailLoading,
              recognizedText: this.vm.recognizedText,
              recognitionHint: this.vm.recognitionHint,
              isOffline: this.vm.isOffline,
              frequentItems: this.vm.frequentItems,
              showEditPanel: this.vm.showEditPanel,
              onFrequentItemTap: (item: FoodLabel) => {
                this.vm.foodLabel = item;
                this.calculateScoreForCurrentLabel();
              }
            })
          }

          // 编辑面板
          if (this.vm.showEditPanel) {
            GlassCard({
              depth: GlassDepth.SURFACE,
              radiusVal: RADIUS.LG,
              paddingVal: 0,
              marginVal: { left: SPACING.LG, right: SPACING.LG, top: SPACING.SM }
            }) {
              ScanEditPanel({ editPanel: this.vm.editPanel })
            }
          }

          // 操作按钮
          Column() {
            if (this.vm.foodLabel.foodId.length === 0) {
              Button('扫码识别条码')
                .width('92%').height(56)
                .backgroundColor(COLORS.PRIMARY)
                .borderRadius(BUTTON.RADIUS_PRIMARY)
                .shadow(this.isDark ? { radius: 16, color: '#3369F0AE', offsetX: 0, offsetY: 4 } : { radius: 8, color: '#2243A047', offsetX: 0, offsetY: 2 })
                .accessibilityLevel('yes')
                .accessibilityText('开始扫描')
                .onClick(() => { HapticHelper.light(); this.startRecognition(); })

              Button('手动输入')
                .width('92%')
                .height(BUTTON.HEIGHT_MD)
                .backgroundColor(COLORS.BG_CARD)
                .fontColor(COLORS.PRIMARY)
                .borderRadius(RADIUS.FULL)
                .accessibilityLevel('yes')
                .accessibilityText('手动输入条码')
                .onClick(() => { HapticHelper.light(); this.startManualEntry(); })
                .margin({ top: SPACING.SM })
            }

            if (this.vm.foodLabel.foodId.length > 0) {
              Row() {
                if (!this.vm.showEditPanel) {
                  Button('编辑信息')
                    .layoutWeight(1).height(BUTTON.HEIGHT_MD)
                    .backgroundColor(COLORS.BG_CARD).fontColor(COLORS.PRIMARY)
                    .borderRadius(RADIUS.FULL)
                    .accessibilityLevel('yes')
                    .accessibilityText('编辑信息')
                    .onClick(() => { HapticHelper.light(); this.loadEditFormFromLabel(); })

                  Button('保存')
                    .layoutWeight(1).height(BUTTON.HEIGHT_MD)
                    .backgroundColor(COLORS.PRIMARY)
                    .borderRadius(RADIUS.FULL)
                    .margin({ left: SPACING.SM, right: SPACING.SM })
                    .accessibilityLevel('yes')
                    .accessibilityText('保存')
                    .onClick(() => { HapticHelper.light(); this.persistCurrentFoodLabel(true); })

                  Button('查看报告')
                    .layoutWeight(1).height(BUTTON.HEIGHT_MD)
                    .backgroundColor(COLORS.SUCCESS)
                    .borderRadius(RADIUS.FULL)
                    .accessibilityLevel('yes')
                    .accessibilityText('查看报告')
                    .onClick(() => { HapticHelper.light(); this.viewReport(); })
                }

                if (this.vm.showEditPanel) {
                  Button('保存编辑')
                    .layoutWeight(1).height(BUTTON.HEIGHT_MD)
                    .backgroundColor(COLORS.PRIMARY).borderRadius(RADIUS.FULL)
                    .margin({ right: SPACING.SM })
                    .accessibilityLevel('yes')
                    .accessibilityText('保存编辑')
                    .onClick(() => { HapticHelper.light(); this.applyEditFormToLabel(); })

                  Button('保存草稿')
                    .layoutWeight(1).height(BUTTON.HEIGHT_MD)
                    .backgroundColor(COLORS.BG_CARD).fontColor(COLORS.TEXT_SECONDARY)
                    .borderRadius(RADIUS.FULL)
                    .accessibilityLevel('yes')
                    .accessibilityText('保存草稿')
                    .onClick(() => { HapticHelper.light(); this.saveDraft(); })
                }
              }
              .width('92%')
              .margin({ top: SPACING.MD })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ bottom: SPACING.LG })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }
}

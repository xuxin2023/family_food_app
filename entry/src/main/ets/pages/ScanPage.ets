// ScanPage.ets
// 扫描页 - V2 体验升级版
// 六大体验升级：零点击自动扫码+振动音效、超时降级引导、加载状态动画、历史快捷入口、离线兜底、错误恢复与防崩溃
//
// 核心流程：
//   aboutToAppear
//     ├─ 检查网络状态 → 无网络时标记 offlineMode
//     ├─ 刷新扫描限额
//     ├─ 预加载高频商品
//     └─ 自动启动识别（零点击 + 振动反馈）
//
//   autoScanTimer (8秒超时)
//     ├─ 8秒内获得结果 → 振动提示 + 清除定时器
//     └─ 8秒无结果 → 降级到拍照 OCR 模式 + 提示
//
//   startRecognition
//     ├─ 付费墙检查 → paywallTrigger
//     ├─ 条码模式 → scanBarcode
//     ├─ 相机模式 → createCameraDraft
//     └─ 离线模式 → 纯本地规则引擎

import {
  ToastHelper, safePushUrl, getPageParams, FoodLabel, FamilyProfile, HealthSignal, Throttler, PaywallTrigger, TIER_DAILY_SCAN_LIMIT, COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON, SCAN_CONFIG, HILOG_DOMAIN_DEFAULT, EnhancedFoodRecommendation, AccessibilityUtil, TodayIntakeInput, DeviceAdapter, Breakpoint, PerformanceMonitor
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
import { ErrorBoundary } from '../components/ErrorBoundary';
import { ScanResultCard } from '../components/ScanResultCard';
import { ScanEditPanel } from '../components/ScanEditPanel';
import { ScanModeSelector } from '../components/ScanModeSelector';
import { AddToShoppingListButton } from '../components/AddToShoppingListButton';
import { FoodDeepAnalysisSheet } from '../components/FoodDeepAnalysisSheet';
import { BatchScanSheet } from '../components/BatchScanSheet';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const TAG = 'ScanPage';

// ==================== 加载阶段枚举 ====================

/**
 * 当前扫描所处的详细阶段
 * 用于在 ResultCard 中展示不同的视觉反馈
 */
enum ScanPhase {
  /** 空闲 - 尚未开始识别 */
  IDLE = 'idle',
  /** 正在扫码/OCR识别中 */
  RECOGNIZING = 'recognizing',
  /** 本地数据库查询中 */
  DB_QUERYING = 'db_querying',
  /** API远程查询中 */
  API_QUERYING = 'api_querying',
  /** 识别完成，评分计算中 */
  SCORING = 'scoring',
  /** 已完成 */
  DONE = 'done',
  /** 扫码超时 - 已降级到拍照 */
  TIMEOUT = 'timeout',
  /** 出错 */
  ERROR = 'error'
}

// 编辑面板数据模型 - 减少单页 @Local 变量数
class EditPanelData {
  foodName: string = ''
  sodium: string = '0'
  sugar: string = '0'
  calories: string = '0'
  fat: string = '0'
  carbohydrate: string = '0'
  protein: string = '0'
  ingredients: string = ''
  manufacturer: string = ''
  scNumber: string = ''
  principal: string = ''
  trustee: string = ''
}

@ObservedV2
class ScanViewModel {
  @Trace scanPhase: ScanPhase = ScanPhase.IDLE
  @Trace foodLabel: FoodLabel = new FoodLabel()
  @Trace showEditPanel: boolean = false
  @Trace scanLimitReached: boolean = false
  @Trace remainingScans: number = 3
  @Trace recognizedText: string = ''
  @Trace recognitionHint: ResourceStr = ''
  @Trace ocrConfidence: number = 1
  @Trace isOffline: boolean = false
  @Trace frequentItems: FoodLabel[] = []
  @Trace recentScans: FoodLabel[] = []
  @Trace scoreReady: boolean = false
  @Trace nutriScore: number = 50
  @Trace detailLoading: boolean = false
  @Trace showPaywallDialog: boolean = false
  @Trace paywallTrigger: PaywallTrigger | null = null
  @Trace editPanel: EditPanelData = new EditPanelData()
  @Trace retryCount: number = 0
  @Trace continuousMode: boolean = false
  @Trace batchResults: FoodLabel[] = []
  @Trace lastError: string = ''
  @Trace showErrorBanner: boolean = false
  @Trace isLoadingRetry: boolean = false
  @Trace permissionDenied: boolean = false
  @Trace showPermissionGuide: boolean = false
  @Trace currentBreakpoint: string = 'md'
  @Trace scanMode: string = 'camera'
}

@Entry
@ComponentV2
struct ScanPage {
  @Local vm: ScanViewModel = new ScanViewModel()
  @Local showDeepAnalysis: boolean = false
  @Local showBatchScan: boolean = false
  @Local hasPageError: boolean = false
  private memberId: string = ''
  private appState: AppState = AppState.getInstance()
  private foodInputService = this.appState.foodInput
  private batchScanService: BatchScanService = new BatchScanService()
  private autoScanTimer: number = -1
  private retryTimer: number = -1
  private scoreTimer: number = -1
  private componentActive: boolean = true
  private scanThrottler: Throttler = new Throttler(500)

  // ==================== 生命周期 ====================

  async aboutToAppear() {
    PerformanceMonitor.getInstance().pageEnter('ScanPage');
    try {
      const params = getPageParams();
      if (params !== undefined) {
        const mid = params.get('memberId');
        if (typeof mid === 'string') {
          this.memberId = mid;
        }
      }

      // 1. 检测网络状态
      await this.checkNetworkStatus()

      // 2. 刷新扫描限额
      this.refreshScanQuota()

      // 3. 异步预加载高频商品库 + 最近扫描记录
      this.loadFrequentItems()
      this.loadRecentScans()

      // 4. 零点击自动启动识别
      this.triggerAutoScan()
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
    }
  }

  async onPageShow() {
    // 扫码页面再次可见时，自动重置状态以便连续扫码
    if (this.vm.foodLabel.foodId.length > 0 && this.componentActive) {
      this.resetScan();
    }
  }

  /**
   * 重置扫码状态，以便连续扫码
   */
  private resetScan(): void {
    this.vm.foodLabel = new FoodLabel();
    this.vm.scanPhase = ScanPhase.IDLE;
    this.vm.scanMode = 'barcode';
    this.autoScanTimer = -1;
    this.retryTimer = -1;
    this.vm.recognitionHint = $r('app.string.first_time_hint');
  }

  aboutToDisappear(): void {
    PerformanceMonitor.getInstance().pageLeave('ScanPage');
    this.componentActive = false
    if (this.autoScanTimer !== -1) {
      try {
        clearTimeout(this.autoScanTimer)
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, 'ScanPage', 'clearTimeout autoScanTimer failed');
      }
      this.autoScanTimer = -1
    }
    if (this.retryTimer !== -1) {
      try {
        clearTimeout(this.retryTimer)
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, 'ScanPage', 'clearTimeout retryTimer failed');
      }
      this.retryTimer = -1
    }
    if (this.scoreTimer !== -1) {
      try {
        clearTimeout(this.scoreTimer)
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, 'ScanPage', 'clearTimeout scoreTimer failed');
      }
      this.scoreTimer = -1
    }
  }

  // ==================== 振动反馈工具方法 ====================

  /**
   * 触发短促成功振动（扫码成功时使用）
   */
  private vibrateSuccess(): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: SCAN_CONFIG.VIBRATE_SUCCESS_MS
      }, {
        id: 0,
        usage: 'physicalFeedback'
      }).then(() => {
        // 振动成功，无需额外处理
      }).catch((err: Error) => {
        hilog.warn(DOMAIN_ZERO, TAG, '振动失败: %{public}s', JSON.stringify(err));
      })
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, '触发振动异常: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 触发错误振动（扫码失败/超时时使用）
   */
  private vibrateError(): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: SCAN_CONFIG.VIBRATE_ERROR_MS
      }, {
        id: 0,
        usage: 'physicalFeedback'
      }).then(() => {
        // 振动成功
      }).catch((err: Error) => {
        hilog.warn(DOMAIN_ZERO, TAG, '错误振动失败: %{public}s', JSON.stringify(err));
      })
    } catch (err) {
      hilog.warn(DOMAIN_ZERO, TAG, '触发错误振动异常: %{public}s', JSON.stringify(err));
    }
  }

  // ==================== 错误恢复与防崩溃 ====================

  /**
   * 安全包装异步操作，自动重试并显示错误提示
   */
  private async safeExecute<T>(action: () => Promise<T>, errorMessage: string): Promise<T | null> {
    if (!this.componentActive) {
      return null
    }
    try {
      this.vm.showErrorBanner = false
      const result = await action()
      this.vm.retryCount = 0
      return result
    } catch (err) {
      const errMsg = `${errorMessage}: ${err}`
      hilog.error(DOMAIN_ZERO, TAG, errMsg)
      this.vm.lastError = errorMessage
      this.vm.retryCount++
      if (this.vm.retryCount <= SCAN_CONFIG.MAX_RETRY_COUNT && this.componentActive) {
        this.vm.showErrorBanner = true
        // 自动重试（记录定时器ID，以便在组件销毁时清理）
        this.retryTimer = setTimeout(() => {
          this.retryTimer = -1
          if (this.componentActive) {
            this.vm.isLoadingRetry = true
            this.safeExecute(action, errorMessage).then(() => {
              this.vm.isLoadingRetry = false
            })
          }
        }, SCAN_CONFIG.RETRY_INTERVAL_MS)
      } else {
        // 超出重试次数，显示永久错误提示
        this.vm.showErrorBanner = true
        ToastHelper.show(this.getUIContext(), $r('app.string.scan_please_retry_later', errorMessage))
      }
      return null
    }
  }

  /**
   * 检查网络连通性
   * 无网络时标记 isOffline = true，后续走纯本地流程
   */
  private async checkNetworkStatus(): Promise<void> {
    this.vm.isOffline = !this.appState.network.isOnline
  }

  // ==================== 零点击自动扫码 ====================

  /**
   * 自动触发扫码流程（零点击体验 - Yuka 风格）
   *
   * 规则：
   * - 已到达每日限额时不自动启动
   * - 启动后设置 8 秒超时定时器
   * - 超时未获得结果 → 降级提示 + 切换到拍照模式 + 错误振动
   */
  private triggerAutoScan() {
    if (this.vm.scanLimitReached) {
      return
    }

    // 启动识别（含振动反馈）
    this.startRecognition()
    this.vibrateSuccess()

    // 设置自动扫码超时定时器
    this.autoScanTimer = setTimeout(() => {
      if (this.vm.foodLabel.foodId.length === 0 && this.componentActive) {
        // 超时且未获得结果 → 降级
        this.vibrateError()
        ToastHelper.show(this.getUIContext(), $r('app.string.barcode_not_found'))
        this.vm.scanMode = 'camera'
        this.vm.scanPhase = ScanPhase.TIMEOUT
        this.vm.recognitionHint = $r('app.string.scan_manual_hint')
      }
    }, SCAN_CONFIG.AUTO_SCAN_TIMEOUT_MS)
  }

  // ==================== 数据预加载 ====================

  private async loadFrequentItems() {
    try {
      const records = await this.appState.getRecentScanHistory(50)
      const foodIds = new Set<string>()
      for (const record of records) {
        if (record.foodId) {
          foodIds.add(record.foodId)
        }
      }
      // 批量查询，避免N+1
      const foodMap = await this.appState.findFoodByIds(Array.from(foodIds))
      const items: FoodLabel[] = []
      for (const foodId of foodIds) {
        const foodLabel = foodMap.get(foodId)
        if (foodLabel && foodLabel.foodName.length > 0) {
          items.push(foodLabel)
          if (items.length >= 8) break
        }
      }
      this.vm.frequentItems = items
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, '预加载高频商品失败: %{public}s', JSON.stringify(error))
    }
  }

  /**
   * 加载最近 3 条扫描记录，用于快捷入口展示
   */
  private async loadRecentScans() {
    try {
      const records = await this.appState.getRecentScanHistory(SCAN_CONFIG.RECENT_SCAN_SHOW_COUNT)
      const foodIds = records.map(r => r.foodId).filter(id => id.length > 0)
      // 批量查询，避免N+1
      const foodMap = await this.appState.findFoodByIds(foodIds)
      const items: FoodLabel[] = []
      for (const record of records) {
        const foodLabel = foodMap.get(record.foodId)
        if (foodLabel && foodLabel.foodName.length > 0) {
          items.push(foodLabel)
        }
      }
      this.vm.recentScans = items
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, '加载最近扫描记录失败: %{public}s', JSON.stringify(error))
    }
  }

  // ==================== UI ====================

  build() {
    ErrorBoundary({
      fallbackMessage: $r('app.string.scan_page_load_failed'),
      onRetry: () => { this.aboutToAppear() },
      hasError: this.hasPageError,
      boundaryName: 'ScanPage'
    }) {
      Stack() {
      GridRow({
        columns: { sm: 4, md: 8, lg: 12 },
        breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] } as BreakPoints
      }) {
        GridCol({ span: { sm: 4, md: 8, lg: this.vm.showEditPanel ? 8 : 12 }, offset: { sm: 0, md: 0, lg: 0 } }) {
          Scroll() {
        Column() {
          // ---- 顶部导航栏 ----
          Row() {
            BackButton({ fontColor: COLORS.PRIMARY })
            Blank()
            if (this.vm.foodLabel.foodId.length > 0) {
              Text($r('app.string.barcode_detected')).fontSize(FONT_SIZE.TINY).fontColor(COLORS.ACCENT_GREEN)
            }
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.SM })

          ScanModeSelector({
            scanMode: this.vm.scanMode,
            onModeChange: (mode: string) => { this.vm.scanMode = mode }
          })

          Row() {
            Button($r('app.string.scan_batch_scan'))
              .height(32)
              .fontSize(13)
              .backgroundColor(COLORS.BG_CARD)
              .fontColor(COLORS.PRIMARY)
              .borderRadius(16)
              .padding({ left: 16, right: 16 })
              .onClick(() => { this.showBatchScan = true; })
              .accessibilityText($r('app.string.scan_batch_scan'))
              .accessibilityLevel('yes')
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
          .padding({ right: SPACING.LG })
          .margin({ bottom: SPACING.SM })

          // ---- 离线提示 ----
          if (this.vm.isOffline) {
            Row() {
              Text() { Span('📡 '); Span($r('app.string.offline_mode')) }
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.WARNING)
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG })
            .margin({ bottom: SPACING.MD })
          }

          // ---- 权限拒绝提示 ----
          if (this.vm.permissionDenied) {
            Row() {
              Text() { Span('📷 '); Span($r('app.string.scan_camera_permission_denied')) }
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.LEVEL_RED)
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG })
            .margin({ bottom: SPACING.MD })
          }

          // ---- 错误横幅 ----
          if (this.vm.showErrorBanner) {
            Row() {
              Text('⚠️')
                .fontSize(FONT_SIZE.SMALL)
                .margin({ right: 4 })
              Text(this.vm.lastError)
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.LEVEL_RED)
                .layoutWeight(1)
              if (this.vm.isLoadingRetry) {
                LoadingProgress().width(16).height(16).color(COLORS.PRIMARY)
              } else {
                Text($r('app.string.retry'))
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => {
                    this.vm.showErrorBanner = false
                    this.startRecognition()
                  })
              }
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG, top: 8, bottom: 8 })
            .backgroundColor('#FFF3E0')
            .margin({ bottom: SPACING.SM })
          }

          // ---- 扫描次数 ----
          if ((this.appState.member?.memberStatus?.scansRemainingToday ?? -1) >= 0) {
            Row() {
              if (this.vm.scanLimitReached) {
                Text($r('app.string.scan_today_used_up'))
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor(COLORS.LEVEL_RED)
              } else {
                Text() { Span($r('app.string.scan_today_remaining')); Span(`：${this.vm.remainingScans} `); Span($r('app.string.scan_times')) }
                  .fontSize(FONT_SIZE.SMALL)
                  .fontColor('#F57C00')
              }
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG })
            .margin({ bottom: SPACING.MD })
          }

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
              this.vm.foodLabel = item
              this.calculateScoreForCurrentLabel()
            }
          })
          .accessibilityRole('list')
          .accessibilityText(this.vm.foodLabel.foodId.length > 0 ?
            `${this.vm.foodLabel.foodName}，营养评分${this.vm.nutriScore}分` : '扫描结果列表')

          // ---- 连续扫描批量结果 ----
          if (this.vm.continuousMode && this.vm.batchResults.length > 0) {
            Column() {
              Text($r('app.string.scan_batch_count', this.vm.batchResults.length))
                .fontSize(FONT_SIZE.BODY_SM)
                .fontColor(COLORS.TEXT_SECONDARY)
                .margin({ bottom: SPACING.SM })

              Scroll() {
                Row() {
                  ForEach(this.vm.batchResults, (item: FoodLabel) => {
                    Column() {
                      Text(item.foodName)
                        .fontSize(FONT_SIZE.TINY)
                        .fontColor(COLORS.TEXT_PRIMARY)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width(72)
                    .height(40)
                    .padding(SPACING.XS)
                    .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
                    .borderRadius(RADIUS.SM)
                    .margin({ right: SPACING.SM })
                    .alignItems(HorizontalAlign.Center)
                    .justifyContent(FlexAlign.Center)
                  }, (item: FoodLabel) => item.foodId)
                }
              }
              .scrollBar(BarState.Off)
            }
            .width('92%')
            .padding(SPACING.MD)
            .backgroundColor(COLORS.BG_CARD)
            .borderRadius(RADIUS.LG)
            .margin({ bottom: SPACING.MD })
            .alignItems(HorizontalAlign.Start)
            .accessibilityText($r('app.string.scan_batch_count', this.vm.batchResults.length))
            .accessibilityLevel('yes')
          }

          // ---- 扫描历史快捷入口 ----
          if (this.vm.foodLabel.foodId.length === 0 && this.vm.recentScans.length > 0 &&
              this.vm.scanPhase !== ScanPhase.RECOGNIZING && !this.isRecognizing()) {
            this.RecentScanBar()
          }

          if (this.vm.showEditPanel) {
            ScanEditPanel({ editPanel: this.vm.editPanel })
          }

          Column() {
            if (this.vm.foodLabel.foodId.length === 0) {
              Button(this.vm.scanMode === 'barcode' ? $r('app.string.scan_mode_barcode') : $r('app.string.scan_mode_photo'))
                .width('90%')
                .height(52)
                .backgroundColor(COLORS.PRIMARY)
                .borderRadius(BUTTON.RADIUS_PRIMARY)
                .onClick(() => {
            if (this.vm.scanMode === 'barcode') {
              this.scanWithSystemKit()
            } else {
              this.startRecognition()
            }
          })
                .animation({ duration: 200, curve: curves.springMotion() })
                .accessibilityRole('button')
                .accessibilityText('扫描食品条码')
                .accessibilityDescription($r('app.string.scan_start_desc'))

              Button($r('app.string.scan_mode_manual'))
                .width('90%')
                .height(BUTTON.HEIGHT_MD)
                .backgroundColor(COLORS.BG_CARD)
                .fontColor(COLORS.PRIMARY)
                .borderRadius(BUTTON.RADIUS_MD)
                .margin({ top: 10 })
                .accessibilityText($r('app.string.scan_manual_input'))
                .accessibilityLevel('yes')
                .onClick(() => { this.startManualEntry() })
                .animation({ duration: 200, curve: curves.springMotion() })
            } else {
              Button($r('app.string.view_report'))
                .width('90%')
                .height(52)
                .backgroundColor(COLORS.ACCENT_GREEN)
                .borderRadius(BUTTON.RADIUS_PRIMARY)
                .accessibilityText($r('app.string.scan_view_report_desc'))
                .accessibilityLevel('yes')
                .onClick(() => { this.viewReport() })
                .animation({ duration: 300, curve: curves.springMotion() })

              AddToShoppingListButton({ foodLabel: this.vm.foodLabel })

              Button($r('app.string.scan_deep_analysis'))
                .layoutWeight(1)
                .height(BUTTON.HEIGHT_SECONDARY)
                .backgroundColor(COLORS.BG_CARD)
                .fontColor(COLORS.PRIMARY)
                .borderRadius(BUTTON.RADIUS_SECONDARY)
                .accessibilityText($r('app.string.scan_deep_analysis'))
                .accessibilityLevel('yes')
                .onClick(() => { this.showDeepAnalysis = true; })

              Row() {
                Button(this.vm.showEditPanel ? $r('app.string.edit_panel_collapse') : $r('app.string.edit_panel_toggle'))
                  .layoutWeight(1)
                  .height(BUTTON.HEIGHT_SECONDARY)
                  .backgroundColor(COLORS.BG_CARD)
                  .fontColor(COLORS.PRIMARY)
                  .borderRadius(BUTTON.RADIUS_SECONDARY)
                  .accessibilityText($r('app.string.scan_edit_panel_toggle_desc'))
                  .accessibilityLevel('yes')
                  .onClick(() => {
                    this.vm.showEditPanel = !this.vm.showEditPanel
                    if (this.vm.showEditPanel) {
                      this.loadEditFormFromLabel()
                    }
                  })
                  .animation({ duration: 200, curve: curves.springMotion() })

                Button($r('app.string.save_food_label'))
                  .layoutWeight(1)
                  .height(BUTTON.HEIGHT_SECONDARY)
                  .backgroundColor(COLORS.BG_WARM_ORANGE)
                  .fontColor(COLORS.ORANGE_DEEP)
                  .borderRadius(BUTTON.RADIUS_SECONDARY)
                  .margin({ left: 10 })
                  .accessibilityText($r('app.string.scan_save_label_desc'))
                  .accessibilityLevel('yes')
                  .onClick(() => { this.saveDraft() })
                  .animation({ duration: 200, curve: curves.springMotion() })
              }
              .width('90%')
              .margin({ top: 10 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')
        .backgroundColor(COLORS.BG_PAGE)
        .accessibilityGroup(true)
        .accessibilityDescription($r('app.string.scan_page_accessibility_desc'))
      }
      .width('100%')
      .height('100%')
        }

        if (this.vm.currentBreakpoint === 'lg' && this.vm.showEditPanel) {
          GridCol({ span: { sm: 0, md: 0, lg: 4 }, offset: { sm: 0, md: 0, lg: 0 } }) {
            Scroll() {
              ScanEditPanel({ editPanel: this.vm.editPanel })
            }
            .width('100%')
            .height('100%')
            .padding({ left: 8, right: 8, top: 16 })
          }
        }
      }
      .width('100%')
      .height('100%')
      .onBreakpointChange((bp: string) => { this.vm.currentBreakpoint = bp })

      // 付费墙弹窗（覆盖在内容之上）
      if (this.vm.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.vm.paywallTrigger,
          showDialog: this.vm.showPaywallDialog,
      onUpdateShowDialog: (val: boolean) => { this.vm.showPaywallDialog = val }
        })
      }

      if (this.vm.showPermissionGuide) {
        Column() {
          PermissionGuideDialog({
            permissionName: '',
            reason: '',
            onClose: () => { this.vm.showPermissionGuide = false }
          })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(0x66000000)
        .onClick(() => { this.vm.showPermissionGuide = false })
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.showDeepAnalysis, FoodDeepAnalysisSheet({
      foodLabel: this.vm.foodLabel,
      profile: this.appState.getAllMembersSync().length > 0 ? this.appState.getAllMembersSync()[0] : new FamilyProfile()
    }), { height: '70%', showClose: true, dragBar: true, onDisappear: () => { this.showDeepAnalysis = false } })
    .bindSheet(this.showBatchScan, BatchScanSheet(), { height: '80%', showClose: true, dragBar: true, onDisappear: () => { this.showBatchScan = false } })
    }
  }

  /**
   * 判断当前是否处于正在识别的阶段
   */
  private isRecognizing(): boolean {
    return this.vm.scanPhase === ScanPhase.RECOGNIZING ||
           this.vm.scanPhase === ScanPhase.DB_QUERYING ||
           this.vm.scanPhase === ScanPhase.API_QUERYING ||
           this.vm.scanPhase === ScanPhase.SCORING
  }



  // ==================== 最近扫描快捷入口 ====================

  @Builder
  RecentScanBar() {
    Column() {
      Text() { Span('⏱ '); Span($r('app.string.scan_recent_scans')) }
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ bottom: SPACING.SM })
      Scroll() {
        Row() {
          ForEach(this.vm.recentScans, (item: FoodLabel) => {
            Column() {
              Text(item.foodName)
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_PRIMARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .lineHeight(14)
                .textAlign(TextAlign.Center)
            }
            .width(72)
            .height(BUTTON.HEIGHT_MD)
            .padding(SPACING.XS)
            .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
            .borderRadius(RADIUS.SM)
            .margin({ right: SPACING.SM })
            .onClick(() => {
              this.vm.foodLabel = item
              this.calculateScoreForCurrentLabel()
            })
          }, (item: FoodLabel) => item.foodId)
        }
      }
      .scrollBar(BarState.Off)
      .margin({ bottom: SPACING.MD })
    }
    .width('92%')
  }

  // ==================== 评分计算 ====================

  private calculateScoreForCurrentLabel() {
    this.vm.scoreReady = false
    this.vm.detailLoading = true
    if (this.scoreTimer !== -1) clearTimeout(this.scoreTimer)
    this.scoreTimer = setTimeout(() => {
      this.scoreTimer = -1
      if (!this.componentActive) return
      this.vm.nutriScore = this.quickNutriScore(this.vm.foodLabel)
      this.vm.scoreReady = true
      this.vm.detailLoading = false
    }, 600)
  }

  private quickNutriScore(label: FoodLabel): number {
    const nutrition = label?.nutrition
    if (!nutrition) return 50
    let score = 50
    score -= Math.min(40, Math.floor((nutrition.sodium ?? 0) / 100) * 2)
    score -= Math.min(30, Math.floor((nutrition.sugar ?? 0) / 10) * 3)
    score -= Math.min(20, Math.floor((nutrition.fat ?? 0) / 10) * 2)
    score += Math.min(20, Math.floor((nutrition.protein ?? 0) / 5) * 2)
    score -= Math.min(20, Math.floor((nutrition.calories ?? 0) / 100))
    return Math.max(0, Math.min(100, score))
  }

  // ==================== 扫描限额 ====================

  // ==================== 系统 ScanKit 扫码（替代自定义扫码） ====================

  /**
   * 使用系统 @kit.ScanKit 原生扫码界面
   * 支持条码/二维码、相册识别、多码模式
   */
  private scanWithSystemKit(): void {
    if (this.vm.scanLimitReached) {
      ToastHelper.show(this.getUIContext(), $r('app.string.scan_today_used_up'))
      return
    }

    this.vm.scanPhase = ScanPhase.RECOGNIZING
    const options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableMultiMode: false,
        enableAlbum: true
      };

    try {
      const context = getContext(this) as common.UIAbilityContext
      scanBarcode.startScanForResult(context, options)
        .then((result: scanBarcode.ScanResult) => {
          if (!this.componentActive) return
          this.vibrateSuccess()
          this.vm.recognizedText = result.originalValue
          this.vm.scanPhase = ScanPhase.DB_QUERYING
          // 用扫码结果查询食品
          this.processScanResult(result.originalValue)
        })
        .catch((err: BusinessError) => {
          if (!this.componentActive) return
          hilog.warn(DOMAIN_ZERO, TAG, 'scanBarcode failed: %{public}s', err.message)
          this.vm.scanPhase = ScanPhase.IDLE
          if (err.code !== 1000500002) { // 非用户取消
            ToastHelper.show(this.getUIContext(), $r('app.string.scan_barcode_failed_retry'))
          }
        })
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'scanWithSystemKit: ' + JSON.stringify(e))
      this.vm.scanPhase = ScanPhase.IDLE
    }
  }

  /**
   * 校验条码格式（仅支持 EAN-8/12/13）
   */
  private isValidBarcodeFormat(barcode: string): boolean {
    if (/^[0-9]{8}$/.test(barcode)) return true;
    if (/^[0-9]{13}$/.test(barcode)) return true;
    if (/^[0-9]{12}$/.test(barcode)) {
      let sum = 0;
      for (let i = 0; i < 11; i++) {
        sum += parseInt(barcode[i]) * (i % 2 === 0 ? 3 : 1);
      }
      const checksum = (10 - (sum % 10)) % 10;
      return checksum === parseInt(barcode[11]);
    }
    if (barcode.startsWith('http') && (barcode.includes('openfoodfacts') || barcode.includes('foodscan'))) {
      return true;
    }
    return false;
  }

  /**
   * 处理扫码结果，查询食品信息
   */
  private async processScanResult(barcode: string): Promise<void> {
    let throttled = false;
    this.scanThrottler.run(() => { throttled = true; });
    if (!throttled) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Scan throttle: too frequent, skip');
      return;
    }

    // 条码格式校验
    if (!this.isValidBarcodeFormat(barcode)) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Invalid barcode format: len=%{public}d', barcode.length);
      ToastHelper.show(this.getUIContext(), $r('app.string.scan_unsupported_barcode'));
      this.vm.scanPhase = ScanPhase.IDLE;
      return;
    }

    try {
      this.vm.scanPhase = ScanPhase.DB_QUERYING
      const scanService = this.appState.scanService
      const lookupResult = await scanService.lookupByBarcodeChain(barcode)
      if (lookupResult.foodLabel && lookupResult.foodLabel.foodName.length > 0) {
        hilog.info(DOMAIN_ZERO, TAG, 'processScanResult: found via %{public}s, confidence=%{public}d',
          lookupResult.source, lookupResult.confidence)
        this.vm.foodLabel = lookupResult.foodLabel
        if (this.vm.isOffline && lookupResult.source !== 'barcode_scan') {
          this.vm.recognitionHint = $r('app.string.scan_offline_data_hint')
        }
        this.vm.scanPhase = ScanPhase.SCORING
        this.calculateScoreForCurrentLabel()
      } else {
        hilog.info(DOMAIN_ZERO, TAG, 'processScanResult: all levels miss for barcode %{public}s', barcode)
        ToastHelper.show(this.getUIContext(), $r('app.string.scan_barcode_not_found_manual'))
        this.vm.scanPhase = ScanPhase.IDLE
      }
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'processScanResult: ' + JSON.stringify(e))
      // 远程查询失败时尝试本地缓存降级
      try {
        const localFood = await this.appState.foodRepo.findByBarcode(barcode)
        if (localFood !== null) {
          this.vm.foodLabel = localFood
          this.vm.recognitionHint = $r('app.string.scan_offline_data_hint')
          this.vm.scanPhase = ScanPhase.SCORING
          this.calculateScoreForCurrentLabel()
          return
        }
      } catch (_e2) {
        hilog.warn(DOMAIN_ZERO, TAG, 'Offline fallback also failed')
      }
      // 降级路径：网络不可用时尝试端侧AI推理
      const onDeviceAi = this.appState.getOnDeviceAiEngine();
      if (onDeviceAi && ((onDeviceAi as Object as Record<string, Object>)['isAvailable']) !== undefined) {
        hilog.info(DOMAIN_ZERO, TAG, 'Attempting on-device AI inference fallback');
        // TODO: 当端侧模型可推理营养评分时，使用 onDeviceAi.inferNutritionScore(localData) 结果
      }
      this.vm.scanPhase = ScanPhase.IDLE
    }
  }

  private refreshScanQuota() {
    this.vm.scanLimitReached = false
    const remaining = this.appState.member.getRemainingScans()
    this.vm.remainingScans = remaining
    this.vm.scanLimitReached = remaining <= 0 && TIER_DAILY_SCAN_LIMIT[this.appState.member?.memberStatus?.tier ?? 'free'] !== -1
  }

  private async scanBatch(barcodes: string[]): Promise<void> {
    this.batchScanService.setRemoteProvider(this.appState.scanService as IRemoteLookupProvider);
    const results = await this.batchScanService.scanBatch(barcodes);
    const summary = this.batchScanService.getSummary();
    hilog.info(DOMAIN_ZERO, TAG, 'Batch scan: %{public}d/%{public}d hit, avg %{public}dms',
      summary.hit, summary.total, summary.avgTimeMs);
    if (results.length > 0 && results[0].foodLabel !== null) {
      this.vm.foodLabel = results[0].foodLabel;
      this.vm.scanPhase = ScanPhase.SCORING;
      this.calculateScoreForCurrentLabel();
    }
  }

  // ==================== 识别入口 ====================

  private startManualEntry() {
    this.applyFoodInputResult(this.foodInputService.createManualDraft() as Object as FoodInputResult)
  }

  private async startRecognition() {
    PerformanceMonitor.getInstance().startSpan('scan_result:recognition');
    // 清除自动超时定时器（以免超时提示在手动操作后出现）
    if (this.autoScanTimer >= 0) {
      try {
        clearTimeout(this.autoScanTimer)
      } catch (_e) {
        hilog.warn(DOMAIN_ZERO, 'ScanPage', 'clearTimeout autoScanTimer 2 failed');
      }
      this.autoScanTimer = -1
    }

    // 付费墙拦截
    const trigger = this.appState.member.useScan();
    if (trigger !== null) {
      const paywallTrigger = new PaywallTrigger();
    paywallTrigger.featureName = 'scan';
    this.vm.paywallTrigger = paywallTrigger;
      this.vm.showPaywallDialog = true;
      this.vm.scanLimitReached = true;
      return;
    }

    this.vm.scanPhase = ScanPhase.RECOGNIZING;
    try {
      // 检查并请求摄像头权限（扫码和拍照都需要）
      const hasCameraPermission = await this.appState.permission.requestCameraPermission();
      if (!hasCameraPermission) {
        this.vm.permissionDenied = true
        this.vm.showPermissionGuide = true
        this.vm.scanPhase = ScanPhase.ERROR
        return
      }
      this.vm.permissionDenied = false

      if (this.vm.scanMode === 'barcode') {
        const context = getContext(this) as common.Context
        const result = await this.foodInputService.scanBarcode(context)
        if (result) {
          this.vm.scanPhase = ScanPhase.DB_QUERYING
          this.applyFoodInputResult(result as Object as FoodInputResult)
        } else {
          ToastHelper.show(this.getUIContext(), $r('app.string.barcode_not_found'))
        }
      } else {
        // 拍照模式：直接生成草稿 + 提示后续手动修正
        this.vm.scanPhase = ScanPhase.DB_QUERYING
        this.applyFoodInputResult(this.foodInputService.createCameraDraft() as Object as FoodInputResult)
      }

      if (this.vm.foodLabel.foodId.length > 0) {
        this.vm.scanPhase = ScanPhase.SCORING
        this.calculateScoreForCurrentLabel()
        this.vm.scanPhase = ScanPhase.DONE
      }
    } catch (error) {
      this.vm.scanPhase = ScanPhase.ERROR
      ToastHelper.show(this.getUIContext(), $r('app.string.scan_recognition_failed_manual'))
      this.startManualEntry()
    } finally {
      this.refreshScanQuota()
    }
  }

  // ==================== 编辑表单 ====================

  private loadEditFormFromLabel() {
    this.vm.editPanel.foodName = this.vm.foodLabel?.foodName ?? ''
    const n = this.vm.foodLabel?.nutrition
    this.vm.editPanel.sodium = `${n?.sodium ?? 0}`
    this.vm.editPanel.sugar = `${n?.sugar ?? 0}`
    this.vm.editPanel.calories = `${n?.calories ?? 0}`
    this.vm.editPanel.fat = `${n?.fat ?? 0}`
    this.vm.editPanel.carbohydrate = `${n?.carbohydrate ?? 0}`
    this.vm.editPanel.protein = `${n?.protein ?? 0}`
    this.vm.editPanel.ingredients = (this.vm.foodLabel?.ingredients ?? []).join('\\n')
    this.vm.editPanel.manufacturer = this.vm.foodLabel?.manufacturer ?? ''
    this.vm.editPanel.scNumber = this.vm.foodLabel?.scNumber ?? ''
    this.vm.editPanel.principal = this.vm.foodLabel?.principal ?? ''
    this.vm.editPanel.trustee = this.vm.foodLabel?.trustee ?? ''
  }

  private applyEditFormToLabel() {
    if (this.vm.foodLabel.foodId.length === 0) {
      this.vm.foodLabel.foodId = `food_${Date.now()}`
    }
    if (this.vm.foodLabel.identifiedAt <= 0) {
      this.vm.foodLabel.identifiedAt = Date.now()
    }
    this.vm.foodLabel.foodName = this.vm.editPanel.foodName.trim()
    const n = this.vm.foodLabel.nutrition
    if (n) {
      n.sodium = this.parseNumber(this.vm.editPanel.sodium)
      n.sugar = this.parseNumber(this.vm.editPanel.sugar)
      n.calories = this.parseNumber(this.vm.editPanel.calories)
      n.fat = this.parseNumber(this.vm.editPanel.fat)
      n.carbohydrate = this.parseNumber(this.vm.editPanel.carbohydrate)
      n.protein = this.parseNumber(this.vm.editPanel.protein)
    }
    const parsedIngredients: string[] = this.vm.editPanel.ingredients
      .split(/\\r?\\n|,|，|、/)
      .map((item: string) => item.trim())
      .filter((item: string) => item.length > 0);
    this.vm.foodLabel.ingredients = parsedIngredients
    this.vm.foodLabel.manufacturer = this.vm.editPanel.manufacturer.trim()
    this.vm.foodLabel.scNumber = this.vm.editPanel.scNumber.trim()
    this.vm.foodLabel.principal = this.vm.editPanel.principal.trim()
    this.vm.foodLabel.trustee = this.vm.editPanel.trustee.trim()
  }

  private applyFoodInputResult(result: FoodInputResult) {
    PerformanceMonitor.getInstance().endSpan('scan_result:recognition');
    if (result.foodLabel instanceof FoodLabel) {
      this.vm.foodLabel = result.foodLabel
    }
    this.vm.recognizedText = result.recognizedText
    this.vm.recognitionHint = result.hint
    this.vm.ocrConfidence = result.confidence
    this.vm.showEditPanel = result.requiresManualReview
    if (this.vm.showEditPanel) {
      this.loadEditFormFromLabel()
    }
    if (this.vm.foodLabel.foodId.length > 0) {
      this.calculateScoreForCurrentLabel()
    }
  }

  private parseNumber(value: string): number {
    const result = Number.parseFloat(value)
    return Number.isFinite(result) ? result : 0
  }

  private async persistCurrentFoodLabel(showSuccessToast: boolean): Promise<boolean> {
    if (this.vm.showEditPanel) {
      this.applyEditFormToLabel()
    }
    if (this.vm.foodLabel.foodName.trim().length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.scan_complete_food_name_first'))
      return false
    }
    await this.appState.saveFoodLabel(this.vm.foodLabel)
    if (showSuccessToast) {
      ToastHelper.show(this.getUIContext(), $r('app.string.scan_food_label_saved'))
    }
    return true
  }

  private async saveDraft() {
    await this.persistCurrentFoodLabel(true)
  }

  private async viewReport() {
    const saved = await this.persistCurrentFoodLabel(false)
    if (!saved) {
      return
    }
    try {
      // 调用动态适配增强计算（集成 FoodAdapterEngine）
      const scanToday = this.appState.member.getTodayScanCount()
      const budget = this.appState.getDailyBudgetSync(this.memberId)
      const todayIntake = new TodayIntakeInput()
      todayIntake.sodium_mg = Math.max(0, (budget?.sodiumBudget ?? 0) - (budget?.sodiumRemaining ?? 0))
      todayIntake.sugar_g = Math.max(0, (budget?.sugarBudget ?? 0) - (budget?.sugarRemaining ?? 0))
      todayIntake.energy_kcal = Math.max(0, (budget?.calorieBudget ?? 0) - (budget?.calorieRemaining ?? 0))
      todayIntake.fat_g = Math.max(0, (budget?.fatBudget ?? 0) - (budget?.fatRemaining ?? 0))
      const members: FamilyProfile[] = this.appState.getAllMembersSync()
      const m: FamilyProfile = members.length > 0 ? members[0] : new FamilyProfile()
      const s: HealthSignal = this.appState.getHealthSignal(this.memberId)
      hilog.info(DOMAIN_ZERO, 'ScanPage', 'Viewing report for %{public}s', this.vm.foodLabel.foodName)
      const navParams = new Map<string, Object>();
      navParams.set('memberId', this.memberId);
      navParams.set('foodId', this.vm.foodLabel.foodId);
      safePushUrl('pages/ReportPage', navParams)
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, 'ScanPage', 'viewReport pushUrl failed');
    }
  }

}
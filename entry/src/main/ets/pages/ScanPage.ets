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

import { common } from '@kit.AbilityKit';
import { router, promptAction, curves } from '@kit.ArkUI';
import { connection } from '@kit.NetworkKit';
import { vibrator } from '@kit.SensorServiceKit';
import { FoodLabel } from '../model/FoodLabel';
import { AppState } from '../AppState';
import { FoodInputResult, FoodInputService } from '../service/FoodInputService';
import { PaywallTrigger } from '../model/MemberStatus';
import { NutriScoreBadge } from '../components/NutriScoreBadge';
import { PaywallDialog } from '../components/PaywallDialog';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';

/** 自动扫码超时时间（毫秒） */
const AUTO_SCAN_TIMEOUT_MS = 8000;

/** 最近扫描记录显示条数 */
const RECENT_SCAN_SHOW_COUNT = 3;

/** 扫码成功时振动时长（毫秒） */
const VIBRATE_SUCCESS_MS = 80;

/** 扫码失败/超时时振动时长（毫秒） */
const VIBRATE_ERROR_MS = 200;

/** 重试最大次数 */
const MAX_RETRY_COUNT = 2;

/** 防崩溃重试间隔（毫秒） */
const RETRY_INTERVAL_MS = 1500;

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

@Entry
@Component
struct ScanPage {
  // ---- 核心扫描状态 ----
  @State scanMode: string = 'camera'
  @State scanPhase: ScanPhase = ScanPhase.IDLE
  @State foodLabel: FoodLabel = new FoodLabel()
  @State showEditPanel: boolean = false
  @State scanLimitReached: boolean = false
  @State remainingScans: number = 3
  @State recognizedText: string = ''
  @State recognitionHint: string = ''
  @State ocrConfidence: number = 1
  @State isOffline: boolean = false

  // ---- 预加载与评分 ----
  @State frequentItems: FoodLabel[] = []
  @State recentScans: FoodLabel[] = []
  @State scoreReady: boolean = false
  @State nutriScore: number = 50
  @State detailLoading: boolean = false

  // ---- 付费墙 ----
  @State showPaywallDialog: boolean = false
  @State paywallTrigger: PaywallTrigger | null = null

  // ---- 编辑面板字段 ----
  @State editFoodName: string = ''
  @State editSodium: string = '0'
  @State editSugar: string = '0'
  @State editCalories: string = '0'
  @State editFat: string = '0'
  @State editCarbohydrate: string = '0'
  @State editProtein: string = '0'
  @State editIngredients: string = ''
  @State editManufacturer: string = ''
  @State editScNumber: string = ''
  @State editPrincipal: string = ''
  @State editTrustee: string = ''

  // ---- 体验升级：错误恢复与防崩溃 ----
  @State retryCount: number = 0
  @State lastError: string = ''
  @State showErrorBanner: boolean = false
  @State isLoadingRetry: boolean = false

  private memberId: string = ''
  private appState: AppState = AppState.getInstance()
  private foodInputService: FoodInputService = new FoodInputService()
  private autoScanTimer: number = -1
  private componentActive: boolean = true

  // ==================== 生命周期 ====================

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params) {
      this.memberId = params.memberId || ''
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
  }

  aboutToDisappear(): void {
    this.componentActive = false
    // 清理定时器，防止内存泄漏
    if (this.autoScanTimer !== -1) {
      try {
        clearTimeout(this.autoScanTimer)
      } catch (_e) {
        // ignore clearTimeout error
      }
      this.autoScanTimer = -1
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
        duration: VIBRATE_SUCCESS_MS
      }, {
        id: 0,
        usage: 'physicalFeedback'
      }).then(() => {
        // 振动成功，无需额外处理
      }).catch(() => {
        // 振动失败静默处理，不影响核心流程
      })
    } catch (err) {
      // 静默处理
    }
  }

  /**
   * 触发错误振动（扫码失败/超时时使用）
   */
  private vibrateError(): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: VIBRATE_ERROR_MS
      }, {
        id: 0,
        usage: 'physicalFeedback'
      }).then(() => {
        // 振动成功
      }).catch(() => {
        // 静默处理
      })
    } catch (err) {
      // 静默处理
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
      this.showErrorBanner = false
      const result = await action()
      this.retryCount = 0
      return result
    } catch (err) {
      const errMsg = `${errorMessage}: ${err}`
      console.error(errMsg)
      this.lastError = errorMessage
      this.retryCount++
      if (this.retryCount <= MAX_RETRY_COUNT && this.componentActive) {
        this.showErrorBanner = true
        // 自动重试
        setTimeout(() => {
          if (this.componentActive) {
            this.isLoadingRetry = true
            this.safeExecute(action, errorMessage).then(() => {
              this.isLoadingRetry = false
            })
          }
        }, RETRY_INTERVAL_MS)
      } else {
        // 超出重试次数，显示永久错误提示
        this.showErrorBanner = true
        promptAction.showToast({ message: errorMessage + '，请稍后重试' })
      }
      return null
    }
  }

  /**
   * 检查网络连通性
   * 无网络时标记 isOffline = true，后续走纯本地流程
   */
  private async checkNetworkStatus(): Promise<void> {
    try {
      const netHandle = connection.getDefaultNetSync()
      const caps = connection.getNetCapabilitiesSync(netHandle)
      const hasNet = caps.bearerTypes.length > 0
      this.isOffline = !hasNet
    } catch (err) {
      // 获取网络状态失败，保守地认为有网络
      this.isOffline = false
    }
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
    if (this.scanLimitReached) {
      return
    }

    // 启动识别（含振动反馈）
    this.startRecognition()
    this.vibrateSuccess()

    // 设置自动扫码超时定时器
    this.autoScanTimer = setTimeout(() => {
      if (this.foodLabel.foodId.length === 0 && this.componentActive) {
        // 超时且未获得结果 → 降级
        this.vibrateError()
        promptAction.showToast({ message: '未识别到条码，已切换到拍照模式' })
        this.scanMode = 'camera'
        this.scanPhase = ScanPhase.TIMEOUT
        this.recognitionHint = '尝试手动对准标签拍照，或手动录入'
      }
    }, AUTO_SCAN_TIMEOUT_MS)
  }

  // ==================== 数据预加载 ====================

  private async loadFrequentItems() {
    try {
      const records = await this.appState.getRecentScanHistory(50)
      const foodIds = new Set<string>()
      const items: FoodLabel[] = []
      for (const record of records) {
        const foodId = record.foodId
        if (foodId && !foodIds.has(foodId)) {
          foodIds.add(foodId)
          const foodLabel = await this.appState.findFoodById(foodId)
          if (foodLabel && foodLabel.foodName.length > 0) {
            items.push(foodLabel)
            if (items.length >= 8) break
          }
        }
      }
      this.frequentItems = items
    } catch (error) {
      console.warn('预加载高频商品失败', error)
    }
  }

  /**
   * 加载最近 3 条扫描记录，用于快捷入口展示
   */
  private async loadRecentScans() {
    try {
      const records = await this.appState.getRecentScanHistory(RECENT_SCAN_SHOW_COUNT)
      const items: FoodLabel[] = []
      for (const record of records) {
        const foodLabel = await this.appState.findFoodById(record.foodId)
        if (foodLabel && foodLabel.foodName.length > 0) {
          items.push(foodLabel)
        }
      }
      this.recentScans = items
    } catch (error) {
      console.warn('加载最近扫描记录失败', error)
    }
  }

  // ==================== UI ====================

  build() {
    Stack() {
      Scroll() {
        Column() {
          // ---- 顶部导航栏 ----
          Row() {
            Text('‹ 返回')
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.PRIMARY)
              .onClick(() => {
                try {
                  router.back()
                } catch (_e) {
                  // ignore router error
                }
              })
            Blank()
            if (this.foodLabel.foodId.length > 0) {
              Text('已识别').fontSize(FONT_SIZE.TINY).fontColor(COLORS.ACCENT_GREEN)
            }
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.SM })

          this.ModeSelector()

          // ---- 离线提示 ----
          if (this.isOffline) {
            Row() {
              Text('📡 当前无网络，使用本地识别')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.WARNING)
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG })
            .margin({ bottom: SPACING.MD })
          }

          // ---- 扫描次数 ----
          if (this.appState.memberStatus.scansRemainingToday >= 0) {
            Row() {
              Text(this.scanLimitReached ? '今日扫描次数已用完' : `今日剩余扫描：${this.remainingScans} 次`)
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(this.scanLimitReached ? COLORS.LEVEL_RED : '#F57C00')
            }
            .width('100%')
            .padding({ left: SPACING.LG, right: SPACING.LG })
            .margin({ bottom: SPACING.MD })
          }

          this.ResultCard()

          // ---- 扫描历史快捷入口 ----
          if (this.foodLabel.foodId.length === 0 && this.recentScans.length > 0 &&
              this.scanPhase !== ScanPhase.RECOGNIZING && !this.isRecognizing()) {
            this.RecentScanBar()
          }

          if (this.showEditPanel) {
            this.EditPanel()
          }

          Column() {
            if (this.foodLabel.foodId.length === 0) {
              Button(this.scanMode === 'barcode' ? '扫码录入' : '拍标签 / 生成草稿')
                .width('90%')
                .height(52)
                .backgroundColor(COLORS.PRIMARY)
                .borderRadius(BUTTON.RADIUS_PRIMARY)
                .onClick(() => { this.startRecognition() })
                .animation({ duration: 200, curve: curves.springMotion() })

              Button('手动录入')
                .width('90%')
                .height(BUTTON.HEIGHT_MD)
                .backgroundColor(COLORS.BG_CARD)
                .fontColor(COLORS.PRIMARY)
                .borderRadius(BUTTON.RADIUS_MD)
                .margin({ top: 10 })
                .onClick(() => { this.startManualEntry() })
                .animation({ duration: 200, curve: curves.springMotion() })
            } else {
              Button('查看适配报告')
                .width('90%')
                .height(52)
                .backgroundColor(COLORS.ACCENT_GREEN)
                .borderRadius(BUTTON.RADIUS_PRIMARY)
                .onClick(() => { this.viewReport() })
                .animation({ duration: 300, curve: curves.springMotion() })

              Row() {
                Button(this.showEditPanel ? '收起修正面板' : '手动修正')
                  .layoutWeight(1)
                  .height(BUTTON.HEIGHT_SECONDARY)
                  .backgroundColor(COLORS.BG_CARD)
                  .fontColor(COLORS.PRIMARY)
                  .borderRadius(BUTTON.RADIUS_SECONDARY)
                  .onClick(() => {
                    this.showEditPanel = !this.showEditPanel
                    if (this.showEditPanel) {
                      this.loadEditFormFromLabel()
                    }
                  })
                  .animation({ duration: 200, curve: curves.springMotion() })

                Button('保存 FoodLabel')
                  .layoutWeight(1)
                  .height(BUTTON.HEIGHT_SECONDARY)
                  .backgroundColor(COLORS.BG_WARM_ORANGE)
                  .fontColor(COLORS.ORANGE_DEEP)
                  .borderRadius(BUTTON.RADIUS_SECONDARY)
                  .margin({ left: 10 })
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
      }
      .width('100%')
      .height('100%')

      // 付费墙弹窗（覆盖在内容之上）
      if (this.paywallTrigger !== null) {
        PaywallDialog({
          trigger: this.paywallTrigger,
          showDialog: $showPaywallDialog
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 判断当前是否处于正在识别的阶段
   */
  private isRecognizing(): boolean {
    return this.scanPhase === ScanPhase.RECOGNIZING ||
           this.scanPhase === ScanPhase.DB_QUERYING ||
           this.scanPhase === ScanPhase.API_QUERYING ||
           this.scanPhase === ScanPhase.SCORING
  }

  // ==================== 模式选择器 ====================

  @Builder
  ModeSelector() {
    Row() {
      Text('拍标签')
        .fontSize(15)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .borderRadius(BUTTON.RADIUS_SMALL)
        .backgroundColor(this.scanMode === 'camera' ? COLORS.PRIMARY : COLORS.WHITE)
        .fontColor(this.scanMode === 'camera' ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
        .onClick(() => {
          this.scanMode = 'camera'
          // 清除超时状态提示
          if (this.scanPhase === ScanPhase.TIMEOUT) {
            this.scanPhase = ScanPhase.IDLE
          }
        })

      Text('扫码')
        .fontSize(15)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .borderRadius(BUTTON.RADIUS_SMALL)
        .backgroundColor(this.scanMode === 'barcode' ? COLORS.PRIMARY : COLORS.WHITE)
        .fontColor(this.scanMode === 'barcode' ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
        .margin({ left: 10 })
        .onClick(() => { this.scanMode = 'barcode' })
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG })
    .margin({ bottom: SPACING.MD })
  }

  // ==================== 最近扫描快捷入口 ====================

  @Builder
  RecentScanBar() {
    Column() {
      Text('⏱ 最近扫描')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ bottom: SPACING.SM })
      Scroll() {
        Row() {
          ForEach(this.recentScans, (item: FoodLabel) => {
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
              this.foodLabel = item
              this.calculateScoreForCurrentLabel()
            })
          }, (item: FoodLabel) => item.foodId)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .margin({ bottom: SPACING.MD })
    }
    .width('92%')
  }

  // ==================== 结果卡片（多态加载状态） ====================

  @Builder
  ResultCard() {
    Column() {
      if (this.isRecognizing()) {
        // ── 正在识别中：按阶段显示不同状态（渐变过渡）──
        if (this.scanPhase === ScanPhase.RECOGNIZING) {
          Column() {
            LoadingProgress()
              .width(48)
              .height(BUTTON.HEIGHT_MD)
              .color(COLORS.ACCENT_BLUE)
            Text('正在扫描条码…')
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.MD })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(140)
          .transition(TransitionEffect.opacity(1))
        } else if (this.scanPhase === ScanPhase.DB_QUERYING) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(COLORS.ACCENT_GREEN)
            Text('正在查询本地数据库…')
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.MD })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(100)
          .transition(TransitionEffect.opacity(1))
        } else if (this.scanPhase === ScanPhase.API_QUERYING) {
          Column() {
            LoadingProgress()
              .width(36)
              .height(36)
              .color(COLORS.ACCENT_PURPLE)
            Text('正在查询远程营养数据…')
              .fontSize(FONT_SIZE.BODY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.MD })
            if (this.isOffline) {
              Text('（离线模式，仅使用本地数据）')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.WARNING)
                .margin({ top: SPACING.XS })
            }
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(120)
          .transition(TransitionEffect.opacity(1))
        } else if (this.scanPhase === ScanPhase.SCORING) {
          Column() {
            LoadingProgress()
              .width(32)
              .height(32)
              .color(COLORS.ACCENT_GREEN)
            Text('正在评估营养评分…')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: SPACING.SM, bottom: SPACING.MD })
          }
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(80)
          .transition(TransitionEffect.opacity(1))
        }
      } else if (this.foodLabel.foodId.length === 0) {
        // ── 未识别：显示高频商品快速入口 ──
        if (this.frequentItems.length > 0) {
          Text('🔥 快速选择历史商品')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ bottom: SPACING.SM })
          Scroll() {
            Row() {
              ForEach(this.frequentItems, (item: FoodLabel) => {
                Column() {
                  Text(item.foodName)
                    .fontSize(FONT_SIZE.TINY)
                    .fontColor(COLORS.TEXT_PRIMARY)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .lineHeight(14)
                    .textAlign(TextAlign.Center)
                }
                .width(72)
                .height(60)
                .padding(SPACING.XS)
                .backgroundColor(COLORS.BG_CARD_HIGHLIGHT)
                .borderRadius(RADIUS.SM)
                .margin({ right: SPACING.SM })
                .onClick(() => {
                  this.foodLabel = item
                  this.calculateScoreForCurrentLabel()
                })
              }, (item: FoodLabel) => item.foodId)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .margin({ bottom: SPACING.MD })
        }

        // 超时降级提示
        if (this.scanPhase === ScanPhase.TIMEOUT) {
          Column() {
            Text('⏰ 扫码超时')
              .fontSize(15)
              .fontColor(COLORS.LEVEL_ORANGE)
              .fontWeight(FONT_WEIGHT.BOLD)
            Text('请对准条码或切换使用拍照模式')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 4 })
          }
          .margin({ bottom: SPACING.MD })
        }

        Text('识别后会在这里生成一个可编辑的 FoodLabel 草稿')
          .fontSize(15)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
        Text('P0 版支持扫码命中本地库，或先生成草稿后手动修正')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
          .margin({ top: SPACING.SM })
      } else {
        // ── 识别完成：先展示评分徽章，再异步加载详情 ──
        if (this.scoreReady) {
          NutriScoreBadge({
            score: this.nutriScore,
            diameter: 120,
            animating: true
          })
          .margin({ bottom: SPACING.MD })
        } else if (this.detailLoading) {
          LoadingProgress()
            .width(32)
            .height(32)
            .color(COLORS.ACCENT_GREEN)
          Text('正在评估营养评分...')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: SPACING.SM, bottom: SPACING.MD })
        }

        Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : '待补充食品名称')
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .margin({ bottom: SPACING.SM })

        if (this.recognitionHint.length > 0) {
          Text(this.recognitionHint)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.PRIMARY)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 6 })
        }

        if (this.recognizedText.length > 0) {
          Text(this.recognizedText)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_TERTIARY)
            .textAlign(TextAlign.Center)
            .margin({ bottom: SPACING.SM })
        }

        Row() {
          this.MetricChip('钠', `${this.foodLabel.nutrition.sodium} mg`)
          this.MetricChip('糖', `${this.foodLabel.nutrition.sugar} g`)
          this.MetricChip('热量', `${this.foodLabel.nutrition.calories} kcal`)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ bottom: SPACING.SM })

        if (this.foodLabel.barcode.length > 0) {
          Text(`条码：${this.foodLabel.barcode}`)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ bottom: 6 })
        }

        Text(this.showEditPanel ? '请核对下方字段后保存或查看报告' : '如信息不完整，可展开手动修正面板补全')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
      }
    }
    .width('92%')
    .padding(20)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MetricChip(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_TERTIARY)
      Text(value)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLORS.TEXT_GRAY_2121)
        .margin({ top: 2 })
    }
    .padding(8)
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(10)
  }

  // ==================== 评分计算 ====================

  private calculateScoreForCurrentLabel() {
    this.scoreReady = false
    this.detailLoading = true
    setTimeout(() => {
      this.nutriScore = this.quickNutriScore(this.foodLabel)
      this.scoreReady = true
      this.detailLoading = false
    }, 600)
  }

  private quickNutriScore(label: FoodLabel): number {
    const nutrition = label.nutrition
    let score = 50
    score -= Math.min(40, Math.floor(nutrition.sodium / 100) * 2)
    score -= Math.min(30, Math.floor(nutrition.sugar / 10) * 3)
    score -= Math.min(20, Math.floor(nutrition.fat / 10) * 2)
    score += Math.min(20, Math.floor(nutrition.protein / 5) * 2)
    score -= Math.min(20, Math.floor(nutrition.calories / 100))
    return Math.max(0, Math.min(100, score))
  }

  // ==================== 编辑面板 ====================

  @Builder
  EditPanel() {
    Column() {
      Text('手动修正')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: SPACING.MD })

      this.FormInput('食品名称', this.editFoodName, '输入食品名称', (value: string) => { this.editFoodName = value })
      this.FormInput('钠（mg/100g）', this.editSodium, '0', (value: string) => { this.editSodium = value })
      this.FormInput('糖（g/100g）', this.editSugar, '0', (value: string) => { this.editSugar = value })
      this.FormInput('热量（kcal/100g）', this.editCalories, '0', (value: string) => { this.editCalories = value })
      this.FormInput('脂肪（g/100g）', this.editFat, '0', (value: string) => { this.editFat = value })
      this.FormInput('碳水（g/100g）', this.editCarbohydrate, '0', (value: string) => { this.editCarbohydrate = value })
      this.FormInput('蛋白质（g/100g）', this.editProtein, '0', (value: string) => { this.editProtein = value })

      Column() {
        Text('配料')
          .fontSize(13)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ bottom: 6 })
        TextArea({ text: this.editIngredients, placeholder: '一行一个，或用逗号分隔' })
          .width('100%')
          .height(100)
          .padding(10)
          .backgroundColor(COLORS.BG_PAGE_LIGHT)
          .borderRadius(12)
          .onChange((value: string) => { this.editIngredients = value })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: SPACING.MD })

      this.FormInput('生产商', this.editManufacturer, '输入生产商', (value: string) => { this.editManufacturer = value })
      this.FormInput('SC 编号', this.editScNumber, '输入 SC 编号', (value: string) => { this.editScNumber = value })
      this.FormInput('委托方', this.editPrincipal, '输入委托方', (value: string) => { this.editPrincipal = value })
      this.FormInput('受托方', this.editTrustee, '输入受托方', (value: string) => { this.editTrustee = value })
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FormInput(title: string, value: string, placeholder: string, onChange: (value: string) => void) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ bottom: 6 })
      TextInput({ text: value, placeholder })
        .width('100%')
        .height(BUTTON.HEIGHT_SECONDARY)
        .padding({ left: 12, right: 12 })
        .backgroundColor(COLORS.BG_PAGE_LIGHT)
        .borderRadius(12)
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: SPACING.MD })
  }

  // ==================== 扫描限额 ====================

  private refreshScanQuota() {
    this.scanLimitReached = false
    const status = this.appState.memberStatus
    this.remainingScans = status.scansRemainingToday === -1 ? 999 : status.scansRemainingToday
  }

  // ==================== 识别入口 ====================

  private startManualEntry() {
    this.applyFoodInputResult(this.foodInputService.createManualDraft())
  }

  private async startRecognition() {
    // 清除自动超时定时器（以免超时提示在手动操作后出现）
    if (this.autoScanTimer >= 0) {
      try {
        clearTimeout(this.autoScanTimer)
      } catch (_e) {
        // ignore clearTimeout error
      }
      this.autoScanTimer = -1
    }

    // 付费墙拦截
    const trigger = this.appState.useScan();
    if (trigger !== null) {
      this.paywallTrigger = trigger;
      this.showPaywallDialog = true;
      this.scanLimitReached = true;
      return;
    }

    this.scanPhase = ScanPhase.RECOGNIZING;
    try {
      if (this.scanMode === 'barcode') {
        const context = getContext(this) as common.Context
        const result = await this.foodInputService.scanBarcode(context)
        if (result) {
          this.scanPhase = ScanPhase.DB_QUERYING
          this.applyFoodInputResult(result)
        }
      } else {
        // 拍照模式：直接生成草稿 + 提示后续手动修正
        this.scanPhase = ScanPhase.DB_QUERYING
        this.applyFoodInputResult(this.foodInputService.createCameraDraft())
      }

      if (this.foodLabel.foodId.length > 0) {
        this.scanPhase = ScanPhase.SCORING
        this.calculateScoreForCurrentLabel()
        this.scanPhase = ScanPhase.DONE
      }
    } catch (error) {
      this.scanPhase = ScanPhase.ERROR
      promptAction.showToast({ message: '识别失败，已切换到手动录入' })
      this.startManualEntry()
    } finally {
      this.refreshScanQuota()
    }
  }

  // ==================== 编辑表单 ====================

  private loadEditFormFromLabel() {
    this.editFoodName = this.foodLabel.foodName
    this.editSodium = `${this.foodLabel.nutrition.sodium}`
    this.editSugar = `${this.foodLabel.nutrition.sugar}`
    this.editCalories = `${this.foodLabel.nutrition.calories}`
    this.editFat = `${this.foodLabel.nutrition.fat}`
    this.editCarbohydrate = `${this.foodLabel.nutrition.carbohydrate}`
    this.editProtein = `${this.foodLabel.nutrition.protein}`
    this.editIngredients = this.foodLabel.ingredients.join('\\n')
    this.editManufacturer = this.foodLabel.manufacturer
    this.editScNumber = this.foodLabel.scNumber
    this.editPrincipal = this.foodLabel.principal
    this.editTrustee = this.foodLabel.trustee
  }

  private applyEditFormToLabel() {
    if (this.foodLabel.foodId.length === 0) {
      this.foodLabel.foodId = `food_${Date.now()}`
    }
    if (this.foodLabel.identifiedAt <= 0) {
      this.foodLabel.identifiedAt = Date.now()
    }
    this.foodLabel.foodName = this.editFoodName.trim()
    this.foodLabel.nutrition.sodium = this.parseNumber(this.editSodium)
    this.foodLabel.nutrition.sugar = this.parseNumber(this.editSugar)
    this.foodLabel.nutrition.calories = this.parseNumber(this.editCalories)
    this.foodLabel.nutrition.fat = this.parseNumber(this.editFat)
    this.foodLabel.nutrition.carbohydrate = this.parseNumber(this.editCarbohydrate)
    this.foodLabel.nutrition.protein = this.parseNumber(this.editProtein)
    this.foodLabel.ingredients = this.editIngredients
      .split(/\\r?\\n|,|，|、/)
      .map(item => item.trim())
      .filter(item => item.length > 0)
    this.foodLabel.manufacturer = this.editManufacturer.trim()
    this.foodLabel.scNumber = this.editScNumber.trim()
    this.foodLabel.principal = this.editPrincipal.trim()
    this.foodLabel.trustee = this.editTrustee.trim()
  }

  private applyFoodInputResult(result: FoodInputResult) {
    this.foodLabel = result.foodLabel
    this.recognizedText = result.recognizedText
    this.recognitionHint = result.hint
    this.ocrConfidence = result.confidence
    this.showEditPanel = result.requiresManualReview
    if (this.showEditPanel) {
      this.loadEditFormFromLabel()
    }
    if (this.foodLabel.foodId.length > 0) {
      this.calculateScoreForCurrentLabel()
    }
  }

  private parseNumber(value: string): number {
    const result = Number.parseFloat(value)
    return Number.isFinite(result) ? result : 0
  }

  private async persistCurrentFoodLabel(showSuccessToast: boolean): Promise<boolean> {
    if (this.showEditPanel) {
      this.applyEditFormToLabel()
    }
    if (this.foodLabel.foodName.trim().length === 0) {
      promptAction.showToast({ message: '请先补全食品名称' })
      return false
    }
    await this.appState.saveFoodLabel(this.foodLabel)
    if (showSuccessToast) {
      promptAction.showToast({ message: 'FoodLabel 已保存' })
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
      router.pushUrl({
        url: 'pages/ReportPage',
        params: {
          memberId: this.memberId,
          foodId: this.foodLabel.foodId
        }
      })
    } catch (_e) {
      // ignore router.pushUrl error
    }
  }
}

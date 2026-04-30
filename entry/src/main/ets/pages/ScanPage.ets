import { common } from '@kit.AbilityKit';
import { router, promptAction } from '@kit.ArkUI';
import { FoodLabel } from '../model/FoodLabel';
import { AppState } from '../AppState';
import { FoodInputResult, FoodInputService } from '../service/FoodInputService';
import { SubscriptionTier } from '../model/PricingModel';
import { NutriScoreBadge } from '../components/NutriScoreBadge';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from '../constants/AppTheme';

@Entry
@Component
struct ScanPage {
  @State scanMode: string = 'camera'
  @State foodLabel: FoodLabel = new FoodLabel()
  @State isRecognizing: boolean = false
  @State showEditPanel: boolean = false
  @State scanLimitReached: boolean = false
  @State remainingScans: number = 3
  @State recognizedText: string = ''
  @State recognitionHint: string = ''
  @State ocrConfidence: number = 1

  // 预加载数据
  @State frequentItems: FoodLabel[] = []
  @State scoreReady: boolean = false       // 评分是否已计算完成
  @State nutriScore: number = 50           // 当前食品的评分
  @State detailLoading: boolean = false    // 详细分析是否正在加载

  // 编辑面板字段
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

  private memberId: string = ''
  private appState: AppState = AppState.getInstance()
  private foodInputService: FoodInputService = new FoodInputService()

  async aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params) {
      this.memberId = params.memberId || ''
    }
    this.refreshScanQuota()
    // 异步预加载高频商品库
    this.loadFrequentItems()
  }

  private async loadFrequentItems() {
    try {
      const records = await this.appState.getRecentScanHistory(50)
      // 从扫描历史中提取高频商品
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
      // 预加载失败不影响主流程
      console.warn('预加载高频商品失败', error)
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => { router.back() })
          Text('识别食品标签')
            .fontSize(FONT_SIZE.TITLE)
            .fontWeight(FONT_WEIGHT.BOLD)
            .margin({ left: SPACING.LG })
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.LG })

        this.ModeSelector()

        if (this.appState.getCurrentTier() === SubscriptionTier.FREE) {
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

        if (this.showEditPanel) {
          this.EditPanel()
        }

        Column() {
          if (this.foodLabel.foodId.length === 0) {
            Button(this.scanMode === 'barcode' ? '扫码录入' : '拍标签 / 生成草稿')
              .width('90%')
              .height(52)
              .backgroundColor(COLORS.PRIMARY)
              .borderRadius(26)
              .onClick(() => { this.startRecognition() })

            Button('手动录入')
              .width('90%')
              .height(48)
              .backgroundColor(COLORS.BG_CARD)
              .fontColor(COLORS.PRIMARY)
              .borderRadius(24)
              .margin({ top: 10 })
              .onClick(() => { this.startManualEntry() })
          } else {
            Button('查看适配报告')
              .width('90%')
              .height(52)
              .backgroundColor(COLORS.ACCENT_GREEN)
              .borderRadius(26)
              .onClick(() => { this.viewReport() })

            Row() {
              Button(this.showEditPanel ? '收起修正面板' : '手动修正')
                .layoutWeight(1)
                .height(46)
                .backgroundColor(COLORS.BG_CARD)
                .fontColor(COLORS.PRIMARY)
                .borderRadius(23)
                .onClick(() => {
                  this.showEditPanel = !this.showEditPanel
                  if (this.showEditPanel) {
                    this.loadEditFormFromLabel()
                  }
                })

              Button('保存 FoodLabel')
                .layoutWeight(1)
                .height(46)
                .backgroundColor('#FFF3E0')
                .fontColor('#EF6C00')
                .borderRadius(23)
                .margin({ left: 10 })
                .onClick(() => { this.saveDraft() })
            }
            .width('90%')
            .margin({ top: 10 })
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: SPACING.LG, bottom: SPACING.XL })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  ModeSelector() {
    Row() {
      Text('拍标签')
        .fontSize(15)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor(this.scanMode === 'camera' ? COLORS.PRIMARY : COLORS.WHITE)
        .fontColor(this.scanMode === 'camera' ? COLORS.WHITE : '#212121')
        .onClick(() => { this.scanMode = 'camera' })

      Text('扫码')
        .fontSize(15)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor(this.scanMode === 'barcode' ? COLORS.PRIMARY : COLORS.WHITE)
        .fontColor(this.scanMode === 'barcode' ? COLORS.WHITE : '#212121')
        .margin({ left: 10 })
        .onClick(() => { this.scanMode = 'barcode' })
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG })
    .margin({ bottom: SPACING.MD })
  }

  @Builder
  ResultCard() {
    Column() {
      if (this.isRecognizing) {
        // 识别中：显示加载状态+评分徽章骨架
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color(COLORS.PRIMARY)
          Text('正在处理中...')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: SPACING.MD })
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .width('100%')
        .height(this.scoreReady ? 'auto' : 140)
      } else if (this.foodLabel.foodId.length === 0) {
        // 未识别：显示提示+高频商品快速入口
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
                  // 进入后自动计算评分
                  this.calculateScoreForCurrentLabel()
                })
              }, (item: FoodLabel) => item.foodId)
            }
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
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
        // 识别完成：先展示评分徽章，再异步加载详情
        if (this.scoreReady) {
          // 评分徽章区域
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
        .fontColor('#212121')
        .margin({ top: 2 })
    }
    .padding(8)
    .backgroundColor('#F5F5F5')
    .borderRadius(10)
  }

  /**
   * 基于当前食品标签快速计算评分
   */
  private calculateScoreForCurrentLabel() {
    this.scoreReady = false
    this.detailLoading = true
    // 异步计算评分
    setTimeout(() => {
      this.nutriScore = this.quickNutriScore(this.foodLabel)
      this.scoreReady = true
      this.detailLoading = false
    }, 600) // 模拟异步加载，展示过渡效果
  }

  /**
   * 快速营养评分（本地简化版）
   */
  private quickNutriScore(label: FoodLabel): number {
    const nutrition = label.nutrition
    let score = 50
    // 钠扣分 (每100mg扣2分)
    score -= Math.min(40, Math.floor(nutrition.sodium / 100) * 2)
    // 糖扣分 (每10g扣3分)
    score -= Math.min(30, Math.floor(nutrition.sugar / 10) * 3)
    // 脂肪扣分 (每10g扣2分)
    score -= Math.min(20, Math.floor(nutrition.fat / 10) * 2)
    // 蛋白质加分 (每5g加2分)
    score += Math.min(20, Math.floor(nutrition.protein / 5) * 2)
    // 热量扣分 (每100kcal扣1分)
    score -= Math.min(20, Math.floor(nutrition.calories / 100))
    return Math.max(0, Math.min(100, score))
  }

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
          .backgroundColor('#F7F8FA')
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
        .height(44)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#F7F8FA')
        .borderRadius(12)
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: SPACING.MD })
  }

  private refreshScanQuota() {
    this.scanLimitReached = !this.appState.canScanToday()
    const remaining = this.appState.getRemainingScansToday()
    this.remainingScans = remaining === -1 ? 999 : remaining
  }

  private startManualEntry() {
    this.applyFoodInputResult(this.foodInputService.createManualDraft())
  }

  private async startRecognition() {
    if (!this.appState.canScanToday()) {
      this.scanLimitReached = true
      promptAction.showToast({ message: '今日扫描次数已用完' })
      return
    }

    this.isRecognizing = true
    try {
      if (this.scanMode === 'barcode') {
        const context = getContext(this) as common.Context
        const result = await this.foodInputService.scanBarcode(context)
        if (result) {
          this.applyFoodInputResult(result)
        }
      } else {
        this.applyFoodInputResult(this.foodInputService.createCameraDraft())
      }

      if (this.foodLabel.foodId.length > 0) {
        this.appState.recordScan()
        // 识别完成后异步计算评分
        this.calculateScoreForCurrentLabel()
      }
    } catch (error) {
      promptAction.showToast({ message: '识别失败，已切换到手动录入' })
      this.startManualEntry()
    } finally {
      this.isRecognizing = false
      this.refreshScanQuota()
    }
  }

  private loadEditFormFromLabel() {
    this.editFoodName = this.foodLabel.foodName
    this.editSodium = `${this.foodLabel.nutrition.sodium}`
    this.editSugar = `${this.foodLabel.nutrition.sugar}`
    this.editCalories = `${this.foodLabel.nutrition.calories}`
    this.editFat = `${this.foodLabel.nutrition.fat}`
    this.editCarbohydrate = `${this.foodLabel.nutrition.carbohydrate}`
    this.editProtein = `${this.foodLabel.nutrition.protein}`
    this.editIngredients = this.foodLabel.ingredients.join('\n')
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
      .split(/\r?\n|,|，|、/)
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
    // 识别完成后立即计算评分
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
    router.pushUrl({
      url: 'pages/ReportPage',
      params: {
        memberId: this.memberId,
        foodId: this.foodLabel.foodId
      }
    })
  }
}

import { common } from '@kit.AbilityKit';
import { router, promptAction } from '@kit.ArkUI';
import { FoodLabel } from '../model/FoodLabel';
import { AppState } from '../AppState';
import { FoodInputResult, FoodInputService } from '../service/FoodInputService';
import { SubscriptionTier } from '../model/PricingModel';

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

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params) {
      this.memberId = params.memberId || ''
    }
    this.refreshScanQuota()
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor('#1976D2')
            .onClick(() => { router.back() })
          Text('识别食品标签')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        this.ModeSelector()

        if (this.appState.getCurrentTier() === SubscriptionTier.FREE) {
          Row() {
            Text(this.scanLimitReached ? '今日扫描次数已用完' : `今日剩余扫描：${this.remainingScans} 次`)
              .fontSize(12)
              .fontColor(this.scanLimitReached ? '#D32F2F' : '#F57C00')
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
          .margin({ bottom: 12 })
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
              .backgroundColor('#1976D2')
              .borderRadius(26)
              .onClick(() => { this.startRecognition() })

            Button('手动录入')
              .width('90%')
              .height(48)
              .backgroundColor('#E3F2FD')
              .fontColor('#1976D2')
              .borderRadius(24)
              .margin({ top: 10 })
              .onClick(() => { this.startManualEntry() })
          } else {
            Button('查看适配报告')
              .width('90%')
              .height(52)
              .backgroundColor('#43A047')
              .borderRadius(26)
              .onClick(() => { this.viewReport() })

            Row() {
              Button(this.showEditPanel ? '收起修正面板' : '手动修正')
                .layoutWeight(1)
                .height(46)
                .backgroundColor('#E3F2FD')
                .fontColor('#1976D2')
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
        .margin({ top: 16, bottom: 24 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  @Builder
  ModeSelector() {
    Row() {
      Text('拍标签')
        .fontSize(15)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor(this.scanMode === 'camera' ? '#1976D2' : '#FFFFFF')
        .fontColor(this.scanMode === 'camera' ? '#FFFFFF' : '#212121')
        .onClick(() => { this.scanMode = 'camera' })

      Text('扫码')
        .fontSize(15)
        .padding({ left: 20, right: 20, top: 8, bottom: 8 })
        .borderRadius(20)
        .backgroundColor(this.scanMode === 'barcode' ? '#1976D2' : '#FFFFFF')
        .fontColor(this.scanMode === 'barcode' ? '#FFFFFF' : '#212121')
        .margin({ left: 10 })
        .onClick(() => { this.scanMode = 'barcode' })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .margin({ bottom: 12 })
  }

  @Builder
  ResultCard() {
    Column() {
      if (this.isRecognizing) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#1976D2')
        Text('正在处理中...')
          .fontSize(14)
          .fontColor('#757575')
          .margin({ top: 12 })
      } else if (this.foodLabel.foodId.length === 0) {
        Text('识别后会在这里生成一个可编辑的 FoodLabel 草稿')
          .fontSize(15)
          .fontColor('#616161')
          .textAlign(TextAlign.Center)
        Text('P0 版支持扫码命中本地库，或先生成草稿后手动修正')
          .fontSize(12)
          .fontColor('#9E9E9E')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      } else {
        Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : '待补充食品名称')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        if (this.recognitionHint.length > 0) {
          Text(this.recognitionHint)
            .fontSize(12)
            .fontColor('#1976D2')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 6 })
        }

        if (this.recognizedText.length > 0) {
          Text(this.recognizedText)
            .fontSize(12)
            .fontColor('#757575')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 8 })
        }

        Row() {
          this.MetricChip('钠', `${this.foodLabel.nutrition.sodium} mg`)
          this.MetricChip('糖', `${this.foodLabel.nutrition.sugar} g`)
          this.MetricChip('热量', `${this.foodLabel.nutrition.calories} kcal`)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ bottom: 8 })

        if (this.foodLabel.barcode.length > 0) {
          Text(`条码：${this.foodLabel.barcode}`)
            .fontSize(12)
            .fontColor('#616161')
            .margin({ bottom: 6 })
        }

        Text(this.showEditPanel ? '请核对下方字段后保存或查看报告' : '如信息不完整，可展开手动修正面板补全')
          .fontSize(12)
          .fontColor('#9E9E9E')
          .textAlign(TextAlign.Center)
      }
    }
    .width('92%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MetricChip(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor('#9E9E9E')
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

  @Builder
  EditPanel() {
    Column() {
      Text('手动修正')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

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
          .fontColor('#757575')
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
      .margin({ bottom: 12 })

      this.FormInput('生产商', this.editManufacturer, '输入生产商', (value: string) => { this.editManufacturer = value })
      this.FormInput('SC 编号', this.editScNumber, '输入 SC 编号', (value: string) => { this.editScNumber = value })
      this.FormInput('委托方', this.editPrincipal, '输入委托方', (value: string) => { this.editPrincipal = value })
      this.FormInput('受托方', this.editTrustee, '输入受托方', (value: string) => { this.editTrustee = value })
    }
    .width('92%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 14 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FormInput(title: string, value: string, placeholder: string, onChange: (value: string) => void) {
    Column() {
      Text(title)
        .fontSize(13)
        .fontColor('#757575')
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
    .margin({ bottom: 12 })
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

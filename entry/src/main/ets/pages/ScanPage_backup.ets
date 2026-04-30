// 鎵弿椤?- 椋熷搧鏍囩璇嗗埆涓庡綍鍏ワ紙V6娓╂殩濂虫€ч鏍硷級
// 鏂板锛氶鍝佹悳绱㈡暟鎹簱銆佸父鐢ㄩ鍝佹ā鏉裤€佸巻鍙查鍝佸揩閫熼€夋嫨銆佸揩閫熷綍鍏ユā鏉?

import { common } from '@kit.AbilityKit';
import { router, promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FoodLabel } from '../model/FoodLabel';
import { AppState } from '../AppState';
import { FoodInputResult, FoodInputService } from '../service/FoodInputService';
import { ScanService } from '../service/ScanService';
import { SubscriptionTier } from '../model/PricingModel';
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT, getNutrientColor } from '../constants/AppTheme';

// 甯哥敤椋熷搧妯℃澘
interface FoodTemplate {
  name: string;
  emoji: string;
  sodium: number;
  sugar: number;
  calories: number;
  fat: number;
  carb: number;
  protein: number;
  ingredients: string[];
}

// 椋熷搧emoji鏄犲皠鏉＄洰
class FoodEmojiEntry {
  key: string = ''
  value: string = ''
}

const FOOD_TEMPLATES: FoodTemplate[] = [
  { name: '绾墰濂?, emoji: '馃', sodium: 50, sugar: 5, calories: 65, fat: 3.5, carb: 5, protein: 3, ingredients: ['鐢熺墰涔?] },
  { name: '鍘熷懗閰稿ザ', emoji: '馃嵍', sodium: 60, sugar: 12, calories: 80, fat: 3, carb: 13, protein: 3, ingredients: ['鐢熺墰涔?, '鐧界爞绯?, '涔抽吀鑿?] },
  { name: '鍏ㄩ害闈㈠寘', emoji: '馃崬', sodium: 300, sugar: 3, calories: 250, fat: 4, carb: 45, protein: 8, ingredients: ['鍏ㄩ害绮?, '姘?, '閰垫瘝', '椋熺敤鐩?] },
  { name: '鑻忔墦楗煎共', emoji: '馃崻', sodium: 450, sugar: 2, calories: 420, fat: 18, carb: 60, protein: 7, ingredients: ['灏忛害绮?, '妞嶇墿娌?, '椋熺敤鐩?, '纰抽吀姘㈤挔'] },
  { name: '鐏吙鑲?, emoji: '馃尛', sodium: 800, sugar: 2, calories: 220, fat: 15, carb: 8, protein: 12, ingredients: ['鐚倝', '娣€绮?, '椋熺敤鐩?, '棣欒緵鏂?] },
  { name: '鏂逛究闈?, emoji: '馃崪', sodium: 1600, sugar: 5, calories: 470, fat: 20, carb: 65, protein: 8, ingredients: ['灏忛害绮?, '妫曟娌?, '椋熺敤鐩?, '鍛崇簿'] },
  { name: '钖墖', emoji: '馃', sodium: 500, sugar: 3, calories: 530, fat: 34, carb: 53, protein: 5, ingredients: ['椹搩钖?, '妞嶇墿娌?, '椋熺敤鐩?, '璋冨懗鏂?] },
  { name: '鍙箰', emoji: '馃イ', sodium: 15, sugar: 11, calories: 42, fat: 0, carb: 11, protein: 0, ingredients: ['姘?, '鏋滆憽绯栨祮', '浜屾哀鍖栫⒊', '鐒︾硸鑹?] },
  { name: '鐭挎硥/鑻忔墦姘?, emoji: '馃挧', sodium: 5, sugar: 0, calories: 0, fat: 0, carb: 0, protein: 0, ingredients: ['姘?] },
  { name: '宸у厠鍔?, emoji: '馃崼', sodium: 30, sugar: 50, calories: 550, fat: 35, carb: 55, protein: 6, ingredients: ['鍙彲鑴?, '鐧界爞绯?, '鍙彲绮?, '涔冲埗鍝?] },
  { name: '楗煎共(澶瑰績)', emoji: '馃ク', sodium: 200, sugar: 25, calories: 480, fat: 22, carb: 65, protein: 5, ingredients: ['灏忛害绮?, '鐧界爞绯?, '妞嶇墿娌?, '涔冲埗鍝?] },
  { name: '鏋滄眮楗枡', emoji: '馃', sodium: 20, sugar: 10, calories: 45, fat: 0, carb: 11, protein: 0, ingredients: ['姘?, '娴撶缉鏋滄眮', '鐧界爞绯?, '鏌犳閰?] },
]

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

  // 缂栬緫琛ㄥ崟
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

  // 鏂板鐘舵€?
  @State showTemplatePicker: boolean = false
  @State showSearchMode: boolean = false
  @State searchQuery: string = ''
  @State searchResults: FoodTemplate[] = []
  @State recentFoods: FoodLabel[] = []
  @State scanAnimOpacity: number = 1.0
  @State scanAnimScale: number = 1.0
  @State showScanGuide: boolean = true
  @State batchMode: boolean = false
  @State batchItems: FoodLabel[] = []
  @State ocrProgressText: string = ''

  private memberId: string = ''
  private appState: AppState = AppState.getInstance()
  private foodInputService: FoodInputService = new FoodInputService()
  private scanAnimTimer: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    if (params) {
      this.memberId = params.memberId || ''
    }
    this.refreshScanQuota()
    this.loadRecentFoods()
    this.startScanAnimation()
  }

  startScanAnimation() {
    this.scanAnimTimer = setInterval(() => {
      animateTo({ duration: 1500, curve: Curve.Smooth }, () => {
        this.scanAnimOpacity = this.scanAnimOpacity === 1.0 ? 0.3 : 1.0
        this.scanAnimScale = this.scanAnimScale === 1.0 ? 1.05 : 1.0
      })
    }, 2000)
  }

  async loadRecentFoods() {
    const history = await this.appState.getRecentScanHistory(20)
    const foodIdSet: string[] = []
    for (const h of history) {
      let found = false
      for (const id of foodIdSet) {
        if (id === h.foodId) {
          found = true
          break
        }
      }
      if (!found) {
        foodIdSet.push(h.foodId)
      }
    }
    const foods: FoodLabel[] = []
    for (const id of foodIdSet) {
      const food = await this.appState.findFoodById(id)
      if (food) foods.push(food)
    }
    this.recentFoods = foods.slice(0, 10)
  }

  build() {
    Scroll() {
      Column() {
        // 椤堕儴瀵艰埅
        Row() {
          Text('鈫?)
            .fontSize(FONT_SIZE.LARGE)
            .fontColor(COLORS.PRIMARY)
            .onClick(() => { router.back() })
          Text('璇嗗埆椋熷搧鏍囩')
            .fontSize(FONT_SIZE.TITLE_LG)
            .fontWeight(FONT_WEIGHT.BOLD)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ left: 12 })
        }
        .width('100%')
        .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.LG })

        // 妯″紡閫夋嫨 + 鎼滅储鍏ュ彛
        this.ModeSelector()

        // 鎵弿閰嶉鎻愮ず
        if (this.appState.getCurrentTier() === SubscriptionTier.FREE) {
          Row() {
            Text(this.scanLimitReached ? '浠婃棩鎵弿娆℃暟宸茬敤瀹? : `浠婃棩鍓╀綑鎵弿锛?{this.remainingScans} 娆)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(this.scanLimitReached ? COLORS.DANGER : COLORS.WARNING)
              .padding({ left: SPACING.SM, right: SPACING.SM, top: SPACING.XS, bottom: SPACING.XS })
              .backgroundColor(this.scanLimitReached ? COLORS.DANGER + '20' : COLORS.WARNING + '20')
              .borderRadius(RADIUS.FULL)
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG })
          .margin({ bottom: 12 })
        }

        // 鎼滅储妯″紡
        if (this.showSearchMode) {
          this.SearchPanel()
        }

        // 甯哥敤椋熷搧妯℃澘
        if (!this.showSearchMode && this.foodLabel.foodId.length === 0) {
          this.FoodTemplateSection()
        }

        // 鏈€杩戞壂鎻忕殑椋熷搧
        if (!this.showSearchMode && this.foodLabel.foodId.length === 0 && this.recentFoods.length > 0) {
          this.RecentFoodsSection()
        }

        // 璇嗗埆缁撴灉
        this.ResultCard()

        // 缂栬緫闈㈡澘
        if (this.showEditPanel) {
          this.EditPanel()
        }

        // 鎿嶄綔鎸夐挳
        this.ActionButtons()

        // 搴曢儴瀹夊叏闂磋窛
        Column().height(24)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [
        [COLORS.BG_GRADIENT_START, 0],
        [COLORS.BG_GRADIENT_END, 1]
      ]
    })
  }

  @Builder
  ModeSelector() {
    Column() {
      Row() {
        // 妯″紡鍒囨崲
        Row() {
          Text('馃摲 鎷嶆爣绛?)
            .fontSize(FONT_SIZE.BODY)
            .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
            .borderRadius(RADIUS.XXL)
            .backgroundColor(this.scanMode === 'camera' ? COLORS.PRIMARY : COLORS.BG_CARD)
            .fontColor(this.scanMode === 'camera' ? COLORS.TEXT_WHITE : COLORS.TEXT_PRIMARY)
            .shadow({
              radius: this.scanMode === 'camera' ? 4 : 0,
              color: COLORS.SHADOW_LIGHT,
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => { this.scanMode = 'camera'; this.showSearchMode = false })

          Text('馃摫 鎵爜')
            .fontSize(FONT_SIZE.BODY)
            .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
            .borderRadius(RADIUS.XXL)
            .backgroundColor(this.scanMode === 'barcode' ? COLORS.PRIMARY : COLORS.BG_CARD)
            .fontColor(this.scanMode === 'barcode' ? COLORS.TEXT_WHITE : COLORS.TEXT_PRIMARY)
            .margin({ left: 8 })
            .shadow({
              radius: this.scanMode === 'barcode' ? 4 : 0,
              color: COLORS.SHADOW_LIGHT,
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => { this.scanMode = 'barcode'; this.showSearchMode = false })
        }

        Blank()

        // 鎼滅储鎸夐挳
        Text('馃攳 鎼滅储')
          .fontSize(FONT_SIZE.BODY)
          .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
          .borderRadius(RADIUS.XXL)
          .backgroundColor(this.showSearchMode ? COLORS.ACCENT_GREEN : COLORS.BG_CARD)
          .fontColor(this.showSearchMode ? COLORS.TEXT_WHITE : COLORS.TEXT_PRIMARY)
          .shadow({
            radius: this.showSearchMode ? 4 : 0,
            color: COLORS.SHADOW_LIGHT,
            offsetX: 0,
            offsetY: 2
          })
          .onClick(() => {
            this.showSearchMode = !this.showSearchMode
            if (!this.showSearchMode) {
              this.searchQuery = ''
              this.searchResults = []
            }
          })
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG })
      .margin({ bottom: 12 })
    }
  }

  @Builder
  SearchPanel() {
    Column() {
      TextInput({ placeholder: '鎼滅储椋熷搧鍚嶇О锛堝锛氱墰濂躲€侀潰鍖呫€佸彲涔?..锛? })
        .width('100%')
        .height(44)
        .borderRadius(RADIUS.LG)
        .backgroundColor(COLORS.BG_CARD)
        .padding({ left: SPACING.MD })
        .onChange((value: string) => {
          this.searchQuery = value
          this.searchResults = this.searchFoods(value)
        })

      if (this.searchResults.length > 0) {
        Column() {
          Text(`鎵惧埌 ${this.searchResults.length} 涓粨鏋渀)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_HINT)
            .width('100%')
            .margin({ bottom: SPACING.SM })

          ForEach(this.searchResults, (template: FoodTemplate) => {
            Row() {
              Text(template.emoji).fontSize(FONT_SIZE.LARGE).margin({ right: SPACING.XS })
              Column() {
                Text(template.name).fontSize(FONT_SIZE.BODY_LG).fontWeight(FONT_WEIGHT.MEDIUM)
                Text(`閽?{template.sodium}mg 路 绯?{template.sugar}g 路 ${template.calories}kcal`)
                  .fontSize(FONT_SIZE.TINY).fontColor(COLORS.TEXT_HINT).margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
              Text('閫夋嫨').fontSize(FONT_SIZE.SMALL).fontColor(COLORS.PRIMARY)
            }
            .width('100%')
            .padding(SPACING.MD)
            .backgroundColor(COLORS.BG_CARD)
            .borderRadius(RADIUS.LG)
            .margin({ bottom: 6 })
            .shadow({
              radius: 2,
              color: COLORS.SHADOW_LIGHT,
              offsetX: 0,
              offsetY: 1
            })
            .onClick(() => {
              this.applyTemplate(template)
              this.showSearchMode = false
              this.searchQuery = ''
              this.searchResults = []
            })
          }, (template: FoodTemplate, index: number) => `${template.name}_${index}`)
        }
        .width('100%')
        .margin({ top: 10 })
      } else if (this.searchQuery.length > 0) {
        Text('鏈壘鍒板尮閰嶇殑椋熷搧锛岃瘯璇曞叾浠栧叧閿瘝')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_HINT)
          .margin({ top: SPACING.XS })
      }
    }
    .width('92%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: SPACING.MD })
    .alignItems(HorizontalAlign.Start)
    .shadow({
      radius: 6,
      color: COLORS.SHADOW_LIGHT,
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  FoodTemplateSection() {
    Column() {
      Row() {
        Text('馃搵 甯哥敤椋熷搧蹇€熷綍鍏?)
          .fontSize(FONT_SIZE.BODY_LG)
          .fontWeight(FONT_WEIGHT.MEDIUM)
        Blank()
        Text(this.showTemplatePicker ? '鏀惰捣 鈻? : '灞曞紑鍏ㄩ儴 鈻?)
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { this.showTemplatePicker = !this.showTemplatePicker })
      }
      .width('100%')
      .margin({ bottom: SPACING.SM })

      if (this.showTemplatePicker) {
        // 缃戞牸灞曠ず鎵€鏈夋ā鏉?
        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(FOOD_TEMPLATES, (template: FoodTemplate) => {
            Column() {
              Text(template.emoji).fontSize(FONT_SIZE.XLARGE)
              Text(template.name).fontSize(FONT_SIZE.SMALL).fontColor(COLORS.TEXT_PRIMARY).margin({ top: 4 })
                .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width(72)
            .height(72)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(COLORS.BG_SECTION)
            .borderRadius(RADIUS.LG)
            .margin({ right: 8, bottom: 8 })
            .shadow({
              radius: 2,
              color: COLORS.SHADOW_LIGHT,
              offsetX: 0,
              offsetY: 1
            })
            .onClick(() => { this.applyTemplate(template) })
          }, (template: FoodTemplate, index: number) => `${template.name}_${index}`)
        }
        .width('100%')
      } else {
        // 鍙樉绀轰竴琛屽父鐢?
        Scroll() {
          Row() {
            ForEach(FOOD_TEMPLATES.slice(0, 8), (template: FoodTemplate) => {
              Column() {
                Text(template.emoji).fontSize(FONT_SIZE.LARGE)
                Text(template.name).fontSize(FONT_SIZE.TINY).fontColor(COLORS.TEXT_PRIMARY).margin({ top: 2 })
                  .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width(60)
              .height(60)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor(COLORS.BG_SECTION)
              .borderRadius(RADIUS.LG)
              .margin({ right: 6 })
              .shadow({
                radius: 2,
                color: COLORS.SHADOW_LIGHT,
                offsetX: 0,
                offsetY: 1
              })
              .onClick(() => { this.applyTemplate(template) })
            }, (template: FoodTemplate, index: number) => `${template.name}_${index}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
      }
    }
    .width('92%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: SPACING.MD })
    .alignItems(HorizontalAlign.Start)
    .shadow({
      radius: 6,
      color: COLORS.SHADOW_LIGHT,
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  RecentFoodsSection() {
    Column() {
      Text('馃晲 鏈€杩戞壂鎻忕殑椋熷搧')
        .fontSize(FONT_SIZE.BODY_LG)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .width('100%')
        .margin({ bottom: SPACING.SM })

      Scroll() {
        Row() {
          ForEach(this.recentFoods, (food: FoodLabel) => {
            Column() {
              Text(this.getFoodEmoji(food.foodName))
                .fontSize(FONT_SIZE.LARGE)
              Text(food.foodName)
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_PRIMARY)
                .margin({ top: 2 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(56)
                .textAlign(TextAlign.Center)
            }
            .width(60)
            .height(60)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(COLORS.BG_SECTION)
            .borderRadius(RADIUS.LG)
            .margin({ right: 6 })
            .shadow({
              radius: 2,
              color: COLORS.SHADOW_LIGHT,
              offsetX: 0,
              offsetY: 1
            })
            .onClick(() => {
              this.foodLabel = food
              this.recognitionHint = '宸蹭粠鍘嗗彶璁板綍鍔犺浇'
              this.loadEditFormFromLabel()
            })
          }, (food: FoodLabel) => food.foodId)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
    }
    .width('92%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: SPACING.MD })
    .alignItems(HorizontalAlign.Start)
    .shadow({
      radius: 6,
      color: COLORS.SHADOW_LIGHT,
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  ResultCard() {
    Column() {
      if (this.isRecognizing) {
        // 澧炲己鐨勮瘑鍒姩鐢?
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(COLORS.PRIMARY)
            .scale({ x: this.scanAnimScale, y: this.scanAnimScale })
            .opacity(this.scanAnimOpacity)
            .animation({ duration: 1500, curve: Curve.Smooth })
          Text('姝ｅ湪璇嗗埆涓?..')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 12 })
          if (this.ocrProgressText.length > 0) {
            Text(this.ocrProgressText)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_HINT)
              .margin({ top: 4 })
          }
        }
        .padding(SPACING.XXL)
        .backgroundColor(COLORS.BG_CARD)
        .borderRadius(RADIUS.LG)
        .shadow({
          radius: 8,
          color: COLORS.SHADOW_LIGHT,
          offsetX: 0,
          offsetY: 2
        })
      } else if (this.foodLabel.foodId.length === 0) {
        Column() {
          Text('馃摳 鎷嶆爣绛炬垨浠庝笂鏂规ā鏉块€夋嫨')
            .fontSize(FONT_SIZE.SUBTITLE)
            .fontColor(COLORS.TEXT_SECONDARY)
            .textAlign(TextAlign.Center)
          Text('鏀寔鎵爜璇嗗埆銆佹墜鍔ㄥ綍鍏ャ€佸父鐢ㄩ鍝佸揩閫熼€夋嫨')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_HINT)
            .textAlign(TextAlign.Center)
            .margin({ top: SPACING.SM })
          if (this.showScanGuide) {
            Text('馃挕 鎻愮ず锛氱偣鍑?寮€濮嬭瘑鍒?鎸夐挳鎵弿椋熷搧鏍囩')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.PRIMARY)
              .textAlign(TextAlign.Center)
              .margin({ top: 12 })
              .padding({ left: SPACING.SM, right: SPACING.SM, top: SPACING.XS, bottom: SPACING.XS })
              .backgroundColor(COLORS.PRIMARY_LIGHT)
              .borderRadius(RADIUS.FULL)
          }
        }
        .padding(SPACING.XL)
        .backgroundColor(COLORS.BG_CARD)
        .borderRadius(RADIUS.LG)
        .shadow({
          radius: 6,
          color: COLORS.SHADOW_LIGHT,
          offsetX: 0,
          offsetY: 2
        })
      } else {
        // 椋熷搧淇℃伅鍗＄墖锛堝甫璇嗗埆鎴愬姛鍔ㄧ敾锛?
        Column() {
          Row() {
            Text(this.getFoodEmoji(this.foodLabel.foodName))
              .fontSize(FONT_SIZE.HUGE)
              .margin({ right: SPACING.MD })
            Column() {
              Text(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : '寰呰ˉ鍏呴鍝佸悕绉?)
                .fontSize(FONT_SIZE.TITLE)
                .fontWeight(FONT_WEIGHT.BOLD)
              if (this.recognitionHint.length > 0) {
                Text(this.recognitionHint)
                  .fontSize(FONT_SIZE.TINY)
                  .fontColor(COLORS.PRIMARY)
                  .margin({ top: 2 })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 12 })

          // 钀ュ吇鎴愬垎缃戞牸
          Row() {
            this.NutriChip('閽?, `${this.foodLabel.nutrition.sodium}mg`, this.foodLabel.isHighSodium())
            this.NutriChip('绯?, `${this.foodLabel.nutrition.sugar}g`, this.foodLabel.isHighSugar())
            this.NutriChip('鐑噺', `${this.foodLabel.nutrition.calories}kcal`, this.foodLabel.isHighCalorie())
            this.NutriChip('鑴傝偑', `${this.foodLabel.nutrition.fat}g`, this.foodLabel.isHighFat())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Row() {
            this.NutriChip('纰虫按', `${this.foodLabel.nutrition.carbohydrate}g`, false)
            this.NutriChip('铔嬬櫧', `${this.foodLabel.nutrition.protein}g`, false)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
          .margin({ top: 6 })

          if (this.foodLabel.ingredients.length > 0) {
            Text(`閰嶆枡锛?{this.foodLabel.ingredients.join('銆?)}`)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_HINT)
              .width('100%')
              .margin({ top: SPACING.SM })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        .padding(SPACING.LG)
        .backgroundColor(COLORS.BG_CARD)
        .borderRadius(RADIUS.LG)
        .shadow({
          radius: 6,
          color: COLORS.SHADOW_LIGHT,
          offsetX: 0,
          offsetY: 2
        })
      }
    }
    .width('92%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  NutriChip(label: string, value: string, isHigh: boolean) {
    Column() {
      Text(label)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_HINT)
      Text(value)
        .fontSize(FONT_SIZE.SMALL)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .fontColor(isHigh ? COLORS.DANGER : COLORS.TEXT_PRIMARY)
        .margin({ top: 2 })
    }
    .padding({ left: SPACING.SM, right: SPACING.SM, top: SPACING.XS, bottom: SPACING.XS })
    .backgroundColor(isHigh ? COLORS.DANGER + '15' : COLORS.BG_SECTION)
    .borderRadius(RADIUS.LG)
    .alignItems(HorizontalAlign.Center)
  }FONT_WEIGHT.MEDIUM)
        .fontColor(isHigh ? COLORS.DANGER : COLORS.TEXT_PRIMARY)
        .margin({ top: 2 })
      if (isHigh) {
        Text('鈿狅笍鍋忛珮')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.DANGER)
          .margin({ top: 1 })
      }
    }
    .padding({ top: SPACING.SM, bottom: SPACING.SM, left: SPACING.SM, right: SPACING.SM })
    .backgroundColor(COLORS.BG_SECTION)
    .borderRadius(RADIUS.SM)
    .margin({ right: 6 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  EditPanel() {
    Column() {
      Text('鉁忥笍 鎵嬪姩淇')
        .fontSize(FONT_SIZE.TITLE)
        .fontWeight(FONT_WEIGHT.BOLD)
        .margin({ bottom: SPACING.MD })

      this.FormInput('椋熷搧鍚嶇О', this.editFoodName, '杈撳叆椋熷搧鍚嶇О', (value: string) => { this.editFoodName = value })
      this.FormInput('閽狅紙mg/100g锛?, this.editSodium, '0', (value: string) => { this.editSodium = value })
      this.FormInput('绯栵紙g/100g锛?, this.editSugar, '0', (value: string) => { this.editSugar = value })
      this.FormInput('鐑噺锛坘cal/100g锛?, this.editCalories, '0', (value: string) => { this.editCalories = value })
      this.FormInput('鑴傝偑锛坓/100g锛?, this.editFat, '0', (value: string) => { this.editFat = value })
      this.FormInput('纰虫按锛坓/100g锛?, this.editCarbohydrate, '0', (value: string) => { this.editCarbohydrate = value })
      this.FormInput('铔嬬櫧璐紙g/100g锛?, this.editProtein, '0', (value: string) => { this.editProtein = value })

      Column() {
        Text('閰嶆枡')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_SECONDARY)
          .margin({ bottom: 6 })
        TextArea({ text: this.editIngredients, placeholder: '涓€琛屼竴涓紝鎴栫敤閫楀彿鍒嗛殧' })
          .width('100%')
          .height(80)
          .padding(SPACING.SM)
        .backgroundColor(COLORS.BG_SECTION)
          .borderRadius(RADIUS.MD)
          .onChange((value: string) => { this.editIngredients = value })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 12 })

      this.FormInput('鐢熶骇鍟?, this.editManufacturer, '杈撳叆鐢熶骇鍟?, (value: string) => { this.editManufacturer = value })
      this.FormInput('SC 缂栧彿', this.editScNumber, '杈撳叆 SC 缂栧彿', (value: string) => { this.editScNumber = value })
    }
    .width('92%')
    .padding(SPACING.LG)
    .backgroundColor(COLORS.BG_CARD)
    .borderRadius(RADIUS.LG)
    .margin({ top: SPACING.SM })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  FormInput(title: string, value: string, placeholder: string, onChange: (value: string) => void) {
    Column() {
      Text(title)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_HINT)
        .margin({ bottom: SPACING.XS })
      TextInput({ text: value, placeholder })
        .width('100%')
        .height(44)
        .padding({ left: SPACING.SM, right: SPACING.SM })
        .backgroundColor(COLORS.BG_SECTION)
        .borderRadius(RADIUS.SM)
        .onChange(onChange)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  ActionButtons() {
    Column() {
      if (this.foodLabel.foodId.length === 0) {
        // 鏈瘑鍒椂锛氭壂鎻?鎵嬪姩褰曞叆
        Button('馃摲 寮€濮嬭瘑鍒?)
          .width('90%')
          .height(52)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(RADIUS.XXL)
          .fontSize(FONT_SIZE.BODY_LG)
          .onClick(() => { this.startRecognition() })

        Button('鉁忥笍 鎵嬪姩褰曞叆')
          .width('90%')
          .height(48)
          .backgroundColor(COLORS.ACCENT_BLUE_LIGHT)
          .fontColor(COLORS.PRIMARY)
          .borderRadius(RADIUS.XL)
          .fontSize(FONT_SIZE.BODY)
          .margin({ top: SPACING.SM })
          .onClick(() => { this.startManualEntry() })
      } else {
        // 宸茶瘑鍒椂锛氭煡鐪嬫姤鍛?+ 淇 + 淇濆瓨
        Button('馃搳 鏌ョ湅閫傞厤鎶ュ憡')
          .width('90%')
          .height(52)
          .backgroundColor(COLORS.ACCENT_GREEN)
          .borderRadius(RADIUS.XXL)
          .fontSize(FONT_SIZE.BODY_LG)
          .onClick(() => { this.viewReport() })

        Row() {
          Button(this.showEditPanel ? '鏀惰捣淇' : '鉁忥笍 鎵嬪姩淇')
            .layoutWeight(1)
            .height(46)
            .backgroundColor(COLORS.ACCENT_BLUE_LIGHT)
            .fontColor(COLORS.PRIMARY)
            .borderRadius(RADIUS.LG)
            .fontSize(FONT_SIZE.SMALL)
            .onClick(() => {
              this.showEditPanel = !this.showEditPanel
              if (this.showEditPanel) {
                this.loadEditFormFromLabel()
              }
            })

          Button('馃捑 淇濆瓨')
            .layoutWeight(1)
            .height(46)
            .backgroundColor(COLORS.WARNING + '20')
            .fontColor(COLORS.WARNING)
            .borderRadius(RADIUS.LG)
            .fontSize(FONT_SIZE.SMALL)
            .margin({ left: SPACING.SM })
            .onClick(() => { this.saveDraft() })
        }
        .width('90%')
        .margin({ top: 10 })

        // 閲嶆柊閫夋嫨
        Text('閲嶆柊閫夋嫨鍏朵粬椋熷搧')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_HINT)
          .margin({ top: SPACING.SM, bottom: SPACING.XL })
          .onClick(() => {
            this.foodLabel = new FoodLabel()
            this.showEditPanel = false
          })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 16, bottom: 24 })
  }

  // ===== 宸ュ叿鏂规硶 =====

  private searchFoods(query: string): FoodTemplate[] {
    if (query.length === 0) return []
    const q = query.toLowerCase()
    return FOOD_TEMPLATES.filter(t =>
      t.name.toLowerCase().includes(q) ||
      t.ingredients.some(i => i.toLowerCase().includes(q))
    )
  }

  private applyTemplate(template: FoodTemplate) {
    const label = new FoodLabel()
    label.foodId = `food_${Date.now()}`
    label.foodName = template.name
    label.nutrition.sodium = template.sodium
    label.nutrition.sugar = template.sugar
    label.nutrition.calories = template.calories
    label.nutrition.fat = template.fat
    label.nutrition.carbohydrate = template.carb
    label.nutrition.protein = template.protein
    label.ingredients = template.ingredients
    label.identifiedAt = Date.now()
    this.foodLabel = label
    this.recognitionHint = `宸查€夋嫨銆?{template.name}銆峘
    this.loadEditFormFromLabel()
    promptAction.showToast({ message: `宸查€夋嫨锛?{template.name}` })
  }

  private getFoodEmoji(foodName: string): string {
    const foodEmojiEntries: FoodEmojiEntry[] = [
      { key: '鐗涘ザ', value: '馃' }, { key: '閰稿ザ', value: '馃嵍' }, { key: '闈㈠寘', value: '馃崬' },
      { key: '楗煎共', value: '馃崻' }, { key: '鐏吙', value: '馃尛' }, { key: '鏂逛究闈?, value: '馃崪' },
      { key: '钖墖', value: '馃' }, { key: '鍙箰', value: '馃イ' }, { key: '姘?, value: '馃挧' },
      { key: '宸у厠鍔?, value: '馃崼' }, { key: '鏋滄眮', value: '馃' }, { key: '铔嬬硶', value: '馃巶' },
      { key: '鍐版穱娣?, value: '馃崷' }, { key: '鍜栧暋', value: '鈽? }, { key: '鑼?, value: '馃嵉' },
      { key: '楦?, value: '馃崡' }, { key: '鑲?, value: '馃ォ' }, { key: '楸?, value: '馃悷' },
      { key: '铏?, value: '馃' }, { key: '铔?, value: '馃' }, { key: '璞嗚厫', value: '馃珮' },
      { key: '钄彍', value: '馃ガ' }, { key: '姘存灉', value: '馃崕' }, { key: '绫抽キ', value: '馃崥' },
      { key: '闈㈡潯', value: '馃崫' },
    ]
    for (const entry of foodEmojiEntries) {
      if (foodName.includes(entry.key)) {
        return entry.value
      }
    }
    return '馃嵔锔?
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
      promptAction.showToast({ message: '浠婃棩鎵弿娆℃暟宸茬敤瀹? })
      return
    }

    this.isRecognizing = true
    this.ocrProgressText = '姝ｅ湪鍑嗗鎵爜...'
    try {
      if (this.scanMode === 'barcode') {
        const context = getContext(this) as common.Context

        // 姝ラ1锛氭鏌ヨ澶囨槸鍚︽敮鎸佹壂鐮?
        if (!ScanService.isScanSupported()) {
          promptAction.showToast({ message: '褰撳墠璁惧涓嶆敮鎸佹壂鐮佸姛鑳斤紝宸插垏鎹㈠埌鎵嬪姩褰曞叆' })
          this.startManualEntry()
          return
        }

        this.ocrProgressText = '姝ｅ湪鍚姩鎵爜...'

        // 姝ラ2锛氳皟鐢?FoodInputService 鐨勬壂鐮?鏌ヨ娴佺▼
        // 璇ユ祦绋嬪唴閮ㄦ墽琛岋細鎵爜 鈫?鏌ユ湰鍦扮紦瀛?鈫?鏌ヨ繙绋婣PI
        const result = await this.foodInputService.scanBarcode(context)

        if (result) {
          this.applyFoodInputResult(result)

          // 鎵爜鎴愬姛鎻愮ず
          if (result.confidence >= 0.8) {
            promptAction.showToast({ message: `璇嗗埆鎴愬姛锛?{result.foodLabel.foodName}` })
          } else if (result.confidence > 0) {
            promptAction.showToast({ message: '宸茶幏鍙栭儴鍒嗘暟鎹紝璇锋牳瀵瑰悗淇濆瓨' })
          }
        } else {
          // 鎵爜鍙栨秷鎴栧け璐?
          promptAction.showToast({ message: '鎵爜宸插彇娑? })
        }
      } else {
        // 鎷嶇収璇嗗埆妯″紡锛圥0鐗堟湰鐢熸垚鍙紪杈戣崏绋匡級
        this.ocrProgressText = '姝ｅ湪澶勭悊鍥惧儚...'
        this.applyFoodInputResult(this.foodInputService.createCameraDraft())
      }

      if (this.foodLabel.foodId.length > 0) {
        this.appState.recordScan()
      }
    } catch (error) {
      hilog.error(0, 'ScanPage', 'Recognition failed: %{public}s', JSON.stringify(error))
      promptAction.showToast({ message: '璇嗗埆澶辫触锛屽凡鍒囨崲鍒版墜鍔ㄥ綍鍏? })
      this.startManualEntry()
    } finally {
      this.isRecognizing = false
      this.ocrProgressText = ''
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
      .split(/\r?\n|,|锛寍銆?)
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
      promptAction.showToast({ message: '璇峰厛琛ュ叏椋熷搧鍚嶇О' })
      return false
    }
    await this.appState.saveFoodLabel(this.foodLabel)
    if (showSuccessToast) {
      promptAction.showToast({ message: 'FoodLabel 宸蹭繚瀛? })
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


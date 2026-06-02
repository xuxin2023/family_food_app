// FoodComparePage.ets
// 食品对比页 — 两个食品的并排营养对比视图

import { FoodLabel, NutritionPer100g, COLORS, RADIUS, HILOG_DOMAIN_DEFAULT, ToastHelper, NutritionSnapshot, resourceToStr } from 'hsp_core';
import { FoodCompareService, FoodCompareResult, NutritionDelta } from 'hsp_service';
import { BackButton } from '../components/BackButton';
import { AppState } from '../AppState';
import { NovaGroupBadge } from '../components/NovaGroupBadge';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';

const TAG = 'FoodComparePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class NutrientDiff {
  name: ResourceStr = '';
  unit: string = '';
  value1: number = 0;
  value2: number = 0;
  diff: number = 0;
  betterSide: number = 0;
}

@Entry
@ComponentV2
struct FoodComparePage {
  @Local food1: FoodLabel | null = null
  @Local food2: FoodLabel | null = null
  @Local isLoading: boolean = false
  @Local barcode1: string = ''
  @Local barcode2: string = ''
  @Local recentFoods: FoodLabel[] = []
  @Local showHistoryPicker: boolean = false
  @Local pickingSide: 1 | 2 = 1
  @Local savedSnapshots: NutritionSnapshot[] = []
  @Local compareResult: FoodCompareResult | null = null

  private appState: AppState = AppState.getInstance()
  private compareService: FoodCompareService = new FoodCompareService()
  private mContext: UIContext | undefined = undefined
  private componentActive: boolean = true

  async aboutToAppear(): Promise<void> {
    this.componentActive = true;
    this.mContext = this.getUIContext() as UIContext;
    try {
      const allResults = await Promise.all([
        this.appState.historyRepo.getRecentFoods(20).catch((e) => {
          hilog.warn(DOMAIN_ZERO, TAG, 'Load recent foods failed: %{public}s', JSON.stringify(e))
          const emptyArr: FoodLabel[] = []
          return emptyArr
        }),
        this.appState.getNutritionSnapshots('', 20).catch((_e) => {
          const emptySnapshots: NutritionSnapshot[] = []
          return emptySnapshots
        })
      ])
      const recentFoods = allResults[0] as FoodLabel[]
      const savedSnapshots = allResults[1] as NutritionSnapshot[]
      this.recentFoods = recentFoods
      this.savedSnapshots = savedSnapshots
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.recentFoods = []
      this.savedSnapshots = []
    }
  }

  aboutToDisappear(): void {
    this.componentActive = false
  }

  build() {
    Column() {
      Row() {
        BackButton()
        .accessibilityText('返回')
        .accessibilityLevel('yes')
        Text($r('app.string.food_compare_title')).fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 12 })
      }
      .width('100%')
      .padding(16)

      Scroll() {
        Column() {
          if (this.food1 !== null && this.food2 !== null) {
            this.compareHeader()
            this.nutrientDiffList()
            this.conclusionSection()
          } else {
            this.selectSection()
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)

      if (this.showHistoryPicker) {
        this.historyPickerSheet()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  selectSection() {
    Column() {
      Text($r('app.string.food_compare_select_hint')).fontSize(16).fontColor(COLORS.TEXT_SECONDARY).margin({ bottom: 24 })

      Row({ space: 12 }) {
        Column() {
          Text($r('app.string.food_compare_food_a')).fontSize(14).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
          if (this.food1 !== null) {
            this.selectedFoodCard(this.food1, 1)
          } else {
            this.foodInputCard(1)
          }
        }
        .layoutWeight(1)

        Column() {
          Text($r('app.string.food_compare_food_b')).fontSize(14).fontWeight(FontWeight.Medium).margin({ bottom: 8 })
          if (this.food2 !== null) {
            this.selectedFoodCard(this.food2, 2)
          } else {
            this.foodInputCard(2)
          }
        }
        .layoutWeight(1)
      }
      .width('100%')

      if (this.food1 !== null && this.food2 !== null) {
        Button($r('app.string.food_compare_start'))
          .width('60%')
          .height(44)
          .margin({ top: 24 })
          .backgroundColor(COLORS.PRIMARY)
          .fontColor(COLORS.WHITE)
          .borderRadius(RADIUS.LG)
          .accessibilityText('开始对比')
          .accessibilityLevel('yes')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 40 })
  }

  @Builder
  foodInputCard(side: 1 | 2) {
    Column() {
      TextInput({ placeholder: $r('app.string.food_compare_barcode_placeholder'), text: side === 1 ? this.barcode1 : this.barcode2 })
        .width('100%')
        .height(36)
        .borderRadius(8)
        .backgroundColor(COLORS.WHITE)
        .type(InputType.Number)
        .onChange((v: string) => {
          if (side === 1) { this.barcode1 = v } else { this.barcode2 = v }
        })
        .onSubmit(() => { this.searchByBarcode(side) })
        .accessibilityText('条码输入')
        .accessibilityLevel('yes')

      Text($r('app.string.food_compare_from_history'))
        .fontSize(12)
        .fontColor(COLORS.PRIMARY)
        .margin({ top: 8 })
        .onClick(() => {
          this.pickingSide = side
          this.showHistoryPicker = true
        })
        .accessibilityText('从历史选择')
        .accessibilityLevel('yes')

      if (this.savedSnapshots.length > 0) {
        Text($r('app.string.select_snapshot'))
          .fontSize(12)
          .fontColor(COLORS.ACCENT_PURPLE_9C27)
          .margin({ top: 4 })
          .onClick(() => {
            this.pickingSide = side
            this.pickFromSnapshot(side)
          })
          .accessibilityText('选择快照')
          .accessibilityLevel('yes')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLORS.BG_LIGHT)
    .borderRadius(RADIUS.MD)
  }

  @Builder
  selectedFoodCard(food: FoodLabel, side: 1 | 2) {
    Column() {
      Text(food.foodName).fontSize(13).fontWeight(FontWeight.Medium).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(food.manufacturer).fontSize(10).fontColor(COLORS.TEXT_TERTIARY).margin({ top: 2 })
      Text($r('app.string.food_compare_replace'))
        .fontSize(11)
        .fontColor(COLORS.PRIMARY)
        .margin({ top: 4 })
        .onClick(() => {
          if (side === 1) { this.food1 = null } else { this.food2 = null }
        })
        .accessibilityText('替换食品')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLORS.BG_LIGHT)
    .borderRadius(RADIUS.MD)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  historyPickerSheet() {
    Column() {
      Row() {
        Text($r('app.string.food_compare_select_food')).fontSize(16).fontWeight(FontWeight.Bold)
        Blank()
        Text($r('app.string.food_compare_close')).fontSize(14).fontColor(COLORS.PRIMARY).onClick(() => {
          this.showHistoryPicker = false
        })
        .accessibilityText('关闭')
        .accessibilityLevel('yes')
      }
      .width('100%')
      .padding(16)

      List() {
        ForEach(this.recentFoods, (food: FoodLabel) => {
          ListItem() {
            Row() {
              Column() {
                Text(food.foodName).fontSize(14).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(food.manufacturer).fontSize(11).fontColor(COLORS.TEXT_TERTIARY).margin({ top: 2 })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .onClick(() => {
              if (this.pickingSide === 1) { this.food1 = food } else { this.food2 = food }
              this.showHistoryPicker = false
            })
            .accessibilityText(food.foodName)
            .accessibilityLevel('yes')
          }
        }, (food: FoodLabel, index: number) => `${food.barcode}_${index}`)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: '#E0E0E0' })
    }
    .width('100%')
    .height('50%')
    .backgroundColor(COLORS.WHITE)
    .borderRadius({ topLeft: RADIUS.XL, topRight: RADIUS.XL })
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: -2 })
  }

  @Builder
  compareHeader() {
    Row() {
      Column() {
        Text(this.food1?.foodName ?? '').fontSize(14).fontWeight(FontWeight.Medium)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.food1?.manufacturer ?? '').fontSize(11).fontColor(COLORS.TEXT_GRAY_9E9E).margin({ top: 2 })
        if (this.food1 !== null && this.food1.source.length > 0) {
          Text(this.food1.source)
            .fontSize(9)
            .fontColor(COLORS.TEXT_TERTIARY)
            .backgroundColor(COLORS.BG_LIGHTER_GRAY_F8)
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .padding({ right: 8 })

      Text('VS').fontSize(16).fontWeight(FontWeight.Bold).fontColor(COLORS.TEXT_GRAY_9E9E)

      Column() {
        Text(this.food2?.foodName ?? '').fontSize(14).fontWeight(FontWeight.Medium)
          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.food2?.manufacturer ?? '').fontSize(11).fontColor(COLORS.TEXT_GRAY_9E9E).margin({ top: 2 })
        if (this.food2 !== null && this.food2.source.length > 0) {
          Text(this.food2.source)
            .fontSize(9)
            .fontColor(COLORS.TEXT_TERTIARY)
            .backgroundColor(COLORS.BG_LIGHTER_GRAY_F8)
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .padding({ left: 8 })
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
  }

  @Builder
  nutrientDiffList() {
    Column() {
      Text($r('app.string.food_compare_nutrition_title')).fontSize(14).fontWeight(FontWeight.Bold).margin({ bottom: 12 })

      ForEach(this.buildNutrientDiffs(), (item: NutrientDiff) => {
        Row() {
          Text(item.value1.toFixed(1)).fontSize(13).fontColor(item.betterSide === 1 ? COLORS.ACCENT_GREEN_4CAF : COLORS.TEXT_PRIMARY)
            .layoutWeight(1).textAlign(TextAlign.End)

          Column() {
            Text(item.name).fontSize(12).fontColor(COLORS.TEXT_GRAY_6161)
            Text(item.unit).fontSize(10).fontColor(COLORS.TEXT_GRAY_9E9E)
          }
          .width(80)
          .alignItems(HorizontalAlign.Center)

          Text(item.value2.toFixed(1)).fontSize(13).fontColor(item.betterSide === 2 ? COLORS.ACCENT_GREEN_4CAF : COLORS.TEXT_PRIMARY)
            .layoutWeight(1).textAlign(TextAlign.Start)
        }
        .width('100%')
        .padding({ top: 6, bottom: 6 })
        .alignItems(VerticalAlign.Center)
      }, (item: NutrientDiff, index: number) => `${index}`)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  conclusionSection() {
    Column() {
      Text($r('app.string.food_compare_conclusion_title')).fontSize(14).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
      Text(this.buildConclusion()).fontSize(13).fontColor(COLORS.TEXT_SECONDARY).lineHeight(20)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  private buildNutrientDiffs(): NutrientDiff[] {
    const n1 = this.food1?.nutrition ?? new NutritionPer100g();
    const n2 = this.food2?.nutrition ?? new NutritionPer100g();

    const items: NutrientDiff[] = [
      this.diffItem($r('app.string.food_compare_calories'), 'kcal', n1.calories, n2.calories, true),
      this.diffItem($r('app.string.food_compare_protein'), 'g', n1.protein, n2.protein, false),
      this.diffItem($r('app.string.food_compare_fat'), 'g', n1.fat, n2.fat, true),
      this.diffItem($r('app.string.food_compare_carbohydrate'), 'g', n1.carbohydrate, n2.carbohydrate, true),
      this.diffItem($r('app.string.food_compare_sugar'), 'g', n1.sugar, n2.sugar, true),
      this.diffItem($r('app.string.food_compare_sodium'), 'mg', n1.sodium, n2.sodium, true),
      this.diffItem($r('app.string.food_compare_fiber'), 'g', n1.fiber, n2.fiber, false),
    ];

    return items;
  }

  private diffItem(name: ResourceStr, unit: string, v1: number, v2: number, lowerIsBetter: boolean): NutrientDiff {
    const diff = v2 - v1;
    let betterSide: 1 | 2 | 0 = 0;
    if (Math.abs(diff) > 0.01) {
      if (lowerIsBetter) {
        betterSide = diff > 0 ? 1 : 2;
      } else {
        betterSide = diff > 0 ? 2 : 1;
      }
    }
    const d = new NutrientDiff();
    d.name = name; d.unit = unit; d.value1 = v1; d.value2 = v2; d.diff = diff; d.betterSide = betterSide;
    return d;
  }

  private buildConclusion(): string {
    if (this.food1 !== null && this.food2 !== null) {
      const result = this.compareService.compare(this.food1, this.food2);
      this.compareResult = result;
      return result.verdict;
    }
    const diffs = this.buildNutrientDiffs();
    const better1 = diffs.filter(d => d.betterSide === 1);
    const better2 = diffs.filter(d => d.betterSide === 2);
    const name1 = this.food1?.foodName ?? '食品A';
    const name2 = this.food2?.foodName ?? '食品B';

    if (better1.length > better2.length) {
      return `综合来看，${name1} 在 ${better1.map(d => resourceToStr(d.name)).join('、')} 方面优于${name2} 在 ${better2.map(d => resourceToStr(d.name)).join('、') || '无明显优势'} 方面`;
    } else if (better2.length > better1.length) {
      return `综合来看，${name2} 在 ${better2.map(d => resourceToStr(d.name)).join('、')} 方面优于${name1} 在 ${better1.map(d => resourceToStr(d.name)).join('、') || '无明显优势'} 方面`;
    }
    return '两种食品营养表现相当';
  }

  private async searchByBarcode(side: 1 | 2): Promise<void> {
    const barcode = side === 1 ? this.barcode1 : this.barcode2;
    if (barcode.length < 4) {
      ToastHelper.show(this.mContext, $r('app.string.food_compare_invalid_barcode'));
      return;
    }
    this.isLoading = true;
    try {
      const food = await this.appState.foodRepo.findByBarcode(barcode);
      if (!this.componentActive) return;
      if (food !== null) {
        if (side === 1) { this.food1 = food } else { this.food2 = food }
      } else {
        ToastHelper.show(this.mContext, $r('app.string.food_compare_barcode_not_found'));
      }
    } catch (e) {
      if (!this.componentActive) return;
      hilog.warn(DOMAIN_ZERO, TAG, 'Search barcode failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.mContext, $r('app.string.food_compare_query_failed'));
    }
    this.isLoading = false;
  }

  private pickFromSnapshot(side: 1 | 2): void {
    if (this.savedSnapshots.length === 0) {
      ToastHelper.show(this.mContext, $r('app.string.food_compare_no_snapshot'));
      return;
    }
    const snapshot = this.savedSnapshots[0];
    const food = new FoodLabel();
    food.foodId = snapshot.id;
    food.foodName = snapshot.foodName;
    food.manufacturer = snapshot.brand;
    food.nutrition = snapshot.nutrition;
    if (side === 1) { this.food1 = food } else { this.food2 = food }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}

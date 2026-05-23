// QuickFoodInput.ets
// 饮食记录快捷录入组件 - 底部弹窗形式

import { NutritionPer100g, COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, DietRecord, OfflineFoodEntry, HILOG_DOMAIN } from 'hsp_core';
import { getOfflineFoodDatabase } from '../service/OfflineFoodDatabase';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG_QFI = 'QuickFoodInput';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

export class QuickFoodInputResult {
  foodName: string = '';
  mealType: string = 'lunch';
  servings: number = 1;
  nutrition: NutritionPer100g = new NutritionPer100g();
  barcode: string = '';
}

const MEAL_OPTIONS: string[] = ['breakfast', 'lunch', 'dinner', 'snack'];
const MEAL_LABELS: Map<string, string> = new Map();
MEAL_LABELS.set('breakfast', `🌅 ${$r('app.string.meal_breakfast') as string}`);
MEAL_LABELS.set('lunch', `☀️ ${$r('app.string.meal_lunch') as string}`);
MEAL_LABELS.set('dinner', `🌙 ${$r('app.string.meal_dinner') as string}`);
MEAL_LABELS.set('snack', `🍪 ${$r('app.string.meal_snack') as string}`);

const SERVING_OPTIONS: number[] = [0.5, 1, 1.5, 2];

@ComponentV2
export struct QuickFoodInput {
  @Param defaultMealType: string = 'lunch'
  @Param memberId: string = ''
  @Event onConfirm: (result: QuickFoodInputResult) => void = (_r: QuickFoodInputResult) => {}
  @Local showSheet: boolean = false
  @Local searchQuery: string = ''
  @Local searchResults: OfflineFoodEntry[] = []
  @Local recentFoods: DietRecord[] = []
  @Local selectedEntry: OfflineFoodEntry | null = null
  @Local selectedMealType: string = 'lunch'
  @Local selectedServings: number = 1
  @Local gramsInput: string = ''
  @Local useGrams: boolean = false
  @Local showAdvanced: boolean = false
  @Local manualFoodName: string = ''
  @Local manualCalories: string = ''
  @Local manualSodium: string = ''
  @Local manualSugar: string = ''
  @Local manualFat: string = ''

  private appState: AppState = AppState.getInstance()
  private mContext: UIContext | undefined = undefined

  async aboutToAppear(): Promise<void> {
    this.selectedMealType = this.defaultMealType;
    try {
      this.recentFoods = await this.appState.getTodayDietRecords(this.memberId);
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG_QFI, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.recentFoods = [];
    }
  }

  open(): void {
    this.showSheet = true;
  }

  build() {
    Column() {
      // 触发按钮不在这里，由父组件控制 showSheet
    }
    .bindSheet($$this.showSheet, this.buildSheetContent(), {
      height: SheetSize.LARGE,
      showClose: true,
      onDisappear: () => { this.showSheet = false; }
    })
  }

  @Builder
  buildSheetContent() {
    Column() {
      Text($r('app.string.quick_food_input'))
        .fontSize(FONT_SIZE.TITLE)
        .fontWeight(FONT_WEIGHT.BOLD)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ bottom: SPACING.MD })

      // 餐次选择
      Row({ space: SPACING.SM }) {
        ForEach(MEAL_OPTIONS, (meal: string) => {
          Text(MEAL_LABELS.get(meal) ?? meal)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(this.selectedMealType === meal ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
            .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
            .borderRadius(RADIUS.FULL)
            .backgroundColor(this.selectedMealType === meal ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
            .onClick(() => { this.selectedMealType = meal; })
            .accessibilityText($r('app.string.select_meal'))
        }, (meal: string) => meal)
      }
      .width('100%')
      .margin({ bottom: SPACING.MD })

      // 搜索输入
      TextInput({ placeholder: $r('app.string.search_food_name'), text: $$this.searchQuery })
        .width('100%')
        .height(40)
        .borderRadius(RADIUS.MD)
        .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .padding({ left: SPACING.MD })
        .placeholderColor(COLORS.TEXT_GRAY_9E9E)
        .accessibilityText($r('app.string.search_food'))
        .accessibilityDescription($r('app.string.search_food_desc'))
        .onChange((v: string) => { this.onSearchChange(v); })

      // 搜索结果
      if (this.searchQuery.length > 0 && this.searchResults.length > 0) {
        List() {
          ForEach(this.searchResults, (entry: OfflineFoodEntry) => {
            ListItem() {
              Row() {
                Column() {
                  Text(entry.foodName).fontSize(FONT_SIZE.BODY).fontColor(COLORS.TEXT_PRIMARY).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(entry.manufacturer).fontSize(FONT_SIZE.TINY).fontColor(COLORS.TEXT_GRAY_9E9E).margin({ top: 2 })
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
                if (this.selectedEntry !== null && this.selectedEntry.barcode === entry.barcode) {
                  Text('✓').fontSize(16).fontColor(COLORS.ACCENT_GREEN_4CAF)
                }
              }
              .width('100%')
              .padding({ top: SPACING.SM, bottom: SPACING.SM })
              .onClick(() => { this.selectedEntry = entry; })
              .accessibilityText($r('app.string.select_food'))
            }
          }, (entry: OfflineFoodEntry) => entry.barcode)
        }
        .width('100%')
        .height(120)
        .margin({ top: SPACING.SM })
      } else if (this.searchQuery.length > 0 && this.searchResults.length === 0) {
        Text($r('app.string.no_search_result'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .margin({ top: SPACING.SM })
      }

      // 最近录入（搜索为空时显示）
      if (this.searchQuery.length === 0 && this.recentFoods.length > 0) {
        Text($r('app.string.recent_foods'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.TEXT_GRAY_6161)
          .margin({ top: SPACING.MD, bottom: SPACING.SM })
        Scroll() {
          Row({ space: SPACING.SM }) {
            ForEach(this.recentFoods.slice(0, 10), (record: DietRecord) => {
              Text(record.scenario || $r('app.string.unknown_food') as string)
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_PRIMARY)
                .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
                .borderRadius(RADIUS.FULL)
                .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                .maxLines(1)
                .constraintSize({ maxWidth: 120 })
            }, (record: DietRecord) => `${record.id}`)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
      } else if (this.searchQuery.length === 0 && this.recentFoods.length === 0) {
        Column() {
          Text('📋')
            .fontSize(28)
          Text($r('app.string.no_recent_records'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.SM })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: SPACING.MD })
      }

      // 份量选择
      if (this.selectedEntry !== null) {
        Row() {
          Text($r('app.string.servings'))
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ right: SPACING.MD })
          ForEach(SERVING_OPTIONS, (s: number) => {
            Text(s.toString())
              .fontSize(FONT_SIZE.BODY)
              .fontColor(this.selectedServings === s ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
              .padding({ left: SPACING.MD, right: SPACING.MD, top: SPACING.SM, bottom: SPACING.SM })
              .borderRadius(RADIUS.SM)
              .backgroundColor(this.selectedServings === s ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
              .onClick(() => { this.selectedServings = s; this.useGrams = false; })
              .accessibilityText($r('app.string.select_servings'))
          }, (s: number) => s.toString())
          Text($r('app.string.or_grams'))
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.PRIMARY)
            .margin({ left: SPACING.SM })
            .onClick(() => { this.useGrams = !this.useGrams; })
            .accessibilityText($r('app.string.toggle_grams'))
        }
        .width('100%')
        .margin({ top: SPACING.MD })

        if (this.useGrams) {
          TextInput({ placeholder: $r('app.string.grams_placeholder') as string, text: $$this.gramsInput })
            .width('100%')
            .height(36)
            .type(InputType.Number)
            .borderRadius(RADIUS.SM)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .margin({ top: SPACING.SM })
            .accessibilityText($r('app.string.input_grams'))
            .accessibilityDescription($r('app.string.input_grams_desc'))
        }
      }

      // 高级模式（手动输入）
      Row() {
        Text($r('app.string.advanced_mode'))
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { this.showAdvanced = !this.showAdvanced; })
          .accessibilityText($r('app.string.toggle_advanced'))
      }
      .width('100%')
      .margin({ top: SPACING.MD })

      if (this.showAdvanced) {
        this.buildAdvancedInputs()
      }

      // 确认按钮
      Button($r('app.string.confirm_add'))
        .width('100%')
        .height(44)
        .margin({ top: SPACING.LG })
        .backgroundColor(COLORS.PRIMARY)
        .fontColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .enabled(this.canConfirm())
        .onClick(() => { this.doConfirm(); })
        .accessibilityText($r('app.string.confirm_add'))
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.MD, bottom: SPACING.LG })
  }

  @Builder
  buildAdvancedInputs() {
    Column({ space: SPACING.SM }) {
      TextInput({ placeholder: $r('app.string.food_name_hint'), text: $$this.manualFoodName })
        .width('100%').height(36).borderRadius(RADIUS.SM).backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .accessibilityText($r('app.string.input_food_name')).accessibilityDescription($r('app.string.input_food_name_desc'))
      TextInput({ placeholder: $r('app.string.calories_placeholder') as string, text: $$this.manualCalories })
        .width('100%').height(36).type(InputType.Number).borderRadius(RADIUS.SM).backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .accessibilityText($r('app.string.input_calories')).accessibilityDescription($r('app.string.input_calories_desc'))
      TextInput({ placeholder: $r('app.string.sodium_placeholder') as string, text: $$this.manualSodium })
        .width('100%').height(36).type(InputType.Number).borderRadius(RADIUS.SM).backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .accessibilityText($r('app.string.input_sodium')).accessibilityDescription($r('app.string.input_sodium_desc'))
      TextInput({ placeholder: $r('app.string.sugar_placeholder') as string, text: $$this.manualSugar })
        .width('100%').height(36).type(InputType.Number).borderRadius(RADIUS.SM).backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .accessibilityText($r('app.string.input_sugar')).accessibilityDescription($r('app.string.input_sugar_desc'))
      TextInput({ placeholder: $r('app.string.fat_placeholder') as string, text: $$this.manualFat })
        .width('100%').height(36).type(InputType.Number).borderRadius(RADIUS.SM).backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
        .accessibilityText($r('app.string.input_fat')).accessibilityDescription($r('app.string.input_fat_desc'))
    }
    .width('100%')
    .margin({ top: SPACING.SM })
  }

  private onSearchChange(query: string): void {
    this.searchQuery = query;
    if (query.length === 0) {
      this.searchResults = [];
      return;
    }
    const lower = query.toLowerCase();
    const keywords = lower.split(/\s+/).filter((s: string) => s.length > 0);
    this.searchResults = getOfflineFoodDatabase().filter((entry: OfflineFoodEntry) => {
      const nameLower = entry.foodName.toLowerCase();
      const mfrLower = entry.manufacturer.toLowerCase();
      const catLower = entry.category.toLowerCase();
      if (nameLower.includes(lower) || mfrLower.includes(lower) || catLower.includes(lower)) {
        return true;
      }
      if (keywords.length > 1) {
        return keywords.every((kw: string) => nameLower.includes(kw) || mfrLower.includes(kw));
      }
      return false;
    }).slice(0, 20);
  }

  private canConfirm(): boolean {
    if (this.showAdvanced && this.manualFoodName.length > 0) {
      return true;
    }
    return this.selectedEntry !== null;
  }

  private doConfirm(): void {
    const result = new QuickFoodInputResult();
    result.mealType = this.selectedMealType;

    if (this.showAdvanced && this.manualFoodName.length > 0) {
      result.foodName = this.manualFoodName;
      const n = new NutritionPer100g();
      n.calories = parseFloat(this.manualCalories) || 0;
      n.sodium = parseFloat(this.manualSodium) || 0;
      n.sugar = parseFloat(this.manualSugar) || 0;
      n.fat = parseFloat(this.manualFat) || 0;
      result.nutrition = n;
      result.servings = this.selectedServings;
    } else if (this.selectedEntry !== null) {
      const sel = this.selectedEntry
      result.foodName = sel.foodName;
      result.nutrition = sel.nutrition;
      result.barcode = sel.barcode;
      if (this.useGrams) {
        const grams = parseFloat(this.gramsInput) || 0;
        if (grams <= 0) {
          return;
        }
        result.servings = grams / 100;
      } else {
        if (this.selectedServings <= 0) {
          return;
        }
        result.servings = this.selectedServings;
      }
    }

    this.onConfirm(result);
    this.showSheet = false;
    this.resetState();
  }

  private resetState(): void {
    this.searchQuery = '';
    this.searchResults = [];
    this.selectedEntry = null;
    this.selectedServings = 1;
    this.gramsInput = '';
    this.useGrams = false;
    this.showAdvanced = false;
    this.manualFoodName = '';
    this.manualCalories = '';
    this.manualSodium = '';
    this.manualSugar = '';
    this.manualFat = '';
  }
}

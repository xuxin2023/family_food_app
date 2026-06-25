import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT, FoodLabel, NutritionPer100g } from 'hsp_core';

const TAG = 'AlternativeComparePanel';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export interface NutritionDelta {
  calories: number;
  sugar: number;
  sodium: number;
  fat: number;
  protein: number;
  fiber: number;
}

export interface AlternativeCompareItem {
  original: FoodLabel;
  alternative: FoodLabel;
  nutritionDelta: NutritionDelta;
  verdict: 'better' | 'worse' | 'mixed';
  scoreDelta: number;
}

@ComponentV2
export struct AlternativeComparePanel {
  @Param originalFood: FoodLabel = new FoodLabel();
  @Param alternativeFood: FoodLabel = new FoodLabel();
  @Param onConfirmReplace: (() => void) | null = null;

  build() {
    Column({ space: 16 }) {
      Text('替代品营养对比')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      this.CompareRow('热量(kcal)', this.originalFood.nutrition.calories,
        this.alternativeFood.nutrition.calories, true)
      this.CompareRow('糖(g)', this.originalFood.nutrition.sugar,
        this.alternativeFood.nutrition.sugar, true)
      this.CompareRow('钠(mg)', this.originalFood.nutrition.sodium,
        this.alternativeFood.nutrition.sodium, true)
      this.CompareRow('脂肪(g)', this.originalFood.nutrition.fat,
        this.alternativeFood.nutrition.fat, true)
      this.CompareRow('蛋白质(g)', this.originalFood.nutrition.protein,
        this.alternativeFood.nutrition.protein, false)
      this.CompareRow('膳食纤维(g)', this.originalFood.nutrition.fiber,
        this.alternativeFood.nutrition.fiber, false)

      this.VerdictSection()

      if (this.onConfirmReplace) {
        Row({ space: 12 }) {
          Button('保持原选')
            .layoutWeight(1)
            .backgroundColor('#F5F5F5')
            .fontColor('#333333')
          Button('确认替代')
            .layoutWeight(1)
            .backgroundColor('#1B8A3E')
            .fontColor('#FFFFFF')
            .onClick(() => {
              if (this.onConfirmReplace) this.onConfirmReplace();
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  CompareRow(label: string, originalVal: number, altVal: number, lowerIsBetter: boolean) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .width('25%')
      Text(`${originalVal.toFixed(1)}`)
        .fontSize(13)
        .textAlign(TextAlign.Center)
        .width('25%')
      Text(`${altVal.toFixed(1)}`)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
        .width('25%')
      Text(this.getDeltaText(altVal, originalVal))
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getDeltaColor(altVal, originalVal, lowerIsBetter))
        .textAlign(TextAlign.Center)
        .width('25%')
    }
    .width('100%')
  }

  @Builder
  VerdictSection() {
    Column() {
      Row({ space: 8 }) {
        Text(this.computeVerdict() === 'better' ? '✅' : this.computeVerdict() === 'worse' ? '⚠️' : '⚖️')
          .fontSize(20)
        Text(this.computeVerdict() === 'better' ? '替代品更优' :
          this.computeVerdict() === 'worse' ? '原选更优' : '各有优劣')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
      }
      if (this.computeVerdict() === 'mixed') {
        Text('替代品在某些营养素上更优，但其他方面原选更好，请根据健康目标选择')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 8, bottom: 8 })
  }

  private getDeltaText(altVal: number, originalVal: number): string {
    const delta = altVal - originalVal;
    return delta > 0 ? `+${delta.toFixed(1)}` : delta.toFixed(1);
  }

  private getDeltaColor(altVal: number, originalVal: number, lowerIsBetter: boolean): string {
    const delta = altVal - originalVal;
    if (delta === 0) return '#999999';
    const isImprovement = lowerIsBetter ? delta < 0 : delta > 0;
    return isImprovement ? '#1B8A3E' : '#E53935';
  }

  private computeVerdict(): 'better' | 'worse' | 'mixed' {
    const o = this.originalFood.nutrition;
    const a = this.alternativeFood.nutrition;
    let improvements = 0;
    let regressions = 0;
    if (a.calories < o.calories) improvements++; else if (a.calories > o.calories) regressions++;
    if (a.sugar < o.sugar) improvements++; else if (a.sugar > o.sugar) regressions++;
    if (a.sodium < o.sodium) improvements++; else if (a.sodium > o.sodium) regressions++;
    if (a.fat < o.fat) improvements++; else if (a.fat > o.fat) regressions++;
    if (a.protein > o.protein) improvements++; else if (a.protein < o.protein) regressions++;
    if (a.fiber > o.fiber) improvements++; else if (a.fiber < o.fiber) regressions++;

    if (improvements > 0 && regressions === 0) return 'better';
    if (regressions > 0 && improvements === 0) return 'worse';
    return 'mixed';
  }
}

export function computeNutritionDelta(original: NutritionPer100g, alternative: NutritionPer100g): NutritionDelta {
  return {
    calories: alternative.calories - original.calories,
    sugar: alternative.sugar - original.sugar,
    sodium: alternative.sodium - original.sodium,
    fat: alternative.fat - original.fat,
    protein: alternative.protein - original.protein,
    fiber: alternative.fiber - original.fiber
  };
}

// RatingVisualizer.ets
// 营养素RDA可视化渲染组件 — 对标Olive营养报告体验
// ArkUI Progress组件 + 色阶编码 + RDA对比

import { COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS } from 'hsp_core';

export class NutrientRdaItem {
  label: string = '';
  value: number = 0;
  unit: string = '';
  rda: number = 0;
  rdaLabel: string = '';
  isReverseScale: boolean = false;
}

@ComponentV2
export struct RatingVisualizer {
  @Param items: NutrientRdaItem[] = [];
  @Param showDetail: boolean = true;
  @Param compact: boolean = false;

  @Computed
  get sorted(): NutrientRdaItem[] {
    return [...this.items].sort((a: NutrientRdaItem, b: NutrientRdaItem) =>
      this.getRdaPercent(b) - this.getRdaPercent(a));
  }

  private getRdaPercent(item: NutrientRdaItem): number {
    if (item.rda <= 0) return 0;
    return Math.min(100, Math.round((item.value / item.rda) * 100));
  }

  private getBarColor(item: NutrientRdaItem): string {
    const pct = this.getRdaPercent(item);
    if (item.isReverseScale) {
      if (pct <= 50) return '#4CAF50';
      if (pct <= 80) return '#FFC107';
      return '#F44336';
    }
    if (pct >= 90) return '#4CAF50';
    if (pct >= 60) return '#FFC107';
    if (pct >= 30) return '#FF9800';
    return '#F44336';
  }

  build() {
    Column() {
      if (!this.compact) {
        Text('📊 每100g营养成分')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .margin({ bottom: SPACING.SMALL })
      }

      ForEach(this.sorted, (item: NutrientRdaItem) => {
        Column() {
          Row() {
            Text(item.label)
              .fontSize(this.compact ? FONT_SIZE.TINY : FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_SECONDARY)
              .width(this.compact ? 50 : 70)

            Progress({
              value: this.getRdaPercent(item),
              total: 100,
              type: ProgressType.Linear
            })
              .color(this.getBarColor(item))
              .layoutWeight(1)

            Column() {
              Text(`${item.value}${item.unit}`)
                .fontSize(this.compact ? FONT_SIZE.TINY : FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_PRIMARY)
                .fontWeight(FONT_WEIGHT.MEDIUM)

              if (item.rdaLabel.length > 0) {
                Text(item.rdaLabel)
                  .fontSize(10)
                  .fontColor(COLORS.TEXT_TERTIARY)
              }
            }
            .alignItems(HorizontalAlign.End)
            .width(this.compact ? 50 : 70)
            .margin({ left: 8 })
          }
          .width('100%')
          .height(this.compact ? 28 : 36)
        }
      })

      if (!this.compact && this.items.length > 0) {
        this.legendRow()
          .margin({ top: SPACING.SMALL })
      }
    }
    .width('100%')
  }

  @Builder
  legendRow() {
    Row() {
      this.legendDot('#4CAF50', '充足')
      this.legendDot('#FFC107', '适量')
      this.legendDot('#FF9800', '偏低')
      this.legendDot('#F44336', '不足')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  legendDot(color: string, label: string) {
    Row() {
      Circle({ width: 8, height: 8 })
        .fill(color)
      Text(label)
        .fontSize(10)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ left: 4, right: 12 })
    }
  }

  static fromFoodLabel(nutrition: Record<string, number>, sodium: number, sugar: number,
    calories: number, fat: number, protein: number, fiber: number,
    saturatedFat: number): NutrientRdaItem[] {

    return [
      { label: '热量', value: calories, unit: 'kcal', rda: 2000, rdaLabel: '2000/日',
        isReverseScale: false },
      { label: '蛋白质', value: protein, unit: 'g', rda: 60, rdaLabel: '60g/日',
        isReverseScale: false },
      { label: '脂肪', value: fat, unit: 'g', rda: 65, rdaLabel: '65g/日',
        isReverseScale: true },
      { label: '碳水', value: nutrition.carbohydrate ?? 0, unit: 'g', rda: 300,
        rdaLabel: '300g/日', isReverseScale: false },
      { label: '纤维素', value: fiber, unit: 'g', rda: 25, rdaLabel: '25g/日',
        isReverseScale: false },
      { label: '钠', value: sodium, unit: 'mg', rda: 2000, rdaLabel: '2000mg/日',
        isReverseScale: true },
      { label: '糖', value: sugar, unit: 'g', rda: 50, rdaLabel: '50g/日',
        isReverseScale: true },
      { label: '饱和脂肪', value: saturatedFat, unit: 'g', rda: 20, rdaLabel: '20g/日',
        isReverseScale: true },
    ];
  }
}
// FoodDetailPage.ets
// 食品详情页 — 对标Yuka详情页（成分解析 + 营养评级 + 过敏原预警 + 替代品推荐）
// 三段式布局：评级概览 | 成分解析 | 推荐与预警

import { router } from '@kit.ArkUI';
import {
  COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS,
  safeBack, FoodLabel, NutritionPer100g, AlternativeFood,
  Recommendation, RecommendLevel, AllergyHint, Severity,
  HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import {
  NutriScoreBadge, AllergenHighlightList, AlternativeCard, AlternativeFoodItem,
  AllergyAlertBanner, AllergyAlertData
} from 'feature_scan';
import { NovaGroupBadge, EcoScoreBadge } from 'feature_report';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'FoodDetailPage';

class ParsedIngredientItem {
  name: string = '';
  role: string = '';
  hazardLevel: string = '';
  hazardColor: string = '';
  detail: string = '';
}

@Entry
@ComponentV2
struct FoodDetailPage {
  @Local foodLabel: FoodLabel = new FoodLabel();
  @Local nutriScore: number = 0;
  @Local nutriGrade: string = 'C';
  @Local novaGroup: number = 1;
  @Local ecoScoreGrade: string = '';
  @Local ecoScoreScore: number = 0;
  @Local ingredients: ParsedIngredientItem[] = [];
  @Local alternatives: AlternativeFoodItem[] = [];
  @Local allergyAlerts: AllergyAlertData[] = [];
  @Local selectedTab: number = 0;
  @Local isLoading: boolean = true;

  aboutToAppear(): void {
    this.loadFoodData();
  }

  async loadFoodData(): Promise<void> {
    this.isLoading = true;
    try {
      const params = router.getParams() as Record<string, Object> | null;
      if (params && params['foodLabel']) {
        this.foodLabel = params['foodLabel'] as FoodLabel;
        this.nutriScore = this.foodLabel.nutriScore;
        this.novaGroup = this.foodLabel.novaGroup;
        this.ecoScoreGrade = this.foodLabel.ecoScoreGrade;
        this.ecoScoreScore = this.foodLabel.ecoScoreScore;

        this.nutriGrade = this.calcGrade(this.nutriScore);
        this.ingredients = this.parseIngredients(this.foodLabel.ingredients);
        this.generateMockAlerts();
        this.generateMockAlternatives();
      }
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'loadFoodData failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;
  }

  private calcGrade(score: number): string {
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    if (score >= 20) return 'D';
    return 'E';
  }

  private parseIngredients(ingredients: string[]): ParsedIngredientItem[] {
    const hazards: Record<string, { level: string; color: string }> = {
      '糖': { level: '⚠注意', color: '#FF9800' },
      '盐': { level: '⚠注意', color: '#FF9800' },
      '棕榈油': { level: '⚠注意', color: '#FF9800' },
      '味精': { level: '⚡谨慎', color: '#FF5722' },
      '色素': { level: '⚡谨慎', color: '#FF5722' },
      '防腐剂': { level: '⚡谨慎', color: '#FF5722' },
    };

    return ingredients.map((ing: string) => {
      const item: ParsedIngredientItem = new ParsedIngredientItem()
      item.name = ing;
      item.role = '成分';
      item.hazardLevel = '✅ 安全';
      item.hazardColor = '#4CAF50';

      for (const kw of Object.keys(hazards)) {
        if (ing.includes(kw)) {
          item.hazardLevel = hazards[kw].level;
          item.hazardColor = hazards[kw].color;
          break;
        }
      }
      return item;
    });
  }

  private generateMockAlerts(): void {
    if (this.foodLabel.allergenHints.length > 0) {
      const alert: AllergyAlertData = new AllergyAlertData()
      alert.type = 'allergy';
      alert.severity = Severity.MODERATE;
      alert.memberName = '家人';
      alert.allergen = this.foodLabel.allergenHints[0];
      alert.advice = '含过敏原成分，请注意查看';
      alert.detail = `该食品标注含有${this.foodLabel.allergenHints.join('、')}`;
      this.allergyAlerts = [alert];
    }
  }

  private generateMockAlternatives(): void {
    if (this.nutriScore < 60) {
      const alt: AlternativeFoodItem = new AlternativeFoodItem()
      alt.productName = `更健康的${this.foodLabel.foodName}替代品`;
      alt.brand = '推荐品牌';
      alt.healthScore = Math.min(95, this.nutriScore + 25);
      alt.nutriGrade = this.calcGrade(alt.healthScore);
      alt.gradeColor = alt.nutriGrade === 'A' ? '#4CAF50' :
        alt.nutriGrade === 'B' ? '#66BB6A' : '#FFA726';
      alt.sodium_mg = Math.round(this.foodLabel.nutrition.sodium * 0.6);
      alt.sugar_g = parseFloat((this.foodLabel.nutrition.sugar * 0.5).toFixed(1));
      alt.energyKcal = Math.round(this.foodLabel.nutrition.calories * 0.8);
      alt.reason = `健康评分提升${alt.healthScore - this.nutriScore}分，更低钠低糖`;
      this.alternatives = [alt];
    }
  }

  build() {
    Column() {
      this.headerBar()

      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color(COLORS.PRIMARY)
          Text('加载食品信息...')
            .fontSize(FONT_SIZE.BODY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: SPACING.SMALL })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            this.ratingOverview()
            this.tabBar()
            if (this.selectedTab === 0) {
              this.ingredientsSection()
            } else if (this.selectedTab === 1) {
              this.nutritionSection()
            } else {
              this.warningsSection()
            }
            this.alternativesSection()
          }
          .width('100%')
          .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM, bottom: 80 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  headerBar() {
    Row() {
      Button({ type: ButtonType.Normal }) {
        Text('← 返回').fontSize(FONT_SIZE.BODY)
      }
      .height(36)
      .onClick(() => safeBack())

      Blank()

      Text(this.foodLabel.foodName)
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      Blank()

      Row().width(60)
    }
    .width('100%')
    .height(48)
    .padding({ left: SPACING.MEDIUM, right: SPACING.MEDIUM })
    .backgroundColor(COLORS.WHITE)
  }

  @Builder
  ratingOverview() {
    Column() {
      Row() {
        NutriScoreBadge({ grade: this.nutriGrade, score: this.nutriScore })
          .margin({ right: SPACING.SMALL })

        Column() {
          Text(this.nutriGrade === 'A' || this.nutriGrade === 'B' ? '👍 推荐食用' :
            this.nutriGrade === 'C' ? '👌 适量食用' :
            this.nutriGrade === 'D' ? '⚠️ 谨慎选择' : '🚫 建议避免')
            .fontSize(FONT_SIZE.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FONT_WEIGHT.BOLD)

          Text(`综合评级 ${this.nutriScore}/100`)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Row() {
        if (this.novaGroup > 0) {
          NovaGroupBadge({ group: this.novaGroup })
        }
        if (this.ecoScoreGrade.length > 0) {
          EcoScoreBadge({ grade: this.ecoScoreGrade, score: this.ecoScoreScore })
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .margin({ top: SPACING.SMALL })
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  tabBar() {
    Row() {
      this.tabButton('🧪 成分', 0)
      this.tabButton('📊 营养', 1)
      this.tabButton('⚠️ 预警', 2)
    }
    .width('100%')
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  tabButton(label: string, index: number) {
    Text(label)
      .fontSize(FONT_SIZE.SMALL)
      .fontColor(this.selectedTab === index ? COLORS.WHITE : COLORS.TEXT_SECONDARY)
      .fontWeight(this.selectedTab === index ? FONT_WEIGHT.MEDIUM : FONT_WEIGHT.REGULAR)
      .padding({ left: SPACING.SMALL, right: SPACING.SMALL, top: 8, bottom: 8 })
      .backgroundColor(this.selectedTab === index ? COLORS.PRIMARY : COLORS.WHITE)
      .borderRadius(RADIUS.SMALL)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.selectedTab = index })
  }

  @Builder
  ingredientsSection() {
    Column() {
      Text(`配料表 (${this.ingredients.length}项)`)
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      ForEach(this.ingredients, (item: ParsedIngredientItem, index: number) => {
        Row() {
          Column() {
            Text(item.hazardLevel)
              .fontSize(FONT_SIZE.TINY)
              .fontColor(item.hazardColor)
          }
          .width(64)
          .alignItems(HorizontalAlign.Center)

          Text(item.name)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_PRIMARY)
            .layoutWeight(1)

          Text(`${index + 1}`)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
        .backgroundColor(index % 2 === 0 ? '#FAFAFA' : COLORS.WHITE)
      })
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  nutritionSection() {
    Column() {
      Text('每100g营养成分')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      this.nutritionRow('热量', ` + '`${this.foodLabel.nutrition.calories}kcal`' + `, '2000kcal/日')
`
      this.nutritionRow('蛋白质', `${this.foodLabel.nutrition.protein}g`, '60g/日')
      this.nutritionRow('脂肪', `${this.foodLabel.nutrition.fat}g`, '65g/日')
`
      this.nutritionRow('钠', `${this.foodLabel.nutrition.sodium}mg`, '2000mg/日')
      this.nutritionRow('糖', `${this.foodLabel.nutrition.sugar}g`, '50g/日')
`
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  nutritionRow(label: string, value: string, rda: string) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .width(60)

      Text(value)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.MEDIUM)

      Text(rda)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
  }

  @Builder
  warningsSection() {
    Column() {
      Text('风险预警')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      if (this.allergyAlerts.length > 0) {
        ForEach(this.allergyAlerts, (alert: AllergyAlertData) => {
          AllergyAlertBanner({ data: alert })
            .margin({ top: 8 })
        })
      } else {
        Row() {
          Text('✅')
            .fontSize(20)
            .margin({ right: 8 })
          Text('未检测到已知过敏原风险')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.SUCCESS)
        }
        .margin({ top: 8 })
      }

      if (this.foodLabel.allergenHints.length > 0) {
        Column() {
          Text('标签过敏原提示')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
          ForEach(this.foodLabel.allergenHints, (hint: string) => {
            Text(`• ${hint}`)
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_SECONDARY)
              .margin({ top: 2 })
          })
        }
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding(SPACING.MEDIUM)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MEDIUM)
    .margin({ top: SPACING.SMALL })
  }

  @Builder
  alternativesSection() {
    if (this.alternatives.length > 0) {
      Column() {
        Row() {
          Text('🔄 更健康的替代品')
            .fontSize(FONT_SIZE.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .layoutWeight(1)
        }
        .width('100%')

        ForEach(this.alternatives, (alt: AlternativeFoodItem) => {
          AlternativeCard({ item: alt, isExpanded: true })
            .margin({ top: 8 })
        })
      }
      .width('100%')
      .padding(SPACING.MEDIUM)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MEDIUM)
      .margin({ top: SPACING.SMALL })
    }
  }
}
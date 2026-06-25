// FoodDetailPage.ets
// 食品详情页 — 对标Yuka详情页（成分解析 + 营养评级 + 过敏原预警 + 替代品推荐）
// 三段式布局：评级概览 | 成分解析 | 推荐与预警
// Sprint 5.3: 评分卡片重设计 + 红绿灯色系统一 + 动画

import { router } from '@kit.ArkUI';
import { curves } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import {
  COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS, SCORE_COLORS,
  safeBack, FoodLabel, NutritionPer100g, AlternativeFood,
  Recommendation, RecommendLevel, AllergyHint, Severity,
  HILOG_DOMAIN_DEFAULT,
  TcmFoodDatabase, TcmFoodEntry, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import {
  NutriScoreBadge, AllergenHighlightList, AlternativeCard, AlternativeFoodItem,
  AllergyAlertBanner, AllergyAlertData
} from 'feature_scan';
import { EcoScore } from 'feature_report';
import { ScTraceabilityParser, ScParseResult } from 'feature_report';
import { FoodHealthScoreCalculator, FoodHealthScoreBreakdown } from 'feature_scan';
import { AlternativeFoodRecommender } from 'feature_scan';
import { GbComplianceChecker, GbComplianceResult } from 'feature_scan';
import { ChildSafetyChecker, ChildSafetyResult } from 'feature_scan';
import { DataService } from 'hsp_service';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { LoadingSkeleton } from '../components/SkeletonScreen';

const TAG = 'FoodDetailPage';

class ParsedIngredientItem {
  name: string = '';
  role: string = '';
  hazardLevel: string = '';
  hazardColor: string = '';
  detail: string = '';
}

class HazardInfo {
  level: string = '';
  color: string = '';
}

class NutriPoint {
  icon: string = '';
  text: string = '';
  positive: boolean = true;
}

class NutrientTrafficLight {
  label: string = '';
  value: string = '';
  level: string = '';
  color: string = '';
  rda: string = '';
}

function gradeToColor(grade: string): string {
  if (grade === 'A') return SCORE_COLORS.GRADE_A;
  if (grade === 'B') return SCORE_COLORS.GRADE_B;
  if (grade === 'C') return SCORE_COLORS.GRADE_C;
  if (grade === 'D') return SCORE_COLORS.GRADE_D;
  return SCORE_COLORS.GRADE_E;
}

function scoreToColor(score: number): string {
  if (score >= 80) return SCORE_COLORS.GRADE_A;
  if (score >= 60) return SCORE_COLORS.GRADE_B;
  if (score >= 40) return SCORE_COLORS.GRADE_C;
  if (score >= 20) return SCORE_COLORS.GRADE_D;
  return SCORE_COLORS.GRADE_E;
}

function nutrientLevel(value: number, lowThreshold: number, highThreshold: number): string {
  if (value <= lowThreshold) return 'low';
  if (value <= highThreshold) return 'medium';
  return 'high';
}

function nutrientColor(level: string): string {
  if (level === 'low') return COLORS.LEVEL_GREEN;
  if (level === 'medium') return COLORS.LEVEL_YELLOW;
  return COLORS.LEVEL_RED;
}

function nutrientBgColor(level: string): string {
  if (level === 'low') return COLORS.BG_LIGHT_GREEN;
  if (level === 'medium') return COLORS.BG_WARM_ORANGE;
  return COLORS.BG_WARM_PINK;
}

@Entry
@ComponentV2
export struct FoodDetailPage {
  @Local foodLabel: FoodLabel = new FoodLabel();
  @Local nutriScore: number = 0;
  @Local nutriGrade: string = 'C';
  @Local novaGroup: number = 1;
  @Local ecoScoreGrade: string = '';
  @Local ecoScoreScore: number = 0;
  @Local healthScore: FoodHealthScoreBreakdown = new FoodHealthScoreBreakdown();
  @Local tcmEntry: TcmFoodEntry | null = null;
  @Local scResult: ScParseResult | null = null;
  @Local gbResult: GbComplianceResult = new GbComplianceResult();
  @Local childResult: ChildSafetyResult = new ChildSafetyResult();
  @Local ingredients: ParsedIngredientItem[] = [];
  @Local alternatives: AlternativeFoodItem[] = [];
  @Local allergyAlerts: AllergyAlertData[] = [];
  @Local selectedTab: number = 0;
  @Local isLoading: boolean = true;

  // 动画状态
  @Local displayScore: number = 0;
  @Local ringProgress: number = 0;
  @Local cardOpacity: number = 0;
  @Local cardOffsetY: number = 20;

  // 优缺点
  @Local positivePoints: NutriPoint[] = [];
  @Local negativePoints: NutriPoint[] = [];

  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#FFF8E1', 0.0], ['#FFF3E0', 0.3], ['#FCE4EC', 0.7], ['#F3E5F5', 1.0]] };
  }

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
        this.healthScore = FoodHealthScoreCalculator.calculate(this.foodLabel);
        this.nutriScore = this.healthScore.totalScore;
        this.nutriGrade = this.healthScore.grade;
        this.ingredients = this.parseIngredients(this.foodLabel.ingredients);
        this.generateAllergyAlerts();
        this.loadTcmData();
        this.loadScData();
        this.gbResult = GbComplianceChecker.check(this.foodLabel);
        this.childResult = ChildSafetyChecker.check(this.foodLabel);
        this.computePositiveNegative();
        await this.loadAlternatives();
      }
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'loadFoodData failed: %{public}s', JSON.stringify(e));
    }
    this.isLoading = false;

    // 启动入场动画
    this.startEntranceAnimation();
  }

  private startEntranceAnimation(): void {
    this.displayScore = 0;
    this.ringProgress = 0;
    this.cardOpacity = 0;
    this.cardOffsetY = 20;

    // 卡片淡入 + 上移
    this.getUIContext()?.animateTo({
      duration: 400,
      curve: Curve.EaseOut,
      delay: 100
    }, () => {
      this.cardOpacity = 1;
      this.cardOffsetY = 0;
    });

    // 评分数字滚动
    const targetScore: number = this.healthScore.totalScore;
    const steps: number = 30;
    const stepDuration: number = 20;
    let currentStep: number = 0;
    const intervalId = setInterval(() => {
      currentStep++;
      const progress: number = currentStep / steps;
      this.displayScore = Math.round(targetScore * progress);
      this.ringProgress = progress * 360;
      if (currentStep >= steps) {
        clearInterval(intervalId);
        this.displayScore = targetScore;
        this.ringProgress = 360;
      }
    }, stepDuration);
  }

  private calcGrade(score: number): string {
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    if (score >= 20) return 'D';
    return 'E';
  }

  private gradeStartColor(grade: string): string {
    if (grade === 'A') return '#43A047';
    if (grade === 'B') return '#66BB6A';
    if (grade === 'C') return '#FFA726';
    if (grade === 'D') return SCORE_COLORS.GRADE_D;
    return '#EF5350';
  }

  private gradeEndColor(grade: string): string {
    if (grade === 'A') return '#2E7D32';
    if (grade === 'B') return '#43A047';
    if (grade === 'C') return '#F57C00';
    if (grade === 'D') return '#E64A19';
    return '#C62828';
  }

  private getEcoScoreEnum(grade: string): EcoScore {
    switch (grade) {
      case 'A': return EcoScore.A;
      case 'B': return EcoScore.B;
      case 'C': return EcoScore.C;
      case 'D': return EcoScore.D;
      case 'E': return EcoScore.E;
      default: return EcoScore.UNKNOWN;
    }
  }

  private parseIngredients(ingredients: string[]): ParsedIngredientItem[] {
    const hazards: Record<string, HazardInfo> = {
      '糖': { level: '⚠注意', color: COLORS.LEVEL_YELLOW } as HazardInfo,
      '盐': { level: '⚠注意', color: COLORS.LEVEL_YELLOW } as HazardInfo,
      '棕榈油': { level: '⚠注意', color: COLORS.LEVEL_YELLOW } as HazardInfo,
      '味精': { level: '⚡谨慎', color: COLORS.LEVEL_ORANGE } as HazardInfo,
      '色素': { level: '⚡谨慎', color: COLORS.LEVEL_ORANGE } as HazardInfo,
      '防腐剂': { level: '⚡谨慎', color: COLORS.LEVEL_ORANGE } as HazardInfo,
    };

    return ingredients.map((ing: string) => {
      const item: ParsedIngredientItem = new ParsedIngredientItem()
      item.name = ing;
      item.role = '成分';
      item.hazardLevel = '✅ 安全';
      item.hazardColor = COLORS.LEVEL_GREEN;

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

  private loadTcmData(): void {
    const db: TcmFoodDatabase = new TcmFoodDatabase();
    this.tcmEntry = db.lookup(this.foodLabel.foodName);
  }

  private loadScData(): void {
    if (this.foodLabel.scNumber.length > 0) {
      this.scResult = ScTraceabilityParser.parse(this.foodLabel.scNumber);
    }
  }

  private generateAllergyAlerts(): void {
    this.allergyAlerts = [];
    try {
      const appState = AppState.getInstance();
      const members = appState.getAllMembersSync();
      const foodAllergens = this.foodLabel.allergenHints;

      for (let i = 0; i < members.length; i++) {
        const member = members[i];
        if (member.allergens.length === 0) continue;

        for (let j = 0; j < member.allergens.length; j++) {
          const memberAllergen = member.allergens[j];
          let matched = false;
          for (let k = 0; k < foodAllergens.length; k++) {
            if (foodAllergens[k] === memberAllergen ||
              foodAllergens[k].includes(memberAllergen) ||
              memberAllergen.includes(foodAllergens[k])) {
              matched = true;
              break;
            }
          }

          if (matched) {
            const alert: AllergyAlertData = new AllergyAlertData();
            alert.type = 'allergy';
            alert.severity = Severity.SEVERE;
            alert.memberName = member.nickname;
            alert.allergen = memberAllergen;
            alert.advice = member.nickname + '对' + memberAllergen + '过敏，请勿食用';
            alert.detail = '该食品标注含有: ' + foodAllergens.join('、') + '。' + member.nickname + '的过敏原包括: ' + member.allergens.join('、');
            this.allergyAlerts.push(alert);
            break;
          }
        }
      }

      // 如果食品有过敏原但没有匹配到任何成员，显示通用提示
      if (this.allergyAlerts.length === 0 && foodAllergens.length > 0) {
        const alert: AllergyAlertData = new AllergyAlertData();
        alert.type = 'allergy';
        alert.severity = Severity.MODERATE;
        alert.memberName = '';
        alert.allergen = foodAllergens[0];
        alert.advice = '该食品含常见过敏原，家庭成员如对以下成分过敏请避免食用';
        alert.detail = '标注过敏原: ' + foodAllergens.join('、');
        this.allergyAlerts = [alert];
      }
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'generateAllergyAlerts failed: %{public}s', JSON.stringify(e));
      // 回退到基本提示
      if (this.foodLabel.allergenHints.length > 0) {
        const alert: AllergyAlertData = new AllergyAlertData();
        alert.type = 'allergy';
        alert.severity = Severity.MODERATE;
        alert.memberName = '家人';
        alert.allergen = this.foodLabel.allergenHints[0];
        alert.advice = '含过敏原成分，请注意查看';
        alert.detail = '该食品标注含有' + this.foodLabel.allergenHints.join('、');
        this.allergyAlerts = [alert];
      }
    }
  }

  private computePositiveNegative(): void {
    const n: NutritionPer100g = this.foodLabel.nutrition;
    const pos: NutriPoint[] = [];
    const neg: NutriPoint[] = [];
    if (n.sodium <= 120) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🧂'; p.text = '低钠'; p.positive = true; pos.push(p);
    }
    if (n.sugar <= 5) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🍬'; p.text = '低糖'; p.positive = true; pos.push(p);
    }
    if (n.protein >= 10) {
      const p: NutriPoint = new NutriPoint(); p.icon = '💪'; p.text = '高蛋白'; p.positive = true; pos.push(p);
    }
    if (n.fiber >= 3) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🌾'; p.text = '高纤维'; p.positive = true; pos.push(p);
    }
    if (n.saturatedFat <= 1.5) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🥑'; p.text = '低饱和脂肪'; p.positive = true; pos.push(p);
    }
    if (n.calories <= 100) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🔥'; p.text = '低热量'; p.positive = true; pos.push(p);
    }
    if (n.sodium > 600) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🧂'; p.text = '高钠'; p.positive = false; neg.push(p);
    }
    if (n.sugar > 12.5) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🍬'; p.text = '高糖'; p.positive = false; neg.push(p);
    }
    if (n.fat > 17.5) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🧈'; p.text = '高脂肪'; p.positive = false; neg.push(p);
    }
    if (n.saturatedFat > 5) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🥓'; p.text = '高饱和脂肪'; p.positive = false; neg.push(p);
    }
    if (n.calories > 400) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🔥'; p.text = '高热量'; p.positive = false; neg.push(p);
    }
    if (this.novaGroup >= 3) {
      const p: NutriPoint = new NutriPoint(); p.icon = '🏭'; p.text = '超加工食品'; p.positive = false; neg.push(p);
    }
    this.positivePoints = pos;
    this.negativePoints = neg;
  }

  private async loadAlternatives(): Promise<void> {
    try {
      const dataService = DataService.getInstance();
      const alts = await dataService.getAlternatives(this.foodLabel, []);
      const items: AlternativeFoodItem[] = [];
      for (const a of alts) {
        const item: AlternativeFoodItem = new AlternativeFoodItem();
        item.productName = a.productName;
        item.brand = a.brand;
        item.healthScore = a.healthScore;
        item.nutriGrade = this.calcGrade(a.healthScore);
        item.gradeColor = item.nutriGrade === 'A' ? SCORE_COLORS.GRADE_A :
          item.nutriGrade === 'B' ? SCORE_COLORS.GRADE_B : SCORE_COLORS.GRADE_C;
        item.sodium_mg = a.sodium_mg;
        item.sugar_g = a.sugar_g;
        item.energyKcal = a.energyKcal;
        item.reason = a.reason;
        items.push(item);
      }
      items.sort((a: AlternativeFoodItem, b: AlternativeFoodItem) => b.healthScore - a.healthScore);
      this.alternatives = items;
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'loadAlternatives failed: %{public}s', JSON.stringify(e));
      this.alternatives = [];
    }
  }

  build() {
    Column() {
      this.headerBar()

      if (this.isLoading) {
        Column() {
          LoadingSkeleton({ variant: 'detail' })
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
            this.tcmSection()
            this.scTraceabilitySection()
            this.gbComplianceSection()
            this.childSafetySection()
            this.brandCalloutSection()
          }
          .width('100%')
          .padding({ left: SPACING.MD, right: SPACING.MD, bottom: 80 })
          .opacity(this.cardOpacity)
          .animation({ duration: 500, curve: Curve.EaseOut, delay: 200 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
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
    .padding({ left: SPACING.MD, right: SPACING.MD })
    .backgroundColor(COLORS.WHITE)
  }

  @Builder
  ratingOverview() {
    Column() {
      Column() {
        Row() {
          Text(this.foodLabel.foodName)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          if (this.novaGroup > 0) {
            Row() {
              Text('超加工 ' + this.novaGroup.toString() + ' 级')
                .fontSize(10)
                .fontColor('rgba(255,255,255,0.9)')
                .fontWeight(FontWeight.Medium)
            }
            .height(22)
            .borderRadius(11)
            .backgroundColor('rgba(255,255,255,0.25)')
            .padding({ left: 8, right: 8 })
            .margin({ left: 8 })
          }

          if (this.ecoScoreGrade.length > 0) {
            Row() {
              Text('环保 ' + this.ecoScoreGrade)
                .fontSize(10)
                .fontColor('rgba(255,255,255,0.9)')
                .fontWeight(FontWeight.Medium)
            }
            .height(22)
            .borderRadius(11)
            .backgroundColor('rgba(255,255,255,0.25)')
            .padding({ left: 8, right: 8 })
            .margin({ left: 6 })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16 })

        if (this.foodLabel.manufacturer.length > 0) {
          Text(this.foodLabel.manufacturer)
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.7)')
            .padding({ left: 20, right: 20 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Stack({ alignContent: Alignment.Center }) {
          Circle({ width: 140, height: 140 })
            .fill('none')
            .stroke('rgba(255,255,255,0.3)')
            .strokeWidth(10)

          Circle({ width: 140, height: 140 })
            .fill('none')
            .stroke(COLORS.WHITE)
            .strokeWidth(10)
            .strokeLineCap(LineCapStyle.Round)
            .startAngle(0)
            .sweepAngle(this.ringProgress)

          Column() {
            Text(this.displayScore.toString())
              .fontSize(44)
              .fontWeight(FontWeight.Bold)
              .fontColor(COLORS.WHITE)
            Text('/ 100')
              .fontSize(13)
              .fontColor('rgba(255,255,255,0.7)')
          }
        }
        .width(160)
        .height(160)
        .margin({ top: 20 })

        Row() {
          Text(this.healthScore.grade)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.WHITE)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor('rgba(255,255,255,0.3)')
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .margin({ top: 12 })

        Text(this.healthScore.grade === 'A' || this.healthScore.grade === 'B' ? '推荐食用' :
          this.healthScore.grade === 'C' ? '适量食用' :
          this.healthScore.grade === 'D' ? '谨慎选择' : '建议避免')
          .fontSize(16)
          .fontColor(COLORS.WHITE)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 8 })

        Text(this.healthScore.label)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.7)')
          .margin({ top: 2, bottom: 20 })
      }
      .width('100%')
      .linearGradient({
        angle: 135,
        colors: [[this.gradeStartColor(this.healthScore.grade), 0], [this.gradeEndColor(this.healthScore.grade), 1]]
      })
      .borderRadius({ topLeft: 0, topRight: 0, bottomLeft: 16, bottomRight: 16 })
      .alignItems(HorizontalAlign.Center)

      this.positiveNegativeCard()

      this.scoreBreakdownCard()
    }
    .width('100%')
    .opacity(this.cardOpacity)
    .offset({ y: this.cardOffsetY })
    .animation({ duration: 400, curve: Curve.EaseOut })
  }

  @Builder
  positiveNegativeCard() {
    if (this.positivePoints.length > 0 || this.negativePoints.length > 0) {
      Row() {
        if (this.positivePoints.length > 0) {
          Column() {
            Row() {
              Text('优点')
                .fontSize(13)
                .fontColor(COLORS.SUCCESS)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 6 })

            ForEach(this.positivePoints, (pt: NutriPoint) => {
              Row() {
                Text(pt.icon + ' ' + pt.text)
                  .fontSize(12)
                  .fontColor(COLORS.SUCCESS)
              }
              .margin({ top: 3 })
            })
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor(COLORS.BG_LIGHT_GREEN)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
        }

        if (this.negativePoints.length > 0) {
          Column() {
            Row() {
              Text('注意')
                .fontSize(13)
                .fontColor(COLORS.ERROR)
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .margin({ bottom: 6 })

            ForEach(this.negativePoints, (pt: NutriPoint) => {
              Row() {
                Text(pt.icon + ' ' + pt.text)
                  .fontSize(12)
                  .fontColor(COLORS.ERROR)
              }
              .margin({ top: 3 })
            })
          }
          .layoutWeight(1)
          .padding(12)
          .backgroundColor(COLORS.BG_WARM_PINK)
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: this.positivePoints.length > 0 ? 8 : 0 })
        }
      }
      .width('100%')
      .margin({ top: 8 })
    }
  }

  @Builder
  scoreBreakdownCard() {
    Column() {
      Text('评分明细')
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .margin({ bottom: 8 })

      this.scoreBar('营养质量', this.healthScore.nutriScore, 60, this.healthScore.nutriGrade)
      this.scoreBar('添加剂安全', this.healthScore.additiveScore, 30, '')
      this.scoreBar('有机认证', this.healthScore.organicScore, 10, '')

      if (this.healthScore.novaPenalty > 0) {
        Row() {
          Row() {
            Text('加工度扣分')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
          .layoutWeight(1)

          Row() {
            Text('-' + this.healthScore.novaPenalty)
              .fontSize(FONT_SIZE.TINY)
              .fontWeight(FontWeight.Medium)
              .fontColor(SCORE_COLORS.GRADE_D)
            Text('  NOVA ' + this.foodLabel.novaGroup)
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.healthScore.additiveResult.cappedAt49) {
        Row() {
          Text('⚠ 含高风险添加剂，添加剂分数封顶49')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.LEVEL_RED)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: 8, top: 6, bottom: 6, right: 8 })
        .backgroundColor(COLORS.BG_WARM_PINK)
        .borderRadius(RADIUS.SM)
        .margin({ top: 6 })
      }
    }
    .width('100%')
    .padding({ top: SPACING.SM })
    .border({ width: { top: 0.5 }, color: COLORS.BORDER })
    .margin({ top: SPACING.SM })
  }

  @Builder
  scoreBar(label: string, score: number, weight: number, grade: string) {
    Column() {
      Row() {
        Text(label)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
          .layoutWeight(1)

        Row() {
          Text(score.toString())
            .fontSize(FONT_SIZE.TINY)
            .fontWeight(FontWeight.Medium)
            .fontColor(scoreToColor(score))
          Text(' × ' + weight + '%')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
          if (grade.length > 0) {
            Text(' (' + grade + ')')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(gradeToColor(grade))
          }
        }
      }
      .width('100%')

      // 进度条
      Row() {
        Column()
          .width((score / 100 * 100).toFixed(0) + '%')
          .height(4)
          .backgroundColor(scoreToColor(score))
          .borderRadius(2)
      }
      .width('100%')
      .height(4)
      .backgroundColor(COLORS.BG_LIGHT)
      .borderRadius(2)
      .margin({ top: 4 })
    }
    .width('100%')
    .margin({ top: 6 })
  }

  @Builder
  tabBar() {
    Row() {
      this.tabButton('🧪 成分', 0)
      this.tabButton('📊 营养', 1)
      this.tabButton('⚠️ 预警', 2)
    }
    .width('100%')
    .margin({ top: SPACING.SM })
  }

  @Builder
  tabButton(label: string, index: number) {
    Text(label)
      .fontSize(FONT_SIZE.SMALL)
      .fontColor(this.selectedTab === index ? COLORS.WHITE : COLORS.TEXT_SECONDARY)
      .fontWeight(this.selectedTab === index ? FONT_WEIGHT.MEDIUM : FONT_WEIGHT.REGULAR)
      .padding({ left: SPACING.SM, right: SPACING.SM, top: 8, bottom: 8 })
      .backgroundColor(this.selectedTab === index ? COLORS.PRIMARY : COLORS.WHITE)
      .borderRadius(RADIUS.SM)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.selectedTab = index })
  }

  @Builder
  ingredientsSection() {
    Column() {
      Text('配料表 (' + this.ingredients.length + '项)')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)

      ForEach(this.ingredients, (item: ParsedIngredientItem, index: number) => {
        Row() {
          // 红绿灯色块
          Column()
            .width(4)
            .height(24)
            .borderRadius(2)
            .backgroundColor(item.hazardColor)
            .margin({ right: 8 })

          Text(item.hazardLevel)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(item.hazardColor)
            .width(56)

          Text(item.name)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_PRIMARY)
            .layoutWeight(1)

          Text('›')
            .fontSize(FONT_SIZE.MEDIUM)
            .fontColor(COLORS.TEXT_TERTIARY)

          Text((index + 1).toString())
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ left: 4 })
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 8, bottom: 8 })
        .backgroundColor(index % 2 === 0 ? COLORS.BG_LIGHT_GRAY_F9 : COLORS.WHITE)
        .borderRadius(RADIUS.SM)
        .margin({ top: 4 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/IngredientDetailPage',
            params: { ingredientName: item.name, foodLabel: this.foodLabel }
          })
        })
      })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  nutritionSection() {
    Column() {
      Text('每100g营养成分')
        .fontSize(FONT_SIZE.MEDIUM)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.BOLD)
        .margin({ bottom: 8 })

      Text('🚦 红绿灯：绿色=低含量(优) · 黄色=中等 · 红色=高含量(注意)')
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ bottom: 8 })

      this.nutritionTrafficRow('热量', this.foodLabel.nutrition.calories, 'kcal', 80, 400, '2000kcal/日', false)
      this.nutritionTrafficRow('蛋白质', this.foodLabel.nutrition.protein, 'g', 5, 20, '60g/日', false)
      this.nutritionTrafficRow('脂肪', this.foodLabel.nutrition.fat, 'g', 3, 17.5, '65g/日', false)
      this.nutritionTrafficRow('饱和脂肪', this.foodLabel.nutrition.saturatedFat, 'g', 1.5, 5, '20g/日', false)
      this.nutritionTrafficRow('碳水', this.foodLabel.nutrition.carbohydrate, 'g', 10, 30, '300g/日', false)
      this.nutritionTrafficRow('糖', this.foodLabel.nutrition.sugar, 'g', 5, 12.5, '50g/日', false)
      this.nutritionTrafficRow('钠', this.foodLabel.nutrition.sodium, 'mg', 120, 600, '2000mg/日', false)
      this.nutritionTrafficRow('膳食纤维', this.foodLabel.nutrition.fiber, 'g', 3, 6, '25g/日', true)
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .alignItems(HorizontalAlign.Start)
  }

  private computeLevel(value: number, lowTh: number, highTh: number, isFiber: boolean): string {
    if (isFiber) {
      if (value >= highTh) return 'low';
      else if (value >= lowTh) return 'medium';
      else return 'high';
    }
    return nutrientLevel(value, lowTh, highTh);
  }

  @Builder
  nutritionTrafficRow(label: string, value: number, unit: string, lowTh: number, highTh: number, rda: string, isFiber: boolean) {
    Row() {
      Column()
        .width(8)
        .height(8)
        .borderRadius(4)
        .backgroundColor(nutrientColor(this.computeLevel(value, lowTh, highTh, isFiber)))
        .margin({ right: 8 })

      Text(label)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_SECONDARY)
        .width(64)

      Text(value.toString() + unit)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.TEXT_PRIMARY)
        .fontWeight(FONT_WEIGHT.MEDIUM)
        .layoutWeight(1)

      Text(this.computeLevel(value, lowTh, highTh, isFiber) === 'low' ? (isFiber ? '高' : '低') : this.computeLevel(value, lowTh, highTh, isFiber) === 'medium' ? '中' : (isFiber ? '低' : '高'))
        .fontSize(10)
        .fontColor(COLORS.WHITE)
        .backgroundColor(nutrientColor(this.computeLevel(value, lowTh, highTh, isFiber)))
        .borderRadius(8)
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })

      Text(rda)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .backgroundColor(nutrientBgColor(this.computeLevel(value, lowTh, highTh, isFiber)))
    .borderRadius(RADIUS.SM)
    .margin({ top: 2 })
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
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
  }

  @Builder
  alternativesSection() {
    if (this.alternatives.length > 0) {
      Column() {
        Row() {
          if (this.healthScore.totalScore < 60) {
            Text('🔄 找到更好的替代品')
              .fontSize(FONT_SIZE.MEDIUM)
              .fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FONT_WEIGHT.BOLD)
              .layoutWeight(1)
          } else {
            Text('🔄 同类推荐')
              .fontSize(FONT_SIZE.MEDIUM)
              .fontColor(COLORS.TEXT_PRIMARY)
              .fontWeight(FONT_WEIGHT.BOLD)
              .layoutWeight(1)
          }
          Text(this.alternatives.length.toString() + '个')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
        .width('100%')

        ForEach(this.alternatives, (alt: AlternativeFoodItem) => {
          Row() {
            Column() {
              Text(alt.healthScore.toString())
                .fontSize(FONT_SIZE.LG)
                .fontWeight(FONT_WEIGHT.BOLD)
                .fontColor(COLORS.WHITE)
              Text(alt.nutriGrade)
                .fontSize(10)
                .fontColor(COLORS.WHITE)
            }
            .width(48)
            .height(48)
            .borderRadius(24)
            .backgroundColor(scoreToColor(alt.healthScore))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            Column() {
              Text(alt.productName)
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_PRIMARY)
                .fontWeight(FONT_WEIGHT.MEDIUM)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              if (alt.brand.length > 0) {
                Text(alt.brand)
                  .fontSize(FONT_SIZE.TINY)
                  .fontColor(COLORS.TEXT_TERTIARY)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .margin({ top: 2 })
              }
              Text(alt.reason)
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_SECONDARY)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            .margin({ left: 10 })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 10, bottom: 10 })
          .backgroundColor(COLORS.WHITE)
          .borderRadius(RADIUS.SM)
          .margin({ top: 6 })
          .onClick(() => {
            const altFood: FoodLabel = new FoodLabel()
            altFood.foodName = alt.productName
            altFood.manufacturer = alt.brand
            altFood.nutrition.sodium = alt.sodium_mg
            altFood.nutrition.sugar = alt.sugar_g
            altFood.nutrition.calories = alt.energyKcal
            altFood.nutriScore = alt.healthScore
            router.pushUrl({
              url: 'pages/FoodDetailPage',
              params: { foodLabel: altFood }
            })
          })
        })
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .margin({ top: SPACING.SM })
    }
  }

  @Builder
  tcmSection() {
    if (this.tcmEntry !== null) {
      Column() {
        Row() {
          Text('🌿 中医食性')
            .fontSize(FONT_SIZE.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Column() {
            Text(this.tcmEntry!.nature)
              .fontSize(FONT_SIZE.LG)
              .fontWeight(FONT_WEIGHT.BOLD)
              .fontColor(COLORS.WHITE)
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor(this.tcmNatureColor(this.tcmEntry!.nature))
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(this.tcmEntry!.foodName + ' · ' + this.tcmEntry!.flavors.join('') + '味')
              .fontSize(FONT_SIZE.SMALL)
              .fontColor(COLORS.TEXT_PRIMARY)
            Text('归' + this.tcmEntry!.meridians.join('、') + '经')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 10 })
        }
        .width('100%')
        .margin({ top: 8 })

        if (this.tcmEntry!.effects.length > 0) {
          Text('功效: ' + this.tcmEntry!.effects)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_SECONDARY)
            .margin({ top: 6 })
        }

        if (this.tcmEntry!.suitableFor.length > 0) {
          Text('✅ 宜: ' + this.tcmEntry!.suitableFor.join('、'))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.LEVEL_GREEN)
            .margin({ top: 4 })
        }

        if (this.tcmEntry!.avoidFor.length > 0) {
          Text('⚠️ 忌: ' + this.tcmEntry!.avoidFor.join('、'))
            .fontSize(FONT_SIZE.TINY)
            .fontColor(SCORE_COLORS.GRADE_D)
            .margin({ top: 2 })
        }
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .margin({ top: SPACING.SM })
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  scTraceabilitySection() {
    if (this.scResult !== null) {
      Column() {
        Row() {
          Text('🔍 SC溯源')
            .fontSize(FONT_SIZE.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
            .fontWeight(FONT_WEIGHT.BOLD)
            .layoutWeight(1)
          Text(this.scResult!.isValid ? '✅ 有效' : '❌ 无效')
            .fontSize(FONT_SIZE.TINY)
            .fontColor(this.scResult!.isValid ? COLORS.LEVEL_GREEN : COLORS.LEVEL_RED)
        }
        .width('100%')

        if (this.scResult!.isValid) {
          this.scInfoRow('SC编号', this.scResult!.scNumber)
          this.scInfoRow('生产企业省份', this.scResult!.provinceName)
          this.scInfoRow('食品类别', this.scResult!.categoryName)

          Row() {
            Text('📎 前往国家市监局查询')
              .fontSize(FONT_SIZE.TINY)
              .fontColor(COLORS.PRIMARY)
              .margin({ top: 8 })
          }
          .width('100%')
          .onClick(() => {
            const sysPasteboard = pasteboard.getSystemPasteboard();
            const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.scResult!.scNumber);
            sysPasteboard.setDataSync(pasteData);
            hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'SC number copied');
          })
        } else {
          Text(this.scResult!.detail)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.LEVEL_RED)
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .margin({ top: SPACING.SM })
      .alignItems(HorizontalAlign.Start)
    }
  }

  @Builder
  scInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_TERTIARY)
        .width(80)
      Text(value)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .layoutWeight(1)
    }
    .width('100%')
    .margin({ top: 4 })
  }

  private tcmNatureColor(nature: string): string {
    if (nature === '寒') return '#2196F3';
    if (nature === '凉') return '#64B5F6';
    if (nature === '平') return '#9E9E9E';
    if (nature === '温') return '#FF9800';
    if (nature === '热') return '#F44336';
    return '#9E9E9E';
  }

  @Builder
  gbComplianceSection() {
    Column() {
      Row() {
        Text('📋 GB标准合规')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .layoutWeight(1)
        Text(this.gbResult.isCompliant ? '✅ 合规' : '❌ 不合规')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(this.gbResult.isCompliant ? COLORS.LEVEL_GREEN : COLORS.LEVEL_RED)
      }
      .width('100%')

      if (this.gbResult.matchedStandard !== null) {
        Text(this.gbResult.matchedStandard!.standardCode + ' ' + this.gbResult.matchedStandard!.standardName)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ top: 4 })
      }

      Text(this.gbResult.summary)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ top: 4 })

      ForEach(this.gbResult.violations, (v: string) => {
        Text('• ' + v)
          .fontSize(FONT_SIZE.TINY)
          .fontColor('#F44336')
          .margin({ top: 2 })
      })

      ForEach(this.gbResult.warnings, (w: string) => {
        Text('• ' + w)
          .fontSize(FONT_SIZE.TINY)
          .fontColor('#FFA726')
          .margin({ top: 2 })
      })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  childSafetySection() {
    Column() {
      Row() {
        Text('👶 儿童安全')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)
          .layoutWeight(1)
        Text(this.childResult.riskLevel)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.WHITE)
          .backgroundColor(this.childResult.riskColor)
          .borderRadius(8)
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      }
      .width('100%')

      Text(this.childResult.summary)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(COLORS.TEXT_SECONDARY)
        .margin({ top: 4 })

      ForEach(this.childResult.warnings, (w: string) => {
        Text('⚠️ ' + w)
          .fontSize(FONT_SIZE.TINY)
          .fontColor('#FF7043')
          .margin({ top: 2 })
      })

      ForEach(this.childResult.nutritionExceeded, (ex: string) => {
        Text('• ' + ex)
          .fontSize(FONT_SIZE.TINY)
          .fontColor('#F44336')
          .margin({ top: 2 })
      })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ top: SPACING.SM })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  brandCalloutSection() {
    if (this.healthScore.additiveResult.avoidCount > 0 && this.foodLabel.manufacturer.length > 0) {
      Column() {
        Text('📣 向品牌反馈')
          .fontSize(FONT_SIZE.MEDIUM)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.BOLD)

        Text('该产品含高风险添加剂，一键向品牌发送改进建议')
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_TERTIARY)
          .margin({ top: 4 })

        Button('生成反馈邮件')
          .fontSize(FONT_SIZE.SMALL)
          .fontColor(COLORS.WHITE)
          .backgroundColor(COLORS.PRIMARY)
          .borderRadius(RADIUS.SM)
          .height(36)
          .margin({ top: 10 })
          .onClick(() => this.shareBrandCallout())
      }
      .width('100%')
      .padding(SPACING.MD)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(RADIUS.MD)
      .margin({ top: SPACING.SM })
      .alignItems(HorizontalAlign.Start)
    }
  }

  private shareBrandCallout(): void {
    const avoidAdditives: string[] = [];
    const assessments = this.healthScore.additiveResult.assessments;
    for (let i = 0; i < assessments.length; i++) {
      if (assessments[i].riskLevel.toString() === 'avoid') {
        avoidAdditives.push(assessments[i].eNumber + ' (' + assessments[i].name + ')');
      }
    }

    const message: string = '尊敬的' + this.foodLabel.manufacturer + '：\n\n' +
      '作为消费者，我发现贵司产品「' + this.foodLabel.foodName + '」含有以下高风险添加剂：\n' +
      avoidAdditives.join('、') + '\n\n' +
      '这些添加剂可能对健康造成潜在风险，建议贵司考虑以下改进方案：\n' +
      '1. 使用更安全的替代添加剂\n' +
      '2. 减少添加剂使用种类\n' +
      '3. 加强产品成分透明度\n\n' +
      '期待贵司的积极回应，为消费者提供更健康的产品。\n\n' +
      '—— 来自家庭食品安全助手用户';

    const sysPasteboard = pasteboard.getSystemPasteboard();
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, message);
    sysPasteboard.setDataSync(pasteData);
  }
}
import {
  ToastHelper, safeBack, DietRecord, NutritionTarget, FamilyProfile, MealScenario,
  COLORS, FONT_SIZE, RADIUS, SPACING, SHADOWS, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive, ThemeColors, ThemeMode
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { NutritionTargetGauge } from '../components/NutritionTargetGauge';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'DailyIntakePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

interface NutrientBucket {
  label: string;
  unit: string;
  current: number;
  target: number;
  color: string;
  lowerIsBetter: boolean;
}

@Entry
@ComponentV2
export struct DailyIntakePage {
  @Local selectedDate: string = ''
  @Local records: DietRecord[] = []
  @Local familyMembers: FamilyProfile[] = []
  @Local selectedMemberId: string = ''
  @Local target: NutritionTarget = new NutritionTarget()
  @Local isLoading: boolean = true

  private appState: AppState = AppState.getInstance()

  private tracker: PageResourceTracker = createPageTracker('DailyIntakePage')
  private themeRef: ThemeReactive = themeReactive

  private get isDark(): boolean {
    if (this.themeRef.key >= 0) { /* trigger reactive */ }
    return ThemeColors.getTheme() === ThemeMode.DARK;
  }

  private get pageBgGradient(): LinearGradient {
    if (this.isDark) {
      return { angle: 180, colors: [['#0D1B0E', 0.0], ['#1A2F1C', 0.5], ['#0A1A0D', 1.0]] };
    }
    return { angle: 180, colors: [['#E8EAF6', 0.0], ['#E0F2F1', 0.3], ['#FFF8E1', 0.7], ['#F3E5F5', 1.0]] };
  }

  aboutToAppear(): void {
    this.tracker.onAppear()
    const now = new Date();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    this.selectedDate = now.getFullYear().toString() + '-' + month + '-' + day;
    this.familyMembers = this.appState.getAllMembersSync();
    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId;
    }
    this.loadData();
  }

  private async loadData(): Promise<void> {
    this.isLoading = true;
    try {
      if (this.selectedMemberId.length > 0) {
        this.records = await this.appState.historyRepo.getDietRecordsByDate(this.selectedMemberId, this.selectedDate);
        const targets = await this.appState.getNutritionTarget(this.selectedMemberId);
        if (targets) { this.target = targets; }
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'loadData failed: %{public}s', JSON.stringify(e));
      this.records = [];
    }
    this.isLoading = false;
  }

  private calcTotal(field: string): number {
    let sum = 0;
    for (const r of this.records) {
      let val: number = 0;
      if (field === 'sodiumIntake') { val = r.sodiumIntake; }
      else if (field === 'sugarIntake') { val = r.sugarIntake; }
      else if (field === 'calorieIntake') { val = r.calorieIntake; }
      else if (field === 'fatIntake') { val = r.fatIntake; }
      sum += val;
    }
    return sum;
  }

  private buildBuckets(): NutrientBucket[] {
    return [
      { label: '热量', unit: 'kcal', current: this.calcTotal('calorieIntake'), target: this.target.caloriesTarget, color: COLORS.PRIMARY, lowerIsBetter: false },
      { label: '钠', unit: 'mg', current: this.calcTotal('sodiumIntake'), target: this.target.sodiumMax_mg, color: COLORS.ACCENT_RED_EF53, lowerIsBetter: true },
      { label: '糖', unit: 'g', current: this.calcTotal('sugarIntake'), target: this.target.sugarMax_g, color: COLORS.ORANGE_ACCENT, lowerIsBetter: true },
      { label: '脂肪', unit: 'g', current: this.calcTotal('fatIntake'), target: this.target.fatMax_g, color: COLORS.ORANGE_ACCENT, lowerIsBetter: true },
    ];
  }

  build() {
    Column() {
      GradientHeader({ title: '每日摄入追踪' })

      if (this.familyMembers.length > 1) {
        this.MemberTabs()
      }

      Row() {
        Text('日期: ')
          .fontSize(14)
          .fontColor(COLORS.TEXT_SECONDARY)
        Text(this.selectedDate)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
      }
      .width('92%')
      .margin({ bottom: 12 })

      Scroll() {
        Column() {
          NutritionTargetGauge({
            calories: this.calcTotal('calorieIntake'),
            caloriesTarget: this.target.caloriesTarget,
            sodium: this.calcTotal('sodiumIntake'),
            sodiumTarget: this.target.sodiumMax_mg,
            sugar: this.calcTotal('sugarIntake'),
            sugarTarget: this.target.sugarMax_g,
            fat: this.calcTotal('fatIntake'),
            fatTarget: this.target.fatMax_g,
            protein: this.calcTotal('proteinIntake'),
            proteinTarget: this.target.proteinTarget_g
          })

          this.SummaryCards()

          this.MealBreakdown()

          this.RecordList()
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .linearGradient(this.pageBgGradient)
    .alignItems(HorizontalAlign.Center)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  MemberTabs() {
    Row() {
      ForEach(this.familyMembers, (member: FamilyProfile) => {
        Text(member.nickname)
          .fontSize(13)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(RADIUS.LG)
          .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.BG_LIGHT)
          .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_PRIMARY)
          .margin({ right: 6 })
          .onClick(() => {
            this.selectedMemberId = member.memberId;
            this.loadData();
          })
          .accessibilityText(member.nickname)
          .accessibilityLevel('yes')
      }, (member: FamilyProfile) => member.memberId)
    }
    .width('92%')
    .margin({ bottom: 12 })
  }

  @Builder
  SummaryCards() {
    Column() {
      Text('今日摄入概览')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 12 })

      ForEach(this.buildBuckets(), (bucket: NutrientBucket, index: number) => {
        Row() {
          Column() {
            Text(bucket.label)
              .fontSize(12)
              .fontColor(COLORS.TEXT_SECONDARY)
            Text(bucket.current.toFixed(0) + ' ' + bucket.unit)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(bucket.color)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Column() {
            Text('目标')
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
            Text(bucket.target.toFixed(0) + ' ' + bucket.unit)
              .fontSize(13)
              .fontColor(COLORS.TEXT_SECONDARY)
          }
          .alignItems(HorizontalAlign.End)
          .width(70)

          this.MiniProgress(bucket)
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
      }, (bucket: NutrientBucket, index: number) => index.toString())
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 14 })
    .alignItems(HorizontalAlign.Start)
    .shadow(SHADOWS.MD)
  }

  @Builder
  MiniProgress(bucket: NutrientBucket) {
    Progress({
      value: Math.min(bucket.current, bucket.target * 1.5),
      total: bucket.target * 1.5,
      type: ProgressType.Linear
    })
      .width(60)
      .height(6)
      .color(bucket.current > bucket.target && bucket.lowerIsBetter ? COLORS.ACCENT_RED_EF53 : bucket.color)
      .backgroundColor(COLORS.BG_LIGHT)
      .borderRadius(3)
  }

  @Builder
  MealBreakdown() {
    Column() {
      Text('分餐汇总')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      ForEach(['breakfast', 'lunch', 'dinner', 'snack'], (mealType: string) => {
        if (this.records.filter(r => r.mealType === mealType).length > 0) {
          Row() {
            Text(this.mealTypeLabel(mealType))
              .fontSize(14)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
            Text(this.getMealCalories(mealType).toFixed(0) + ' 千卡')
              .fontSize(13)
              .fontColor(COLORS.TEXT_SECONDARY)
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
        }
      }, (mealType: string) => mealType)
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 14 })
    .alignItems(HorizontalAlign.Start)
    .shadow(SHADOWS.MD)
  }

  @Builder
  RecordList() {
    Column() {
      Text('饮食记录')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      if (this.records.length === 0) {
        Column() {
          Text('🍽️')
            .fontSize(48)
            .margin({ bottom: 8 })
          Text('今日暂无饮食记录')
            .fontSize(14)
            .fontColor(COLORS.TEXT_TERTIARY)
            .margin({ bottom: 4 })
          Text('扫描食品后添加到饮食日记即可查看')
            .fontSize(12)
            .fontColor(COLORS.TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
        .alignItems(HorizontalAlign.Center)
      }

      ForEach(this.records, (record: DietRecord) => {
        Row() {
          Column() {
            Text(this.mealTypeLabel(record.mealType))
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(COLORS.TEXT_PRIMARY)
            Text(record.amountG.toFixed(0) + '克 · ' + record.calorieIntake.toFixed(0) + '千卡')
              .fontSize(11)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Column() {
            Text('钠' + record.sodiumIntake.toFixed(0) + '毫克')
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
            Text('糖' + record.sugarIntake.toFixed(1) + 'g')
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.End)
          .width(70)
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .border({ width: { bottom: 0.5 }, color: COLORS.DIVIDER })
      }, (record: DietRecord, index: number) => record.id + '_' + index.toString())
    }
    .width('92%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.LG)
    .margin({ bottom: 24 })
    .alignItems(HorizontalAlign.Start)
    .shadow(SHADOWS.MD)
  }

  private mealTypeLabel(type: string): string {
    switch (type) {
      case 'breakfast': return '早餐';
      case 'lunch': return '午餐';
      case 'dinner': return '晚餐';
      case 'snack': return '加餐';
      default: return type;
    }
  }

  private getMealCalories(mealType: string): number {
    let total = 0;
    for (const r of this.records) {
      if (r.mealType === mealType) total += r.calorieIntake;
    }
    return total;
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }



  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}

// DietDiaryPage.ets
// 膳食日记页面 - 按餐次查看每日摄入，查看趋势图表入口

import { router, promptAction } from '@kit.ArkUI';
import { AppState } from '../AppState';
import { DietRecord } from '../repository/HistoryRepository';
import { FamilyProfile } from '../model/FamilyProfile';
import { NutritionTrendEngine, MealGroup } from '../engine/NutritionTrendEngine';
import { DailyBudget } from '../model/DailyBudget';
import { DateUtil } from '../utils/DateUtil';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';
import { MealScenario } from '../model/MealBalance';

// 场景emoji映射
const SCENARIO_EMOJI: Record<string, string> = {
  '烧烤': '🔥', '火锅': '🍲', '炸鸡': '🍗', '奶茶': '🧋',
  '甜品': '🍰', '卤味': '🥘', '方便面': '🍜', '夜宵': '🌙',
  '麻辣烫': '🌶️', '烤肉': '🥩', '日料': '🍣', '自助餐': '🍱',
  '下午茶': '☕', '螺蛳粉': '🍝', '其他': '🍽️'
};

@Entry
@Component
struct DietDiaryPage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State currentDate: string = ''
  @State mealGroups: MealGroup[] = []
  @State budget: DailyBudget | null = null
  @State dateInputText: string = ''
  @State showDatePicker: boolean = false
  @State isLoading: boolean = false

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.currentDate = DateUtil.getToday()
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }
    await this.refreshData()
  }

  private async refreshData() {
    if (this.selectedMemberId.length === 0) return
    this.isLoading = true

    this.mealGroups = await this.appState.getDailyDietGroups(this.selectedMemberId, this.currentDate)
    this.budget = this.appState.getDailyBudget(this.selectedMemberId)

    this.isLoading = false
  }

  private changeDate(delta: number): void {
    const d = new Date(this.currentDate)
    d.setDate(d.getDate() + delta)
    this.currentDate = DateUtil.formatDate(d)
    this.refreshData()
  }

  private getDateLabel(): string {
    const today = DateUtil.getToday()
    if (this.currentDate === today) return '今天'
    const d = new Date(this.currentDate)
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    if (this.currentDate === DateUtil.formatDate(yesterday)) return '昨天'
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return `${d.getMonth() + 1}月${d.getDate()}日 ${weekDays[d.getDay()]}`
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Text('‹')
          .fontSize(28)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
        Text('膳食日记')
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ left: SPACING.MD })
        Blank()
        Text('📊 趋势')
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .onClick(() => {
            try {
              router.pushUrl({
                url: 'pages/NutritionTrendPage',
                params: { memberId: this.selectedMemberId }
              })
            } catch (_e) { /* ignore */ }
          })
      }
      .width('100%')
      .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.LG, bottom: SPACING.MD })

      // 成员选择器 (横向滚动)
      Scroll() {
        Row() {
          ForEach(this.familyMembers, (member: FamilyProfile) => {
            Text(member.nickname)
              .fontSize(FONT_SIZE.SMALL)
              .fontWeight(this.selectedMemberId === member.memberId ? FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
              .fontColor(this.selectedMemberId === member.memberId ? COLORS.WHITE : COLORS.TEXT_GRAY_6161)
              .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
              .borderRadius(RADIUS.FULL)
              .backgroundColor(this.selectedMemberId === member.memberId ? COLORS.PRIMARY : COLORS.BG_LIGHT_GRAY_F5)
              .margin({ right: SPACING.SM })
              .onClick(() => {
                this.selectedMemberId = member.memberId
                this.refreshData()
              })
          }, (member: FamilyProfile) => member.memberId)
        }
        .padding({ left: SPACING.LG, right: SPACING.LG })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .height(48)
      .margin({ bottom: SPACING.SM })

      // 日期导航
      Row() {
        Text('‹')
          .fontSize(24)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => this.changeDate(-1))
        Column() {
          Text(this.getDateLabel())
            .fontSize(FONT_SIZE.LG)
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .fontColor(COLORS.TEXT_PRIMARY)
          Text(this.currentDate)
            .fontSize(FONT_SIZE.TINY)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
        }
        .padding({ left: SPACING.MD, right: SPACING.MD })
        .onClick(() => {
          this.showDatePicker = !this.showDatePicker
        })
        Text('›')
          .fontSize(24)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => this.changeDate(1))
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .height(56)
      .margin({ bottom: SPACING.SM })

      // 快速日期跳转输入
      if (this.showDatePicker) {
        Row() {
          TextInput({ placeholder: '输入日期 YYYY-MM-DD', text: this.dateInputText })
            .width(160)
            .height(36)
            .borderRadius(RADIUS.SM)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .padding({ left: SPACING.SM })
            .placeholderColor(COLORS.TEXT_GRAY_9E9E)
            .fontSize(FONT_SIZE.SMALL)
            .onChange((v: string) => { this.dateInputText = v })
          Button('跳转')
            .height(36)
            .fontSize(FONT_SIZE.SMALL)
            .borderRadius(RADIUS.SM)
            .backgroundColor(COLORS.PRIMARY)
            .fontColor(COLORS.WHITE)
            .onClick(() => {
              if (this.dateInputText.length === 10) {
                this.currentDate = this.dateInputText
                this.showDatePicker = false
                this.refreshData()
              } else {
                promptAction.showToast({ message: '请输入完整日期' })
              }
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: SPACING.SM })
      }

      // 今日预算概览
      if (this.budget !== null) {
        this.buildBudgetBar()
      }

      // 内容区
      if (this.isLoading) {
        LoadingProgress()
          .width(32)
          .height(32)
          .color(COLORS.PRIMARY)
          .margin({ top: 80 })
      } else if (this.mealGroups.length === 0) {
        // 空状态
        Column() {
          Text('📝')
            .fontSize(48)
          Text('暂无膳食记录')
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.MD })
          Text('去首页扫描食品标签后自动记录')
            .fontSize(FONT_SIZE.SMALL)
            .fontColor(COLORS.TEXT_GRAY_BDBD)
            .margin({ top: SPACING.SM })
        }
        .width('100%')
        .margin({ top: 60 })
        .alignItems(HorizontalAlign.Center)
      } else {
        // 膳食记录列表 - 按餐次分组
        Scroll() {
          Column() {
            ForEach(this.mealGroups, (group: MealGroup) => {
              this.buildMealGroupCard(group)
            }, (group: MealGroup) => group.mealType)
          }
          .width('100%')
          .padding({ left: SPACING.LG, right: SPACING.LG })
          .padding({ bottom: 100 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  @Builder
  buildBudgetBar() {
    Row() {
      // 4 种营养素的进度条
      this.buildMiniProgress('🧂 钠', this.getSodiumPercent(), COLORS.ACCENT_RED_F443)
      this.buildMiniProgress('🍬 糖', this.getSugarPercent(), COLORS.ORANGE_ACCENT)
      this.buildMiniProgress('🔥 热量', this.getCaloriePercent(), COLORS.ACCENT_GREEN_4CAF)
      this.buildMiniProgress('🥩 脂肪', this.getFatPercent(), COLORS.ACCENT_PURPLE_9C27)
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.SM, bottom: SPACING.SM })
    .backgroundColor(COLORS.WHITE)
    .margin({ bottom: SPACING.SM })
  }

  @Builder
  buildMiniProgress(label: string, percent: number, color: string) {
    Column() {
      Text(label)
        .fontSize(9)
        .fontColor(COLORS.TEXT_GRAY_6161)
        .margin({ bottom: 2 })
      Stack() {
        Column()
          .width('100%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(COLORS.BG_DIVIDER)
        Column()
          .width((percent > 100 ? 100 : percent).toFixed(0) + '%')
          .height(4)
          .borderRadius(2)
          .backgroundColor(color)
          .alignSelf(ItemAlign.Start)
      }
      .width('100%')
      .height(4)
      .borderRadius(2)
      Text(Math.round(percent) + '%')
        .fontSize(8)
        .fontColor(color)
        .margin({ top: 1 })
    }
    .layoutWeight(1)
    .padding({ right: 4 })
  }

  @Builder
  buildMealGroupCard(group: MealGroup) {
    Column() {
      // 餐次头
      Row() {
        Text(this.getMealEmoji(group.mealType))
          .fontSize(20)
          .margin({ right: SPACING.SM })
        Text(group.mealLabel)
          .fontSize(FONT_SIZE.LG)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text(`钠${Math.round(group.sodiumTotal)}mg · 糖${group.sugarTotal.toFixed(1)}g`)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
      }
      .width('100%')
      .padding({ bottom: SPACING.SM })

      // 记录列表
      ForEach(group.records, (record: DietRecord) => {
        this.buildRecordItem(record)
      }, (record: DietRecord) => `${record.id}`)

      // 营养素汇总条
      Row({ space: SPACING.MD }) {
        this.buildNutriChip('🧂', `${Math.round(group.sodiumTotal)}mg`, COLORS.ACCENT_RED_F443)
        this.buildNutriChip('🍬', `${group.sugarTotal.toFixed(1)}g`, COLORS.ORANGE_ACCENT)
        this.buildNutriChip('🔥', `${Math.round(group.calorieTotal)}kcal`, COLORS.ACCENT_GREEN_4CAF)
        this.buildNutriChip('🥩', `${group.fatTotal.toFixed(1)}g`, COLORS.ACCENT_PURPLE_9C27)
      }
      .width('100%')
      .padding({ top: SPACING.SM })
    }
    .width('100%')
    .padding(SPACING.MD)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(RADIUS.MD)
    .margin({ bottom: SPACING.MD })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  buildRecordItem(record: DietRecord) {
    Row() {
      Text(this.getScenarioEmoji(record.scenario))
        .fontSize(16)
        .margin({ right: SPACING.SM })
      Column() {
        Text(record.scenario || '未知场景')
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.TEXT_PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
        Text(`${record.amountG.toFixed(0)}g · ${DateUtil.formatTime(new Date(record.recordedAt))}`)
          .fontSize(FONT_SIZE.TINY)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      Blank()
      Text(`钠${Math.round(record.sodiumIntake)}`)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.ACCENT_RED_F443)
        .margin({ right: SPACING.SM })
      Text(`糖${record.sugarIntake.toFixed(1)}`)
        .fontSize(FONT_SIZE.SMALL)
        .fontColor(COLORS.ORANGE_ACCENT)
    }
    .width('100%')
    .padding({ top: SPACING.SM, bottom: SPACING.SM })
    .border({ width: { bottom: 1 }, color: COLORS.BORDER_LIGHT_E8 })
  }

  @Builder
  buildNutriChip(emoji: string, value: string, color: string) {
    Row({ space: 2 }) {
      Text(emoji)
        .fontSize(10)
      Text(value)
        .fontSize(FONT_SIZE.TINY)
        .fontColor(color)
        .fontWeight(FONT_WEIGHT.MEDIUM)
    }
    .padding({ left: SPACING.SM, right: SPACING.SM, top: 4, bottom: 4 })
    .backgroundColor(color + '15')
    .borderRadius(RADIUS.FULL)
  }

  private getMealEmoji(mealType: string): string {
    const map: Record<string, string> = {
      'breakfast': '🌅', 'lunch': '☀️', 'dinner': '🌙', 'snack': '🍪'
    }
    return map[mealType] || '🍽️'
  }

  private getScenarioEmoji(scenario: string): string {
    return SCENARIO_EMOJI[scenario] || '🍽️'
  }

  private getSodiumPercent(): number {
    return this.budget?.sodiumUsagePercent() || 0;
  }

  private getSugarPercent(): number {
    return this.budget?.sugarUsagePercent() || 0;
  }

  private getCaloriePercent(): number {
    return this.budget?.calorieUsagePercent() || 0;
  }

  private getFatPercent(): number {
    return this.budget?.fatUsagePercent() || 0;
  }
}

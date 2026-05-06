// DietDiaryPage.ets
// 膳食日记页面 - 按餐次查看每日摄入，查看趋势图表入口

import { router, promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppState } from '../AppState';
import { DietRecord } from '../repository/HistoryRepository';
import { FamilyProfile } from '../model/FamilyProfile';
import { NutritionTrendEngine, MealGroup } from '../engine/NutritionTrendEngine';
import { DailyBudget } from '../model/DailyBudget';
import { ErrorFallback } from '../components/ErrorFallback';
import { DateUtil } from '../utils/DateUtil';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';
import { MealScenario } from '../model/MealBalance';
import { AiNutritionAdvice } from '../model/AiModels';

const DOMAIN_ZERO = 0;

// 场景emoji映射
const SCENARIO_EMOJI: Record<string, string> = {
  '烧烤': '🔥', '火锅': '🍲', '炸鸡': '🍗', '奶茶': '🧋',
  '甜品': '🍰', '卤味': '🥘', '方便面': '🍜', '夜宵': '🌙',
  '麻辣烫': '🌶️', '烤肉': '🥩', '日料': '🍣', '自助餐': '🍱',
  '下午茶': '☕', '螺蛳粉': '🍝',
  '冒菜': '🫘', '麻辣香锅': '🌶️', '轻食沙拉': '🥗', '披萨': '🍕',
  '汉堡': '🍔', '饺子包子': '🥟', '炒饭盖饭': '🍚',
  '其他': '🍽️'
};

// AI营养素分析卡片类型（兼容AiModels中的NutrientAnalysis）
interface NutrientAnalysisItem {
  name: string;
  averageDaily: number;
  target: number;
  status: 'excellent' | 'good' | 'warning' | 'over';
  trend: string;
  insight: string;
}

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
  @State errorMessage: string = ''
  @State aiAdvice: AiNutritionAdvice | null = null
  @State isLoadingAi: boolean = false
  @State showAiSection: boolean = false

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    this.currentDate = DateUtil.getToday()
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }
    // 检查是否从首页以AI营养师模式进入
    try {
      const params = router.getParams() as Record<string, Object>;
      if (params['aiMode'] === 'nutritionist') {
        this.showAiSection = true
      }
    } catch (_e) { /* ignore */ }
    await this.refreshData()
  }

  private async loadAiAdvice() {
    if (this.selectedMemberId.length === 0) return
    this.isLoadingAi = true
    try {
      this.aiAdvice = await this.appState.getAiNutritionAdvice(
        this.selectedMemberId, 7, true
      )
    } catch (e) {
      hilog.error(DOMAIN_ZERO, 'DietDiaryPage', 'ai nutritionist error: ' + JSON.stringify(e))
    }
    this.isLoadingAi = false
  }

  private async refreshData() {
    if (this.selectedMemberId.length === 0) return
    this.isLoading = true
    this.errorMessage = ''

    try {
      this.mealGroups = await this.appState.getDailyDietGroups(this.selectedMemberId, this.currentDate)
      this.budget = this.appState.getDailyBudgetSync(this.selectedMemberId)
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, 'DietDiaryPage', 'refreshData failed: %{public}s', JSON.stringify(_e))
      this.errorMessage = '数据加载失败，请重试'
    }

    this.isLoading = false
  }

  private changeDate(delta: number): void {
    const today = DateUtil.getToday()
    // 禁止导航到未来日期
    if (delta > 0 && this.currentDate === today) {
      return
    }
    const d = new Date(this.currentDate)
    d.setDate(d.getDate() + delta)

    // 再次检查确保不超过今天
    const candidate = DateUtil.formatDate(d)
    if (candidate > today) {
      this.currentDate = today
    } else {
      this.currentDate = candidate
    }
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
        BackButton()
          .fontSize(28)
          .fontColor(COLORS.PRIMARY)
          .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
        Text($r('app.string.diet_diary'))
          .fontSize(FONT_SIZE.TITLE)
          .fontWeight(FONT_WEIGHT.BOLD)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ left: SPACING.MD })
        Blank()
        Text($r('app.string.ai_analysis'))
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.ACCENT_PURPLE)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .onClick(() => {
            this.showAiSection = !this.showAiSection
            if (this.showAiSection && this.aiAdvice === null) {
              this.loadAiAdvice()
            }
          })
        Text($r('app.string.trend_tab'))
          .fontSize(FONT_SIZE.BODY)
          .fontColor(COLORS.PRIMARY)
          .fontWeight(FONT_WEIGHT.MEDIUM)
          .margin({ left: SPACING.MD })
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
        BackButton()
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

      // AI营养师分析区
      if (this.showAiSection) {
        this.buildAiNutritionistSection()
      }

      // 内容区
      if (this.errorMessage.length > 0) {
        ErrorFallback({
          message: this.errorMessage,
          icon: '📊',
          onRetry: () => this.refreshData()
        })
        .layoutWeight(1)
      } else if (this.isLoading) {
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
          Text($r('app.string.no_content'))
            .fontSize(FONT_SIZE.LG)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: SPACING.MD })
          Text($r('app.string.go_scan_tip'))
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
  buildAiNutritionistSection() {
    Column() {
      if (this.isLoadingAi) {
        Row({ space: 8 }) {
          LoadingProgress().width(20).height(20).color(COLORS.ACCENT_PURPLE)
          Text($r('app.string.ai_analyzing'))
            .fontSize(14)
            .fontColor(COLORS.TEXT_GRAY_6161)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding(16)
        .backgroundColor(COLORS.BG_WARM_PURPLE)
        .borderRadius(RADIUS.LG)
      } else if (this.aiAdvice !== null) {
        // 总评卡片
        Column() {
          Row({ space: 6 }) {
            Text('🤖').fontSize(22)
            Column() {
              Text($r('app.string.ai_analysis_title'))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(COLORS.PRIMARY_DARK)
              if (this.aiAdvice.isAiGenerated) {
                Text($r('app.string.ai_enhanced'))
                  .fontSize(10)
                  .fontColor(COLORS.ACCENT_PURPLE)
                  .backgroundColor(COLORS.BG_WARM_PURPLE)
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  .borderRadius(8)
                  .margin({ top: 2 })
              }
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(this.aiAdvice.dateRange)
              .fontSize(12)
              .fontColor(COLORS.TEXT_GRAY_9E9E)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Text(this.aiAdvice.summary)
            .fontSize(14)
            .fontColor(COLORS.TEXT_PRIMARY)
            .lineHeight(22)
            .width('100%')

          // 营养素分析
          if (this.aiAdvice.nutrientAnalyses.length > 0) {
            Row({ space: 6 }) {
              ForEach(this.aiAdvice.nutrientAnalyses, (na: NutrientAnalysisItem) => {
                this.buildNutrientMiniCard(na)
              })
            }
            .width('100%')
            .margin({ top: 8 })
          }

          // 问题与亮点
          if (this.aiAdvice.patternAnalysis.issues.length > 0) {
            Column() {
              Text($r('app.string.need_attention'))
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor(COLORS.ORANGE_ACCENT)
                .margin({ bottom: 4 })
              ForEach(this.aiAdvice.patternAnalysis.issues, (issue: string) => {
                Text('· ' + issue)
                  .fontSize(12)
                  .fontColor(COLORS.TEXT_GRAY_6161)
                  .margin({ bottom: 2 })
              })
            }
            .width('100%')
            .margin({ top: 8 })
          }

          // 建议列表
          Row() {
            Text('💡 ' + this.aiAdvice.suggestions[0])
              .fontSize(13)
              .fontColor(COLORS.ACCENT_PURPLE)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding(10)
          .backgroundColor(COLORS.BG_WARM_PURPLE)
          .borderRadius(RADIUS.MD)
          .margin({ top: 8 })

          // 鼓励语
          Text(this.aiAdvice.motivationalMessage)
            .fontSize(12)
            .fontColor(COLORS.TEXT_GRAY_9E9E)
            .margin({ top: 8 })
            .width('100%')

          // 刷新按钮
          Button('🔄 刷新分析')
            .height(32)
            .fontSize(12)
            .backgroundColor(COLORS.ACCENT_PURPLE)
            .borderRadius(RADIUS.FULL)
            .fontColor(COLORS.WHITE)
            .margin({ top: 8 })
            .onClick(() => { this.loadAiAdvice() })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(RADIUS.LG)
        .margin({ bottom: SPACING.MD })
        .shadow({ radius: 2, color: COLORS.SHADOW_LIGHT, offsetY: 1 })
      } else {
        // 未加载状态
        Button() {
          Row({ space: 6 }) {
            Text('🤖').fontSize(18)
            Text($r('app.string.ai_analysis'))
          }
        }
        .width('100%')
        .height(44)
        .backgroundColor(COLORS.ACCENT_PURPLE)
        .borderRadius(RADIUS.LG)
        .onClick(() => { this.loadAiAdvice() })
      }
    }
    .width('100%')
    .padding({ left: SPACING.LG, right: SPACING.LG, bottom: SPACING.SM })
  }

  @Builder
  buildNutrientMiniCard(na: NutrientAnalysisItem) {
    Column() {
      Text(na.name)
        .fontSize(10)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
      Text(Math.round(na.averageDaily).toString())
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(na.status === 'over' ? COLORS.ACCENT_RED_F443 :
          na.status === 'warning' ? COLORS.ORANGE_ACCENT : COLORS.ACCENT_GREEN_4CAF)
      Text('/' + na.target.toString())
        .fontSize(9)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
    }
    .layoutWeight(1)
    .padding(6)
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(RADIUS.SM)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildBudgetBar() {
    Row() {
      // 4 种营养素的进度条
      this.buildMiniProgress('🧂 钠', this.budget?.sodiumUsagePercent() || 0, COLORS.ACCENT_RED_F443)
      this.buildMiniProgress('🍬 糖', this.budget?.sugarUsagePercent() || 0, COLORS.ORANGE_ACCENT)
      this.buildMiniProgress('🔥 热量', this.budget?.calorieUsagePercent() || 0, COLORS.ACCENT_GREEN_4CAF)
      this.buildMiniProgress('🥩 脂肪', this.budget?.fatUsagePercent() || 0, COLORS.ACCENT_PURPLE_9C27)
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
}

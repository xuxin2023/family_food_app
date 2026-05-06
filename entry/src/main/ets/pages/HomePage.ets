// HomePage.ets
// 首页 - 家庭饮食平衡助手 V5
// V5增强：今日家庭状态条、各成员预算剩余

import { router, promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FamilyProfile, HealthGoal } from '../model/FamilyProfile';
import { MemberCard } from '../components/MemberCard';
import { FeatureButton, NavLinkText } from '../components/FeatureButton';
import { LinkInputDialog } from '../components/LinkInputDialog';
import { AppState } from '../AppState';
import { MilestoneService, Milestone } from '../service/MilestoneService';
import { OnlineShoppingParser } from '../service/OnlineShoppingParser';
import { DailyBudget } from '../model/DailyBudget';
import { LoadingSkeleton } from '../components/SkeletonScreen';
import { COLORS, FONT_SIZE, SPACING, RADIUS, FONT_WEIGHT, BUTTON } from '../constants/AppTheme';

const DOMAIN_ZERO = 0;

export class StatusResult {
  text: string = ''
  color: string = ''
  constructor(text: string, color: string) {
    this.text = text
    this.color = color
  }
}

@Entry
@Component
struct HomePage {
  @State familyMembers: FamilyProfile[] = []
  @State selectedMemberId: string = ''
  @State milestones: Milestone[] = []
  @State showLinkInput: boolean = false
  @State linkInputText: string = ''
  @State isParsingLink: boolean = false
  @State memberStatusMap: Map<string, StatusResult> = new Map()
  @State remainingScans: number = 0
  @State isLoading: boolean = true

  // ===== AppStorage 版本号绑定 =====
  // scanVersion 在扫码后递增，驱动 UI 增量刷新
  @StorageProp('scanVersion') scanVersion: number = 0

  // 记录上次加载时的版号，避免重复刷新
  private lastScanVersion: number = -1

  private appState: AppState = AppState.getInstance()
  private milestoneService: MilestoneService = MilestoneService.getInstance()
  private currentSloganIndex: number = 0
  private todayDate: string = ''

  private slogans: ResourceStr[] = [
    $r('app.string.slogan_1'),
    $r('app.string.slogan_2'),
    $r('app.string.slogan_3'),
    $r('app.string.slogan_4'),
    $r('app.string.slogan_5')
  ]

  async aboutToAppear() {
    this.currentSloganIndex = Math.floor(Math.random() * this.slogans.length)
    this.todayDate = this.getTodayDate()
    await this.refreshAll()
  }

  /** onPageShow：每次页面变为可见时触发 — 响应式增量刷新 */
  async onPageShow() {
    await this.refreshIfNeeded()
  }

  /**
   * 增量刷新：每次 onPageShow 时执行，只在数据有变化时刷新
   * - 成员列表由 aboutToAppear 全量加载，onPageShow 不再同步重载（getAllMembers 已有缓存保护）
   * - scanVersion 变化 → 刷新当日状态
   */
  private async refreshIfNeeded(): Promise<void> {
    // scanVersion 递增 → 刷新当日状态
    if (this.scanVersion !== this.lastScanVersion) {
      // 确保成员列表与 AppState 缓存一致（内存读取，无数据库查询）
      if (this.familyMembers.length === 0) {
        this.familyMembers = await this.appState.getAllMembers()
      }
      this.refreshMemberStatuses()
      this.lastScanVersion = this.scanVersion
    }
  }

  private async refreshAll(): Promise<void> {
    this.isLoading = true
    await this.loadFamilyMembers()
    this.refreshMemberStatuses()
    await this.refreshMilestones()
    // 记录当前版号
    this.lastScanVersion = this.scanVersion
    this.isLoading = false
  }

  private async refreshMilestones() {
    try {
      this.milestones = await this.milestoneService.checkMilestones()
    } catch (_error) {
      hilog.warn(DOMAIN_ZERO, 'HomePage', 'refreshMilestones failed: ' + JSON.stringify(_error))
    }
  }

  async loadFamilyMembers() {
    this.familyMembers = await this.appState.getAllMembers()
    if (this.familyMembers.length > 0 && this.selectedMemberId.length === 0) {
      this.selectedMemberId = this.familyMembers[0].memberId
    }
  }

  /**
   * 刷新所有成员的状态文本（基于AppState实时预算数据）
   */
  private refreshMemberStatuses(): void {
    this.remainingScans = this.appState.member.getRemainingScans()
    const newMap: Map<string, StatusResult> = new Map()

    for (let i = 0; i < this.familyMembers.length; i++) {
      const member = this.familyMembers[i]
      const budget = this.appState.getDailyBudgetSync(member.memberId)
      const result = this.computeStatusFromBudget(member, budget)
      newMap.set(member.memberId, result)
    }

    this.memberStatusMap = newMap
  }

  private getTodayDate(): string {
    const d = new Date()
    return d.getFullYear() + '-' +
      String(d.getMonth() + 1).padStart(2, '0') + '-' +
      String(d.getDate()).padStart(2, '0')
  }

  /**
   * 解析粘贴的电商链接
   */
  private async handleParseLink(url: string): Promise<void> {
    if (url.trim().length === 0) {
      promptAction.showToast({ message: $r('app.string.paste_link_hint') })
      return
    }

    this.isParsingLink = true
    this.showLinkInput = false

    try {
      // 合并为一次调用：parseUrlToLabel 内部已调用 parseUrl 获取商品数据
      const parser = OnlineShoppingParser.getInstance()
      const parseResult = await parser.parseUrlToLabel(url.trim())

      if (!parseResult.success || !parseResult.label) {
        // 解析失败
        promptAction.showToast({ message: parseResult.errorMessage || $r('app.string.parse_failed') })
        this.isParsingLink = false
        return
      }

      // 解析成功 → 存入路由缓存，只传 foodId
      this.appState.reportCache.setParams(parseResult.label, [], [])

      const sourceName: string = parseResult.source ?? '';
      router.pushUrl({
        url: 'pages/ReportPage',
        params: {
          foodLabelId: parseResult.label.foodId,
          sourceName: sourceName,
          fromEcommerce: true
        }
      })
    } catch (error) {
      promptAction.showToast({ message: $r('app.string.parse_exception') })
      hilog.error(DOMAIN_ZERO, 'HomePage', 'parseLink error: ' + JSON.stringify(error))
    } finally {
      this.isParsingLink = false
    }
  }

  /**
   * 打开链接输入弹窗
   */
  private openLinkInput(): void {
    this.linkInputText = ''
    this.showLinkInput = true
  }

  build() {
    Stack() {
      Column() {
      // 顶部品牌区
      Column() {
        Text($r('app.string.app_name'))
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.PRIMARY)
          .margin({ top: 20, bottom: 4 })

        Text(this.slogans[this.currentSloganIndex])
          .fontSize(14)
          .fontColor(COLORS.TEXT_GRAY_7575)
          .margin({ bottom: 16 })
          .textAlign(TextAlign.Center)
          .maxLines(2)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 快速操作区：扫描
      Row({ space: 12 }) {
        Button() {
          Row({ space: 6 }) {
            Text('📷').fontSize(16)
            Text($r('app.string.scan_identify')).fontSize(14).fontColor(COLORS.WHITE)
          }
        }
        .width('45%')
        .height(BUTTON.HEIGHT_SECONDARY)
        .borderRadius(BUTTON.RADIUS_SECONDARY)
        .backgroundColor(COLORS.PRIMARY)
        .accessibilityText($r('app.string.scan_identify'))
        .accessibilityDescription('打开相机扫描食品条码或识别食品标签')
        .onClick(() => {
          try {
            router.pushUrl({
              url: 'pages/ScanPage',
              params: { memberId: this.selectedMemberId }
            })
          } catch (_e) {
            hilog.warn(DOMAIN_ZERO, 'HomePage', 'pushUrl ScanPage failed: %{public}s', JSON.stringify(_e));
          }
        })
      }
      .margin({ bottom: 16 })

      // V5增强：今日家庭状态条
      this.buildFamilyStatusBar()

      // 里程碑横向滑动卡片
      if (this.milestones.length > 0) {
        this.buildMilestoneCarousel()
      }

      // 家庭成员选择
      if (this.isLoading) {
        LoadingSkeleton({ variant: 'card', rowCount: 2 })
          .layoutWeight(1)
          .margin({ top: 8 })
      } else {
        Text($r('app.string.home_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_GRAY_2121)
          .margin({ left: 16, bottom: 8 })

        Scroll() {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
            ForEach(this.familyMembers, (member: FamilyProfile) => {
              Column() {
                MemberCard({
                  member: member,
                  isSelected: this.selectedMemberId === member.memberId,
                  onSelect: (id: string) => { this.selectedMemberId = id }
                })
              }
              .width('45%')
              .margin(8)
            }, (member: FamilyProfile) => member.memberId)

            Column() {
              Text('+').fontSize(28).fontColor(COLORS.PRIMARY)
              Text(this.appState.member.canAddMember() ? $r('app.string.add_member') : $r('app.string.upgrade_unlock'))
                .fontSize(12)
                .fontColor(this.appState.member.canAddMember() ? COLORS.PRIMARY : COLORS.ORANGE_ACCENT)
                .margin({ top: 4 })
            }
            .width('45%')
            .height(100)
            .margin(8)
            .borderRadius(16)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .border({ width: 1, color: COLORS.BORDER_LIGHT, style: BorderStyle.Dashed, radius: 16 })
            .onClick(() => {
              try {
                if (this.appState.member.canAddMember()) {
                  router.pushUrl({ url: 'pages/MemberEditPage' })
                } else {
                  router.pushUrl({ url: 'pages/SettingsPage' })
                }
              } catch (_e) {
                hilog.warn(DOMAIN_ZERO, 'HomePage', 'pushUrl member/add failed: %{public}s', JSON.stringify(_e));
              }
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16 })
        }
        .scrollable(ScrollDirection.Vertical)
        .layoutWeight(1)
      }

      // 底部操作区
      Column() {
        // 粘贴电商链接按钮
        FeatureButton({
          icon: '🔗',
          text: $r('app.string.paste_link'),
          btnBg: COLORS.PURPLE_ACCENT,
          btnHeight: BUTTON.HEIGHT_MD,
          btnRadius: BUTTON.RADIUS_MD,
          onCustomClick: () => { this.openLinkInput() }
        })

        FeatureButton({
          icon: '📷',
          text: $r('app.string.scan_button'),
          btnBg: COLORS.PRIMARY,
          onCustomClick: () => {
            router.pushUrl({ url: 'pages/ScanPage', params: { memberId: this.selectedMemberId } })
          }
        })

        FeatureButton({
          icon: '🍽',
          text: $r('app.string.balance_button'),
          btnBg: COLORS.BG_WARM_BLUE,
          textColor: COLORS.PRIMARY,
          onCustomClick: () => {
            router.pushUrl({ url: 'pages/BalancePage', params: { memberId: this.selectedMemberId } })
          }
        })

        FeatureButton({
          icon: '📊',
          text: $r('app.string.diet_diary'),
          btnBg: COLORS.BG_LIGHT_GREEN,
          textColor: COLORS.ACCENT_GREEN_66BB,
          onCustomClick: () => {
            router.pushUrl({ url: 'pages/DietDiaryPage', params: { memberId: this.selectedMemberId } })
          }
        })

        FeatureButton({
          icon: '🤖',
          text: $r('app.string.ai_nutritionist'),
          btnBg: COLORS.ACCENT_PURPLE,
          onCustomClick: () => {
            router.pushUrl({ url: 'pages/DietDiaryPage', params: { memberId: this.selectedMemberId, aiMode: 'nutritionist' } })
          }
        })

        FeatureButton({
          icon: '✨',
          text: $r('app.string.ai_recommend_recipe'),
          btnBg: COLORS.PRIMARY_DARK,
          onCustomClick: () => {
            router.pushUrl({ url: 'pages/RecipeCommunityPage', params: { aiMode: 'recommend' } })
          }
        })

        if (this.appState.member.hasFamilyAccess()) {
          FeatureButton({
            icon: '🛒',
            text: $r('app.string.basket_button'),
            btnBg: COLORS.BG_WARM_ORANGE,
            textColor: COLORS.ORANGE_ACCENT,
            btnHeight: BUTTON.HEIGHT_MD,
            btnRadius: BUTTON.RADIUS_MD,
            targetUrl: 'pages/BasketCheckPage'
          })
        }

        FeatureButton({
          icon: '🛡️',
          text: $r('app.string.brand_transparency'),
          btnBg: COLORS.BG_WARM_PURPLE,
          textColor: COLORS.PURPLE_ACCENT,
          btnHeight: BUTTON.HEIGHT_MD,
          btnRadius: BUTTON.RADIUS_MD,
          targetUrl: 'pages/SettingsPage'
        })

        // 社交入口：食谱社区 + 家庭群组
        Row({ space: 10 }) {
          Button() {
            Row({ space: 4 }) {
              Text('🍳').fontSize(16)
              Text($r('app.string.recipe_community')).fontSize(14).fontColor(COLORS.WHITE)
            }
          }
          .layoutWeight(1)
          .height(BUTTON.HEIGHT_SECONDARY)
          .backgroundColor(COLORS.ACCENT_PURPLE)
          .borderRadius(BUTTON.RADIUS_SECONDARY)
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/RecipeCommunityPage' });
            } catch (e) {
              hilog.warn(DOMAIN_ZERO, 'HomePage', 'pushUrl RecipeCommunityPage failed: %{public}s', JSON.stringify(e));
            }
          })

          Button() {
            Row({ space: 4 }) {
              Text('👨‍👩‍👧‍👦').fontSize(16)
              Text($r('app.string.family_group')).fontSize(14).fontColor(COLORS.WHITE)
            }
          }
          .layoutWeight(1)
          .height(BUTTON.HEIGHT_SECONDARY)
          .backgroundColor(COLORS.ACCENT_BLUE)
          .borderRadius(BUTTON.RADIUS_SECONDARY)
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/FamilyGroupPage' });
            } catch (e) {
              hilog.warn(DOMAIN_ZERO, 'HomePage', 'pushUrl FamilyGroupPage failed: %{public}s', JSON.stringify(e));
            }
          })
        }
        .width('90%')
        .margin({ bottom: 12 })

        Row() {
          Text('历史').fontSize(13).fontColor(COLORS.TEXT_GRAY_7575)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/HistoryPage' })
              } catch (_e) {
                // ignore router.pushUrl error
              }
            })
          Text('  |  ').fontSize(13).fontColor(COLORS.BORDER)
          Text('日记').fontSize(13).fontColor(COLORS.ACCENT_GREEN_66BB)
            .fontWeight(500)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/DietDiaryPage' })
              } catch (_e) {
                // ignore router.pushUrl error
              }
            })
          Text('  |  ').fontSize(13).fontColor(COLORS.BORDER)
          Text('仪表盘').fontSize(13).fontColor(COLORS.PRIMARY)
            .fontWeight(500)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/DashboardPage' })
              } catch (_e) {
                // ignore router.pushUrl error
              }
            })
          Text('  |  ').fontSize(13).fontColor(COLORS.BORDER)
          if (this.appState.member.hasFamilyAccess()) {
            Text('周报').fontSize(13).fontColor(COLORS.TEXT_GRAY_7575)
              .onClick(() => {
                try {
                  router.pushUrl({ url: 'pages/WeeklyReportPage' })
                } catch (_e) {
                  // ignore router.pushUrl error
                }
              })
            Text('  |  ').fontSize(13).fontColor(COLORS.BORDER)
          }
          Text('设备').fontSize(13).fontColor(COLORS.TEXT_GRAY_7575)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/DeviceDashboardPage' })
              } catch (_e) {
                // ignore router.pushUrl error
              }
            })
          Text('  |  ').fontSize(13).fontColor(COLORS.BORDER)
          Text('设置').fontSize(13).fontColor(COLORS.TEXT_GRAY_7575)
            .onClick(() => {
              try {
                router.pushUrl({ url: 'pages/SettingsPage' })
              } catch (_e) {
                // ignore router.pushUrl error
              }
            })
        }
        .margin({ bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)

    // 链接输入浮层
    if (this.showLinkInput) {
      Column() {
        Column() {
          Text('粘贴商品链接')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.TEXT_PRIMARY)
            .margin({ bottom: 16 })

          TextInput({ placeholder: '粘贴京东/淘宝/天猫商品链接...', text: this.linkInputText })
            .width('100%')
            .height(BUTTON.HEIGHT_SECONDARY)
            .borderRadius(8)
            .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
            .padding({ left: 12, right: 12 })
            .placeholderColor(COLORS.TEXT_TERTIARY)
            .onChange((value: string) => { this.linkInputText = value })

          Row({ space: 12 }) {
            Button('取消')
              .width('45%')
              .height(BUTTON.HEIGHT_SECONDARY)
              .borderRadius(BUTTON.RADIUS_SECONDARY)
              .backgroundColor(COLORS.BORDER)
              .fontColor(COLORS.TEXT_SECONDARY)
              .onClick(() => {
                this.showLinkInput = false
                this.linkInputText = ''
              })

            Button() {
              if (this.isParsingLink) {
                LoadingProgress()
                  .width(20)
                  .height(20)
                  .color(COLORS.WHITE)
              } else {
                Text('解析链接').fontColor(COLORS.WHITE).fontSize(16)
              }
            }
            .width('45%')
            .height(BUTTON.HEIGHT_SECONDARY)
            .borderRadius(BUTTON.RADIUS_SECONDARY)
            .backgroundColor(COLORS.PURPLE_ACCENT)
            .enabled(!this.isParsingLink)
            .onClick(() => { this.handleParseLink(this.linkInputText) })
          }
          .margin({ top: 16 })
        }
        .width('85%')
        .padding(24)
        .backgroundColor(COLORS.WHITE)
        .borderRadius(16)
        .shadow({ radius: 12, color: COLORS.SHADOW, offsetY: 4 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#66000000')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        this.showLinkInput = false
        this.linkInputText = ''
      })
      .position({ x: 0, y: 0 })
      .zIndex(999)
    }
  }
}

@Builder
  buildMilestoneCarousel() {
    Column() {
      Row() {
        Text('🏆 成就里程碑')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
        Text('查看全部')
          .fontSize(11)
          .fontColor(COLORS.ACCENT_BLUE)
          .onClick(() => {
            try {
              router.pushUrl({ url: 'pages/SettingsPage' })
            } catch (_e) {
              hilog.warn(DOMAIN_ZERO, 'HomePage', 'pushUrl failed: %{public}s', JSON.stringify(_e));
            }
          })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Scroll() {
        Row({ space: 12 }) {
          ForEach(this.milestones, (milestone: Milestone) => {
            this.MilestoneCard(milestone)
          })
        }
        .padding({ left: 0, right: 0 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(10)
    .margin({ left: 16, right: 16, bottom: 12 })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  MilestoneCard(milestone: Milestone) {
    Column() {
      // Emoji 图标
      Text(milestone.icon)
        .fontSize(28)
        .margin({ bottom: 6 })

      // 标题
      Text(milestone.title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(COLORS.TEXT_GRAY_2121)
        .lineHeight(18)
        .maxLines(1)
        .margin({ bottom: 8 })

      // 进度条
      Row() {
        Column() {
          // 进度条背景
          Row() {
            Column() {
              // 进度条填充
              Row()
                .width(`${milestone.progress}%`)
                .height(6)
                .backgroundColor(milestone.achieved && !milestone.acknowledged ? COLORS.WARNING : COLORS.PRIMARY)
                .borderRadius(3)
            }
            .width('100%')
            .height(6)
            .backgroundColor(COLORS.BORDER)
            .borderRadius(3)
          }
          .width('100%')
          .margin({ bottom: 4 })

          // 百分比文字
          if (milestone.achieved) {
            Text('✅ 已完成')
              .fontSize(11)
              .fontColor(COLORS.LEVEL_GREEN)
          } else {
            Text(`${milestone.progress}% (${milestone.current}/${milestone.target})`)
              .fontSize(10)
              .fontColor(COLORS.TEXT_TERTIARY)
          }
        }
        .layoutWeight(1)
      }
    }
    .width(160)
    .height(120)
    .padding(12)
    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
    .borderRadius(12)
    .border(milestone.achieved && !milestone.acknowledged ?
      { width: 2, color: COLORS.WARNING } : undefined)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (milestone.achieved) {
        promptAction.showToast({
          message: `🎉 恭喜达成「${milestone.title}」！解锁了新的饮食智慧`,
          duration: 3000
        })
        this.milestoneService.acknowledgeMilestone(milestone.name)
        // 刷新以去掉金色边框
        this.refreshMilestones()
      }
    })
  }

  @Builder
  buildFamilyStatusBar() {
    Column() {
      Row() {
        Text('💡')
          .fontSize(16)
          .margin({ right: 4 })
        Text('今日家庭状态')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(COLORS.TEXT_PRIMARY)
        Blank()
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.familyMembers.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.familyMembers, (member: FamilyProfile) => {
            this.buildMemberStatusItem(member)
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(10)
    .margin({ left: 16, right: 16, bottom: 12 })
    .shadow({ radius: 2, color: '#1A000000', offsetY: 1 })
  }

  @Builder
  buildMemberStatusItem(member: FamilyProfile) {
    Row() {
      Text(this.getMemberEmoji(member))
        .fontSize(14)
        .margin({ right: 4 })
      Text(member.nickname)
        .fontSize(12)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ right: 4 })
      Text(this.getMemberStatusText(member))
        .fontSize(11)
        .fontColor(this.getMemberStatusColor(member))
    }
    .width('48%')
    .margin({ top: 4, bottom: 4 })
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.nickname === '爸爸') return '👨'
    if (member.nickname === '妈妈') return '👩'
    if (member.nickname === '孩子') return '👶'
    return '🧑'
  }

  private getMemberStatusText(member: FamilyProfile): string {
    const cached = this.memberStatusMap.get(member.memberId)
    if (cached !== undefined) {
      return cached.text
    }
    return this.computeStatusFromBudget(member, undefined).text
  }

  private getMemberStatusColor(member: FamilyProfile): string {
    const cached = this.memberStatusMap.get(member.memberId)
    if (cached !== undefined) {
      return cached.color
    }
    return this.computeStatusFromBudget(member, undefined).color
  }

  /**
   * 基于DailyBudget计算成员状态文本与颜色
   * 映射关系：
   * 控压 → 钠剩余百分比
   * 控糖 → 糖剩余百分比
   * 减脂 → 热量剩余百分比
   * 儿童 → 所有维度中最低的百分比
   * 无目标 → 平均剩余百分比
   */
  private computeStatusFromBudget(member: FamilyProfile, budget: DailyBudget | undefined): StatusResult {
    if (budget === undefined) {
      // 后备：从成员配置构建一个完整的预算（refreshMemberStatuses 已异步加载缓存）
      // 此路径仅在模板渲染时缓存尚未填充的情况下触发
      budget = new DailyBudget()
      budget.memberId = member.memberId
      budget.date = this.getTodayDate()
      budget.sodiumBudget = member.dailyBudget.sodiumBudget
      budget.sugarBudget = member.dailyBudget.sugarBudget
      budget.calorieBudget = member.dailyBudget.calorieBudget
      budget.fatBudget = member.dailyBudget.fatBudget
      budget.sodiumRemaining = budget.sodiumBudget
      budget.sugarRemaining = budget.sugarBudget
      budget.calorieRemaining = budget.calorieBudget
      budget.fatRemaining = budget.fatBudget
    }
    const goal: HealthGoal = member.healthGoals.length > 0 ? member.healthGoals[0] : HealthGoal.NONE

    let usage: number = 0
    let primaryMetric: string = ''

    if (goal === HealthGoal.CONTROL_BP) {
      usage = budget.sodiumUsagePercent()
      primaryMetric = '钠'
    } else if (goal === HealthGoal.CONTROL_SUGAR) {
      usage = budget.sugarUsagePercent()
      primaryMetric = '糖'
    } else if (goal === HealthGoal.LOSE_FAT) {
      usage = budget.calorieUsagePercent()
      primaryMetric = '热量'
    } else if (goal === HealthGoal.CHILD) {
      usage = Math.max(
        budget.sodiumUsagePercent(),
        budget.sugarUsagePercent(),
        budget.calorieUsagePercent(),
        budget.fatUsagePercent()
      )
      primaryMetric = '综合'
    } else {
      usage = (budget.sodiumUsagePercent() + budget.sugarUsagePercent() +
        budget.calorieUsagePercent() + budget.fatUsagePercent()) / 4
      primaryMetric = '综合'
    }

    const remaining = Math.max(0, 100 - Math.round(usage))
    const text = remaining >= 80 ? primaryMetric + '预算余' + remaining + '%（充足）' :
      remaining >= 50 ? primaryMetric + '预算剩余' + remaining + '%' :
        remaining >= 20 ? '⚠️ ' + primaryMetric + '额度紧张(' + remaining + '%)' :
          '🚫 ' + primaryMetric + '额度已用尽!'

    const color = remaining >= 50 ? COLORS.LEVEL_GREEN :
      remaining >= 20 ? COLORS.LEVEL_ORANGE :
        COLORS.LEVEL_RED

    return new StatusResult(text, color)
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}

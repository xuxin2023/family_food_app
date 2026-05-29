import {
  ToastHelper, safeBack, safePushUrl, getPageParams, Recommendation, FamilyProfile, GroupSummary, FeedType, BUTTON, COLORS, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { ShareCard } from 'feature_report';
import { ShareService } from '../service/ShareService';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'SharePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@Entry
@ComponentV2
struct SharePage {
  @Local isLoading: boolean = true
  @Local foodName: string = ''
  @Local recommendations: Recommendation[] = []
  @Local familyMembers: FamilyProfile[] = []
  @Local shareText: string = ''
  @Local copyHint: string = ''
  @Local isWorking: boolean = false
  @Local myGroups: GroupSummary[] = []
  @Local showGroupPicker: boolean = false
  @Local showRecipePublish: boolean = false
  @Local currentBreakpoint: string = 'md'

  private appState: AppState = AppState.getInstance()
  private shareService: ShareService = new ShareService()

  async aboutToAppear() {
    try {
      this.isLoading = true
      const params = getPageParams()
      const rawFoodName = params !== undefined ? params.get('foodName') : undefined;
      this.foodName = (typeof rawFoodName === 'string' ? rawFoodName : '');
      const rawRecs = params !== undefined ? params.get('recommendations') : undefined;
      this.recommendations = (Array.isArray(rawRecs) ? rawRecs as Recommendation[] : []);
      const rawMembers = params !== undefined ? params.get('members') : undefined;
      this.familyMembers = (Array.isArray(rawMembers) ? rawMembers as FamilyProfile[] : []);

      const membersPromise = this.familyMembers.length === 0
        ? this.appState.getAllMembers()
        : Promise.resolve(this.familyMembers)

      const allResults = await Promise.all([
        membersPromise,
        this.appState.getMyGroups().catch((e: Object) => {
          hilog.warn(DOMAIN_ZERO, TAG, '加载群组列表失败: %{public}s', JSON.stringify(e));
          return [] as GroupSummary[]
        })
      ])
      const members = allResults[0] as FamilyProfile[]
      const myGroups = allResults[1] as GroupSummary[]

      if (this.familyMembers.length === 0) {
        this.familyMembers = members
      }

      this.copyHint = this.shareService.getCopyHint()
      this.refreshShareText()
      this.myGroups = myGroups
      this.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.isLoading = false
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
            .accessibilityText('返回')
            .accessibilityLevel('yes')
          Text($r('app.string.share_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        GridRow({
          columns: { sm: 4, md: 8, lg: 12 },
          breakpoints: { reference: BreakpointsReference.WindowSize, breakpoints: ['320vp', '600vp'] } as BreakPoints
        }) {
          GridCol({ span: { sm: 4, md: 8, lg: 10 }, offset: { sm: 0, md: 0, lg: 1 } }) {
            Column() {
              if (this.recommendations.length > 0) {
                Column() {
                  ShareCard({
                    foodName: this.foodName,
                    recommendations: this.recommendations,
                    members: this.familyMembers
                  })
                }
                .id('shareCardComponent')
                .width('90%')
                .margin({ bottom: 16 })
              }

              // 分享文案
              Column() {
                Text($r('app.string.share_copy_text'))
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 8 })

                Text(this.copyHint)
                  .fontSize(12)
                  .fontColor(COLORS.TEXT_GRAY_7575)
                  .margin({ bottom: 12 })

                TextArea({ text: this.shareText, placeholder: $r('app.string.share_placeholder') })
                  .width('100%')
                  .height(180)
                  .padding(12)
                  .backgroundColor(COLORS.BG_PAGE_LIGHT)
                  .borderRadius(12)
                  .onChange((value: string) => { this.shareText = value })

                Row() {
                  Button($r('app.string.share_refresh'))
                    .layoutWeight(1)
                    .height(BUTTON.HEIGHT_SECONDARY)
                    .backgroundColor(COLORS.BG_WARM_BLUE)
                    .fontColor(COLORS.PRIMARY)
                    .borderRadius(BUTTON.RADIUS_SECONDARY)
                    .onClick(() => { this.refreshShareText() })
                    .accessibilityText('刷新文案')
                    .accessibilityLevel('yes')

                  Button($r('app.string.share_copy'))
                    .layoutWeight(1)
                    .height(BUTTON.HEIGHT_SECONDARY)
                    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                    .fontColor(COLORS.TEXT_GRAY_6161)
                    .borderRadius(BUTTON.RADIUS_SECONDARY)
                    .margin({ left: 10 })
                    .onClick(() => {
                      ToastHelper.show(this.getUIContext(), this.copyHint)
                    })
                    .accessibilityText('复制文案')
                    .accessibilityLevel('yes')
                }
                .width('100%')
                .margin({ top: 12 })
              }
              .width('90%')
              .padding(16)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(16)
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 16 })

              // 社交分享区
              Column() {
                Text($r('app.string.share_to_group_title'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                if (this.myGroups.length === 0) {
                  Column() {
                    Text($r('app.string.no_group_hint'))
                      .fontSize(13)
                      .fontColor(COLORS.TEXT_GRAY_9E9E)
                      .margin({ bottom: 8 })
                    Button($r('app.string.create_or_join_group'))
                      .height(BUTTON.HEIGHT_SMALL)
                      .backgroundColor(COLORS.PRIMARY)
                      .borderRadius(BUTTON.RADIUS_SMALL)
                      .fontColor(COLORS.WHITE)
                      .fontSize(13)
                      .onClick(() => {
                        safePushUrl('pages/FamilyGroupPage')
                      })
                      .accessibilityText('创建或加入群组')
                      .accessibilityLevel('yes')
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Center)
                } else {
                  ForEach(this.myGroups.slice(0, 3), (group: GroupSummary) => {
                    Row() {
                      Stack() {
                        Circle()
                          .width(36)
                          .height(36)
                          .fill(COLORS.PRIMARY_LIGHT)
                        Text(group.groupName.substring(0, 1))
                          .fontSize(16)
                          .fontColor(COLORS.PRIMARY)
                      }
                      .width(36)
                      .height(36)
                      Column() {
                        Text(group.groupName)
                          .fontSize(14)
                          .fontWeight(FontWeight.Medium)
                        Text(`${group.memberCount}位成员`)
                          .fontSize(11)
                          .fontColor(COLORS.TEXT_GRAY_9E9E)
                      }
                      .margin({ left: 10 })
                      .layoutWeight(1)
                      Text($r('app.string.share_to_group_action'))
                        .fontSize(13)
                        .fontColor(COLORS.PRIMARY)
                        .onClick(async () => {
                          await this.shareToGroup(group.groupId)
                        })
                        .accessibilityText('分享到群组')
                        .accessibilityLevel('yes')
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 8 })
                  }, (group: GroupSummary) => group.groupId)
                }
              }
              .width('90%')
              .padding(16)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(16)
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 16 })

              // 发布食谱
              Column() {
                Row({ space: 10 }) {
                  Text('🍳').fontSize(20)
                  Column() {
                    Text($r('app.string.publish_as_recipe'))
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                    Text($r('app.string.publish_to_community'))
                      .fontSize(11)
                      .fontColor(COLORS.TEXT_GRAY_9E9E)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  Blank()
                  Text($r('app.string.share_go_publish'))
                    .fontSize(13)
                    .fontColor(COLORS.PRIMARY)
                    .onClick(() => {
                      const publishParams = new Map<string, Object>()
                      publishParams.set('relatedFoodId', this.foodName as Object)
                      safePushUrl('pages/RecipeCreatePage', publishParams)
                    })
                    .accessibilityText('前往发布食谱')
                    .accessibilityLevel('yes')
                }
                .width('100%')
              }
              .width('90%')
              .padding(16)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(16)
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 24 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
        }
        .width('100%')
        .onBreakpointChange((bp: string) => { this.currentBreakpoint = bp })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
  }

  private refreshShareText() {
    this.shareText = this.shareService.generateShareText(
      this.shareService.buildShareParams(this.foodName, this.recommendations, this.familyMembers)
    )
  }

  private async shareToGroup(groupId: string) {
    const summaryLines: string[] = []
    for (const rec of this.recommendations) {
      const member = this.familyMembers.find(m => m.memberId === rec.memberId)
      const name = member?.nickname || '成员'
      const amount = rec.maxAmount > 0 ? `建议上限 ${rec.maxAmount}g` : '建议暂时不吃'
      summaryLines.push(`${name}：${rec.level}，${amount}`)
    }

    try {
      await this.appState.shareFoodScanToGroup(
        groupId,
        this.foodName,
        this.foodName,
        50,
        `食品扫描：${this.foodName}`,
        summaryLines.join('\n')
      )
      ToastHelper.show(this.getUIContext(), $r('app.string.share_to_group_success'))
    } catch (e) {
      ToastHelper.show(this.getUIContext(), `分享失败：${(e as Error).message}`)
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
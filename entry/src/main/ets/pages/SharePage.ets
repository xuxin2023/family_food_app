import { router, promptAction } from '@kit.ArkUI';
import { BackButton } from '../components/BackButton';
import { safeBack, safePushUrl } from '../utils/RouterUtil';
import { Recommendation } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';
import { ShareCard } from '../components/ShareCard';
import { ShareService } from '../service/ShareService';
import { AppState } from '../AppState';
import { ShareActionResult } from '../service/share/ShareProvider';
import { GroupSummary } from '../model/FamilyGroup';
import { BUTTON, COLORS } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

@Entry
@ComponentV2
struct SharePage {
  @Local foodName: string = ''
  @Local recommendations: Recommendation[] = []
  @Local familyMembers: FamilyProfile[] = []
  @Local shareText: string = ''
  @Local copyHint: string = ''
  @Local isWorking: boolean = false
  @Local myGroups: GroupSummary[] = []
  @Local showGroupPicker: boolean = false
  @Local showRecipePublish: boolean = false

  private appState: AppState = AppState.getInstance()
  private shareService: ShareService = new ShareService()

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    if (params) {
      this.foodName = (params.foodName as string) || ''
      this.recommendations = (params.recommendations as Recommendation[]) || []
      this.familyMembers = (params.members as FamilyProfile[]) || []
    }

    if (this.familyMembers.length === 0) {
      this.familyMembers = await this.appState.getAllMembers()
    }

    this.copyHint = this.shareService.getCopyHint()
    this.refreshShareText()

    // 加载群组列表
    try {
      this.myGroups = await this.appState.getMyGroups()
    } catch (_e) {
      // 忽略，社交服务可能未初始化
    }
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
            .onClick(() => { safeBack() })
          Text($r('app.string.share_title'))
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

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

            Button($r('app.string.share_copy'))
              .layoutWeight(1)
              .height(BUTTON.HEIGHT_SECONDARY)
              .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
              .fontColor(COLORS.TEXT_GRAY_6161)
              .borderRadius(BUTTON.RADIUS_SECONDARY)
              .margin({ left: 10 })
              .onClick(() => {
                promptAction.showToast({ message: this.copyHint })
              })
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
                  Text(group.group.groupName.substring(0, 1))
                    .fontSize(16)
                    .fontColor(COLORS.PRIMARY)
                }
                .width(36)
                .height(36)
                Column() {
                  Text(group.group.groupName)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                  Text(`${group.members.length}位成员`)
                    .fontSize(11)
                    .fontColor(COLORS.TEXT_GRAY_9E9E)
                }
                .margin({ left: 10 })
                .layoutWeight(1)
                Text($r('app.string.share_to_group_action'))
                  .fontSize(13)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(async () => {
                    await this.shareToGroup(group.group.groupId)
                  })
              }
              .width('100%')
              .padding({ top: 8, bottom: 8 })
            })
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
                const publishParams: Record<string, Object> = {} as Record<string, Object>
                publishParams['relatedFoodId'] = this.foodName
                safePushUrl('pages/RecipeCreatePage', publishParams)
              })
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
        '',
        0,
        summaryLines.join('\n'),
        ''
      )
      promptAction.showToast({ message: '已分享到群组！' })
    } catch (e) {
      promptAction.showToast({ message: `分享失败：${(e as Error).message}` })
    }
  }
}
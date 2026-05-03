import { router, promptAction } from '@kit.ArkUI';
import { Recommendation } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';
import { ShareCard } from '../components/ShareCard';
import { ShareService } from '../service/ShareService';
import { AppState } from '../AppState';
import { ShareActionResult } from '../service/share/ShareProvider';

@Entry
@Component
struct SharePage {
  @State foodName: string = ''
  @State recommendations: Recommendation[] = []
  @State familyMembers: FamilyProfile[] = []
  @State shareText: string = ''
  @State copyHint: string = ''
  @State isWorking: boolean = false

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
  }

  build() {
    Scroll() {
      Column() {
        Row() {
          Text('<')
            .fontSize(24)
            .fontColor('#1976D2')
            .onClick(() => { try { router.back() } catch (_e) { /* ignore */ } })
          Text('分享文案')
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

        Column() {
          Text('可复制分享文案')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })

          Text(this.copyHint)
            .fontSize(12)
            .fontColor('#757575')
            .margin({ bottom: 12 })

          TextArea({ text: this.shareText, placeholder: '报告生成后，这里会出现可复制文案。' })
            .width('100%')
            .height(220)
            .padding(12)
            .backgroundColor('#F7F8FA')
            .borderRadius(12)
            .onChange((value: string) => { this.shareText = value })

          Row() {
            Button('刷新文案')
              .layoutWeight(1)
              .height(44)
              .backgroundColor('#E3F2FD')
              .fontColor('#1976D2')
              .borderRadius(22)
              .onClick(() => { this.refreshShareText() })

            Button('复制说明')
              .layoutWeight(1)
              .height(44)
              .backgroundColor('#F5F5F5')
              .fontColor('#616161')
              .borderRadius(22)
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
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 16 })

        Column() {
          Text('未接入的系统能力')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 8 })

          Text('P0 版先保证文案可复制；系统分享、图片生成、保存相册都不会再提示假成功。')
            .fontSize(12)
            .fontColor('#757575')
            .margin({ bottom: 12 })

          Row() {
            Button('系统分享')
              .layoutWeight(1)
              .height(44)
              .backgroundColor('#EEEEEE')
              .fontColor('#616161')
              .borderRadius(22)
              .onClick(() => { this.handleUnsupportedAction('family') })

            Button('微信分享')
              .layoutWeight(1)
              .height(44)
              .backgroundColor('#EEEEEE')
              .fontColor('#616161')
              .borderRadius(22)
              .margin({ left: 10 })
              .onClick(() => { this.handleUnsupportedAction('wechat') })
          }
          .width('100%')

          Button('保存图片 / 相册')
            .width('100%')
            .height(44)
            .backgroundColor('#EEEEEE')
            .fontColor('#616161')
            .borderRadius(22)
            .margin({ top: 10 })
            .onClick(() => { this.handleUnsupportedAction('image') })
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 24 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAFAFA')
  }

  private refreshShareText() {
    this.shareText = this.shareService.generateShareText(
      this.shareService.buildShareParams(this.foodName, this.recommendations, this.familyMembers)
    )
  }

  private async handleUnsupportedAction(action: 'family' | 'wechat' | 'image') {
    if (this.isWorking) {
      return
    }

    this.isWorking = true
    let result: ShareActionResult
    if (action === 'family') {
      result = await this.shareService.shareToFamily(this.shareText)
    } else if (action === 'wechat') {
      result = await this.shareService.shareToWechat(this.shareText)
    } else {
      result = await this.shareService.saveAsImage('shareCardComponent')
    }

    promptAction.showToast({ message: result.message })
    this.isWorking = false
  }
}

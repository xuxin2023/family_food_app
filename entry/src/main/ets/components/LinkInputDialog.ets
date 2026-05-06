// LinkInputDialog.ets
// 链接输入弹窗组件 - 粘贴电商商品链接进行解析

import { promptAction } from '@kit.ArkUI';
import { OnlineShoppingParser } from '../service/OnlineShoppingParser';
import { AppState } from '../AppState';
import { COLORS, BUTTON } from '../constants/AppTheme';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN_ZERO = 0;

@Component
export struct LinkInputDialog {
  linkInputText: string = ''
  isParsingLink: boolean = false
  onClose: () => void = () => {}

  private appState: AppState = AppState.getInstance()

  build() {
    Column() {
      Column() {
        Text('粘贴商品链接')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '粘贴京东/淘宝/拼多多商品链接', text: this.linkInputText })
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
              this.linkInputText = ''
              this.onClose()
            })

          Button() {
            if (this.isParsingLink) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(COLORS.WHITE)
            } else {
              Text('解析')
                .fontColor(COLORS.WHITE)
                .fontSize(16)
            }
          }
          .width('45%')
          .height(BUTTON.HEIGHT_SECONDARY)
          .borderRadius(BUTTON.RADIUS_SECONDARY)
          .backgroundColor(this.isParsingLink ? COLORS.TEXT_TERTIARY : COLORS.PRIMARY)
          .onClick(() => {
            if (!this.isParsingLink) {
              this.handleParseLink()
            }
          })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('85%')
      .padding(24)
      .backgroundColor(COLORS.WHITE)
      .borderRadius(16)
      .shadow({ radius: 16, color: '#33000000', offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#33000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.linkInputText = ''
      this.onClose()
    })
  }

  private async handleParseLink(): Promise<void> {
    const url = this.linkInputText.trim()
    if (url.length === 0) {
      promptAction.showToast({ message: '请输入或粘贴商品链接' })
      return
    }

    this.isParsingLink = true

    try {
      const parser = OnlineShoppingParser.getInstance()
      const parseResult = await parser.parseUrlToLabel(url)

      if (!parseResult.success || !parseResult.label) {
        promptAction.showToast({ message: parseResult.errorMessage || '解析失败，请检查链接' })
        this.isParsingLink = false
        return
      }

      this.appState.setReportParams(parseResult.label, [], [])

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
      promptAction.showToast({ message: '解析异常，请稍后重试' })
      hilog.error(DOMAIN_ZERO, 'LinkInputDialog', 'parseLink error: ' + JSON.stringify(error))
    } finally {
      this.isParsingLink = false
      this.linkInputText = ''
      this.onClose()
    }
  }
}

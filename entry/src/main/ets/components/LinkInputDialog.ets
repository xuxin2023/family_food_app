// LinkInputDialog.ets
// 链接输入弹窗组件 - 粘贴电商商品链接进行解析

import { ToastHelper, COLORS, BUTTON, safePushUrl, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { OnlineShoppingParser } from 'feature_scan';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@ComponentV2
export struct LinkInputDialog {
  linkInputText: string = ''
  isParsingLink: boolean = false
  onClose: () => void = () => {}

  private appState: AppState = AppState.getInstance()

  build() {
    Column() {
      Column() {
        Text($r('app.string.link_input_paste_product_link'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_PRIMARY)
          .margin({ bottom: 16 })

        TextInput({ placeholder: $r('app.string.link_input_paste_placeholder'), text: this.linkInputText })
          .width('100%')
          .height(BUTTON.HEIGHT_SECONDARY)
          .borderRadius(8)
          .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
          .padding({ left: 12, right: 12 })
          .placeholderColor(COLORS.TEXT_TERTIARY)
          .accessibilityText($r('app.string.link_input_paste_product_link'))
          .accessibilityDescription($r('app.string.link_input_paste_desc'))
          .onChange((value: string) => { this.linkInputText = value })

        Row({ space: 12 }) {
          Button($r('app.string.link_input_cancel'))
            .width('45%')
            .height(BUTTON.HEIGHT_SECONDARY)
            .borderRadius(BUTTON.RADIUS_SECONDARY)
            .backgroundColor(COLORS.BORDER)
            .fontColor(COLORS.TEXT_SECONDARY)
            .onClick(() => {
              this.linkInputText = ''
              this.onClose()
            })
            .accessibilityText($r('app.string.link_input_cancel'))

          Button() {
            if (this.isParsingLink) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(COLORS.WHITE)
            } else {
              Text($r('app.string.link_input_parse'))
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
          .accessibilityText($r('app.string.link_input_confirm_parse'))
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
    .accessibilityText($r('app.string.link_input_paste_link'))
  }

  private async handleParseLink(): Promise<void> {
    const url = this.linkInputText.trim()
    if (url.length === 0) {
      ToastHelper.show(this.getUIContext(), $r('app.string.link_input_please_paste'))
      return
    }

    this.isParsingLink = true

    try {
      const parser = OnlineShoppingParser.getInstance()
      const parseResult = await parser.parseUrlToLabel(url)

      if (!parseResult.success || !parseResult.label) {
        ToastHelper.show(this.getUIContext(), parseResult.errorMessage || $r('app.string.link_input_parse_fail'))
        this.isParsingLink = false
        return
      }

      this.appState.reportCache.setParams(parseResult.label, [], [])

      const sourceName: string = parseResult.source ?? '';
      const navParams = new Map<string, Object>();
      navParams.set('foodLabelId', parseResult.label.foodId);
      navParams.set('sourceName', sourceName);
      navParams.set('fromEcommerce', true);
      safePushUrl('pages/ReportPage', navParams)
    } catch (error) {
      ToastHelper.show(this.getUIContext(), $r('app.string.link_input_parse_error'))
      hilog.error(DOMAIN_ZERO, 'LinkInputDialog', 'parseLink error: ' + JSON.stringify(error))
    } finally {
      this.isParsingLink = false
      this.linkInputText = ''
      this.onClose()
    }
  }
}
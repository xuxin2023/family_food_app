// PrivacyDialogPage.ets
// 隐私政策与用户协议确认页面 - 首次启动时展示
// 用户同意后方可进入主页面

import { router } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { COLORS } from '../constants/AppTheme';

const TAG = 'PrivacyDialogPage';
const DOMAIN_ZERO = 0;

@Entry
@Component
struct PrivacyDialogPage {
  @State currentTab: number = 0 // 0=隐私政策, 1=用户协议
  @State agreed: boolean = false
  @State showPrivacyContent: boolean = false
  @State showAgreementContent: boolean = false

  private privacyController: webview.WebviewController = new webview.WebviewController()
  private agreementController: webview.WebviewController = new webview.WebviewController()

  async aboutToAppear() {
    // 检查是否已经同意过
    const agreed = await this.checkPrivacyAgreed()
    if (agreed) {
      // 已同意过，直接跳转到首页
      this.navigateToHome()
    }
  }

  /**
   * 检查用户是否已同意隐私政策
   */
  private async checkPrivacyAgreed(): Promise<boolean> {
    try {
      const context = AppStorage.get<Object>('appContext') as Context
      if (!context) {
        return false
      }
      const pref = await preferences.getPreferences(context, 'privacy_settings')
      const agreed = await pref.get('privacy_agreed', false)
      return agreed as boolean
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'checkPrivacyAgreed failed')
      return false
    }
  }

  /**
   * 保存用户同意状态并跳转
   */
  private async onAgreeAndContinue(): Promise<void> {
    try {
      const context = AppStorage.get<Object>('appContext') as Context
      if (context) {
        const pref = await preferences.getPreferences(context, 'privacy_settings')
        await pref.put('privacy_agreed', true)
        await pref.flush()
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'save privacy agreed failed')
    }
    this.navigateToHome()
  }

  private navigateToHome(): void {
    try {
      router.replaceUrl({ url: 'pages/HomePage' })
    } catch (_e) {
      hilog.error(DOMAIN_ZERO, TAG, 'navigateToHome failed')
    }
  }

  build() {
    Stack() {
      Column() {
        // 顶部品牌标识
        Column() {
          Text('家庭饮食平衡助手')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.PRIMARY)
            .margin({ top: 40 })

          Text('欢迎使用')
            .fontSize(16)
            .fontColor(COLORS.TEXT_GRAY_7575)
            .margin({ top: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ bottom: 24 })

        // 隐私协议内容展示区
        Column() {
          if (!this.showPrivacyContent && !this.showAgreementContent) {
            // 缩略摘要模式
            Column() {
              Text('在使用本应用前，请您仔细阅读以下条款：')
                .fontSize(14)
                .fontColor(COLORS.TEXT_GRAY_3333)
                .lineHeight(22)
                .margin({ bottom: 16 })

              Row() {
                Text('1. ')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                Text('我们重视您的隐私保护，所有数据默认仅存储在您的设备本地。')
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_GRAY_3333)
                  .lineHeight(22)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .margin({ bottom: 8 })

              Row() {
                Text('2. ')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                Text('本应用提供的所有建议仅供饮食参考，不构成医疗建议。')
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_GRAY_3333)
                  .lineHeight(22)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .margin({ bottom: 8 })

              Row() {
                Text('3. ')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                Text('您可随时在设置中查看、导出或删除您的数据。')
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_GRAY_3333)
                  .lineHeight(22)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .margin({ bottom: 8 })

              Row({ space: 16 }) {
                Text('查看隐私政策')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .decoration({ type: TextDecorationType.Underline })
                  .onClick(() => {
                    this.showPrivacyContent = true
                    this.showAgreementContent = false
                  })

                Text('查看用户协议')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .decoration({ type: TextDecorationType.Underline })
                  .onClick(() => {
                    this.showAgreementContent = true
                    this.showPrivacyContent = false
                  })
              }
              .margin({ top: 12 })
            }
            .width('100%')
            .padding(16)
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
          }

          // 隐私政策完整内容
          if (this.showPrivacyContent) {
            Column() {
              Row() {
                Text('← 返回')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => {
                    this.showPrivacyContent = false
                  })
                Blank()
                Text('隐私政策')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(COLORS.TEXT_GRAY_3333)
              }
              .width('100%')
              .margin({ bottom: 8 })

              Web({ src: $rawfile('privacy_policy.html'), controller: this.privacyController })
                .width('100%')
                .layoutWeight(1)
                .domStorageAccess(true)
                .javaScriptAccess(true)
            }
            .width('100%')
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
            .layoutWeight(1)
          }

          // 用户协议完整内容
          if (this.showAgreementContent) {
            Column() {
              Row() {
                Text('← 返回')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => {
                    this.showAgreementContent = false
                  })
                Blank()
                Text('用户协议')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(COLORS.TEXT_GRAY_3333)
              }
              .width('100%')
              .margin({ bottom: 8 })

              Web({ src: $rawfile('user_agreement.html'), controller: this.agreementController })
                .width('100%')
                .layoutWeight(1)
                .domStorageAccess(true)
                .javaScriptAccess(true)
            }
            .width('100%')
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
            .layoutWeight(1)
          }
        }
        .layoutWeight(1)
        .width('92%')

        // 同意复选框与操作按钮
        Column() {
          Row() {
            Checkbox()
              .selectedColor(COLORS.PRIMARY)
              .size({ width: 20, height: 20 })
              .onChange((isSelected: boolean) => {
                this.agreed = isSelected
              })
            Text('我已阅读并同意')
              .fontSize(13)
              .fontColor('#666666')
              .margin({ left: 8 })

            Text('《隐私政策》')
              .fontSize(13)
              .fontColor(COLORS.PRIMARY)
              .onClick(() => {
                this.showPrivacyContent = true
                this.showAgreementContent = false
              })

            Text('和')
              .fontSize(13)
              .fontColor('#666666')

            Text('《用户协议》')
              .fontSize(13)
              .fontColor(COLORS.PRIMARY)
              .onClick(() => {
                this.showAgreementContent = true
                this.showPrivacyContent = false
              })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 16 })

          Button('同意并继续')
            .width('100%')
            .height(50)
            .backgroundColor(this.agreed ? COLORS.PRIMARY : '#BDBDBD')
            .borderRadius(25)
            .fontColor(COLORS.WHITE)
            .fontSize(16)
            .enabled(this.agreed)
            .onClick(() => {
              if (this.agreed) {
                this.onAgreeAndContinue()
              }
            })
        }
        .width('92%')
        .padding({ bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FAFAFA')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}

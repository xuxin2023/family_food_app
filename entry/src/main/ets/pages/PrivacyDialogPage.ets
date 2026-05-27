// PrivacyDialogPage.ets
// 隐私政策与用户协议确认页面 - 首次启动时展示
// 用户同意后方可进入主页面

import { safeReplaceUrl, getPrivacyPolicyHtml, getUserAgreementHtml, COLORS, HILOG_DOMAIN } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppState } from '../AppState';
import { PrivacyManager, PrivacyDocumentUrls } from 'hsp_service';

const TAG = 'PrivacyDialogPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

@Entry
@ComponentV2
struct PrivacyDialogPage {
  @Local isLoading: boolean = true
  @Local currentTab: number = 0 // 0=隐私政策, 1=用户协议
  @Local agreed: boolean = false
  @Local showPrivacyContent: boolean = false
  @Local showAgreementContent: boolean = false
  @Local privacyHtml: string = ''
  @Local agreementHtml: string = ''
  @Local onlineDocUrls: PrivacyDocumentUrls | null = null

  private appState: AppState = AppState.getInstance()

  async aboutToAppear() {
    try {
      this.isLoading = true
      await AppState.waitForReady()

      const context = AppStorage.get<common.Context>('appContext')
      if (context) {
        PrivacyManager.getDocumentUrls(context).then((urls: PrivacyDocumentUrls) => {
          this.onlineDocUrls = urls
          hilog.info(DOMAIN_ZERO, TAG, 'Online doc URLs loaded, isOnline=%{public}s', urls.isOnline ? 'true' : 'false');
        }).catch((_e: Error) => {
          hilog.warn(DOMAIN_ZERO, TAG, 'Failed to load online doc URLs');
        })
      }

      const agreed = await this.checkPrivacyAgreed()
      if (agreed) {
        this.navigateToHome()
      }
      this.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.isLoading = false
    }
  }

  /**
   * 检查用户是否已同意隐私政策
   */
  private async checkPrivacyAgreed(): Promise<boolean> {
    try {
      const context = AppStorage.get<common.Context>('appContext')
      if (!context) {
        return false
      }
      return await this.appState.checkPrivacyAgreed(context)
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
      const context = AppStorage.get<common.Context>('appContext')
      if (context) {
        await this.appState.agreePrivacy(context)
      }
      this.appState.permission.setPrivacyAgreed()
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'save privacy agreed failed')
    }
    this.navigateToHome()
  }

  private navigateToHome(): void {
    safeReplaceUrl('pages/MainTabsPage')
  }

  build() {
    Stack() {
      Column() {
        // 顶部品牌标识
        Column() {
          Text($r('app.string.privacy_dialog_title'))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(COLORS.PRIMARY)
            .margin({ top: 40 })

          Text($r('app.string.welcome_title'))
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
              Text($r('app.string.privacy_terms_desc'))
                .fontSize(14)
                .fontColor(COLORS.TEXT_GRAY_3333)
                .lineHeight(22)
                .margin({ bottom: 16 })

              Row() {
                Text('1. ')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                Text($r('app.string.privacy_data_storage'))
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
                Text($r('app.string.privacy_medical_disclaimer'))
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
                Text($r('app.string.privacy_data_control'))
                  .fontSize(14)
                  .fontColor(COLORS.TEXT_GRAY_3333)
                  .lineHeight(22)
              }
              .width('100%')
              .alignItems(VerticalAlign.Top)
              .margin({ bottom: 8 })

              Row({ space: 16 }) {
                Text($r('app.string.privacy_policy'))
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .decoration({ type: TextDecorationType.Underline })
                  .onClick(() => {
                    this.showPrivacyContent = true
                    this.showAgreementContent = false
                  })
                  .accessibilityText('隐私政策')
                  .accessibilityLevel('yes')
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .decoration({ type: TextDecorationType.Underline })
                  .onClick(() => {
                    this.showAgreementContent = true
                    this.showPrivacyContent = false
                  })
                  .accessibilityText('用户协议')
                  .accessibilityLevel('yes')
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
                Text($r('app.string.back_arrow'))
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => {
                    this.showPrivacyContent = false
                  })
                  .accessibilityText('返回')
                  .accessibilityLevel('yes')
                Blank()
                Text($r('app.string.privacy_policy'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(COLORS.TEXT_GRAY_3333)
              }
              .width('100%')
              .margin({ bottom: 8 })

              RichText(this.privacyHtml)
                .width('100%')
                .layoutWeight(1)
            }
            .width('100%')
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
            .layoutWeight(1)
            .onAppear(() => {
              if (this.privacyHtml.length === 0) {
                const ctx = AppStorage.get<common.Context>('appContext')
                if (ctx) {
                  getPrivacyPolicyHtml(ctx).then(html => {
                    this.privacyHtml = html
                  })
                }
              }
            })
          }

          // 用户协议完整内容
          if (this.showAgreementContent) {
            Column() {
              Row() {
                Text($r('app.string.back_arrow'))
                  .fontSize(14)
                  .fontColor(COLORS.PRIMARY)
                  .onClick(() => {
                    this.showAgreementContent = false
                  })
                  .accessibilityText('返回')
                  .accessibilityLevel('yes')
                Blank()
                Text($r('app.string.user_agreement'))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(COLORS.TEXT_GRAY_3333)
              }
              .width('100%')
              .margin({ bottom: 8 })

              RichText(this.agreementHtml)
                .width('100%')
                .layoutWeight(1)
            }
            .width('100%')
            .backgroundColor(COLORS.WHITE)
            .borderRadius(12)
            .layoutWeight(1)
            .onAppear(() => {
              if (this.agreementHtml.length === 0) {
                const ctx = AppStorage.get<common.Context>('appContext')
                if (ctx) {
                  getUserAgreementHtml(ctx).then(html => {
                    this.agreementHtml = html
                  })
                }
              }
            })
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
              .accessibilityText('同意协议')
              .accessibilityLevel('yes')
            Text($r('app.string.agree_read'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ left: 8 })

            Text() {
              Span('《')
              Span($r('app.string.privacy_policy'))
              Span('》')
            }
              .fontSize(13)
              .fontColor(COLORS.PRIMARY)
              .onClick(() => {
                this.showPrivacyContent = true
                this.showAgreementContent = false
              })
              .accessibilityText('隐私政策')
              .accessibilityLevel('yes')

            Text($r('app.string.and_conjunction'))
              .fontSize(13)
              .fontColor('#666666')

            Text() {
              Span('《')
              Span($r('app.string.user_agreement'))
              Span('》')
            }
              .fontSize(13)
              .fontColor(COLORS.PRIMARY)
              .onClick(() => {
                this.showAgreementContent = true
                this.showPrivacyContent = false
              })
              .accessibilityText('用户协议')
              .accessibilityLevel('yes')
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 16 })

          Button($r('app.string.agree_continue'))
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
            .accessibilityText('同意并继续')
            .accessibilityLevel('yes')
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

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}
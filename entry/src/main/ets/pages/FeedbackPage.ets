// FeedbackPage.ets
// 用户反馈页面 - 支持 Bug报告/功能建议/使用问题/其他
// 匿名模式：无需登录即可提交

import { ToastHelper, safeBack, COLORS, HILOG_DOMAIN } from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { HuaweiCloudService } from 'hsp_service';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';
import { picker } from '@kit.CoreFileKit';

const TAG = 'FeedbackPage';
const DOMAIN_ZERO = HILOG_DOMAIN.DEFAULT;

const FEEDBACK_TYPES: ResourceStr[] = [$r('app.string.feedback_type_bug'), $r('app.string.feedback_type_feature'), $r('app.string.feedback_type_usage'), $r('app.string.feedback_type_other')];
const MAX_CONTENT_LENGTH: number = 500;
const MAX_SCREENSHOTS: number = 3;
const PREFS_FILE: string = 'feedback_cache';
const KEY_PENDING_FEEDBACKS: string = 'pending_feedbacks';

export class FeedbackData {
  type: string = '';
  content: string = '';
  contact: string = '';
  screenshots: string[] = [];
  timestamp: number = 0;
}

@Entry
@ComponentV2
struct FeedbackPage {
  @Local selectedTypeIndex: number = 0
  @Local content: string = ''
  @Local contact: string = ''
  @Local screenshotUris: string[] = []
  @Local isSubmitting: boolean = false

  build() {
    Column() {
      Row() {
        BackButton({ fontSize: 24, fontColor: COLORS.PRIMARY })
          .onClick(() => { safeBack() })
          .accessibilityText('返回')
          .accessibilityLevel('yes')
        Text($r('app.string.feedback_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })

      Scroll() {
        Column() {
          this.buildTypeSelector()
          this.buildContentInput()
          this.buildContactInput()
          this.buildScreenshotSection()
          this.buildSubmitButton()
        }
        .width('92%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildTypeSelector() {
    Column() {
      Text($r('app.string.feedback_type_label'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Row() {
        ForEach(FEEDBACK_TYPES, (item: string, index: number) => {
          Text(item)
            .fontSize(13)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .borderRadius(18)
            .backgroundColor(this.selectedTypeIndex === index ? COLORS.PRIMARY : '#F5F5F5')
            .fontColor(this.selectedTypeIndex === index ? COLORS.WHITE : COLORS.TEXT_GRAY_2121)
            .margin({ right: 8 })
            .onClick(() => { this.selectedTypeIndex = index })
            .accessibilityText(item)
            .accessibilityLevel('yes')
        }, (item: string, index: number) => `${index}`)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
  }

  @Builder
  buildContentInput() {
    Column() {
      Text($r('app.string.feedback_content'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      TextArea({ placeholder: $r('app.string.feedback_content_placeholder'), text: this.content })
        .width('100%')
        .height(120)
        .fontSize(14)
        .maxLength(MAX_CONTENT_LENGTH)
        .onChange((value: string) => {
          this.content = value
        })

      Text(`${this.content.length}/${MAX_CONTENT_LENGTH}`)
        .fontSize(12)
        .fontColor(COLORS.TEXT_GRAY_9E9E)
        .width('100%')
        .textAlign(TextAlign.End)
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildContactInput() {
    Column() {
      Text($r('app.string.feedback_contact'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      TextInput({ placeholder: $r('app.string.feedback_contact_placeholder'), text: this.contact })
        .width('100%')
        .fontSize(14)
        .onChange((value: string) => {
          this.contact = value
        })
        .accessibilityText('联系方式')
        .accessibilityLevel('yes')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildScreenshotSection() {
    Column() {
      Text($r('app.string.feedback_screenshot'))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Row() {
        ForEach(this.screenshotUris, (uri: string, index: number) => {
          Stack() {
            Image(uri)
              .width(80)
              .height(80)
              .borderRadius(8)
              .objectFit(ImageFit.Cover)

            Text('×')
              .fontSize(14)
              .fontColor(COLORS.WHITE)
              .width(20)
              .height(20)
              .borderRadius(10)
              .backgroundColor('#88000000')
              .textAlign(TextAlign.Center)
              .position({ x: 62, y: 0 })
              .onClick(() => {
                const newList: string[] = [...this.screenshotUris];
                newList.splice(index, 1);
                this.screenshotUris = newList;
              })
              .accessibilityText('删除截图')
              .accessibilityLevel('yes')
          }
          .width(80)
          .height(80)
          .margin({ right: 8 })
        }, (uri: string, index: number) => `${index}`)

        if (this.screenshotUris.length < MAX_SCREENSHOTS) {
          Column() {
            Text('+')
              .fontSize(28)
              .fontColor(COLORS.TEXT_GRAY_BDBD)
          }
          .width(80)
          .height(80)
          .borderRadius(8)
          .border({ width: 1, color: COLORS.DIVIDER })
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.pickScreenshot();
          })
          .accessibilityText('添加截图')
          .accessibilityLevel('yes')
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLORS.WHITE)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildSubmitButton() {
    Button($r('app.string.feedback_submit'))
      .width('100%')
      .height(50)
      .backgroundColor(this.content.length > 0 ? COLORS.PRIMARY : '#BDBDBD')
      .borderRadius(25)
      .fontColor(COLORS.WHITE)
      .fontSize(16)
      .enabled(this.content.length > 0 && !this.isSubmitting)
      .onClick(() => {
        this.submitFeedback();
      })
      .margin({ bottom: 24 })
      .accessibilityText('提交反馈')
      .accessibilityLevel('yes')
  }

  private async pickScreenshot(): Promise<void> {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = MAX_SCREENSHOTS - this.screenshotUris.length;
      const photoViewPicker = new picker.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        this.screenshotUris = [...this.screenshotUris, ...photoSelectResult.photoUris];
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Pick screenshot failed: %{public}s', JSON.stringify(e));
    }
  }

  private async submitFeedback(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }
    this.isSubmitting = true;

    const feedbackData = new FeedbackData();
    feedbackData.type = FEEDBACK_TYPES[this.selectedTypeIndex] as string;
    feedbackData.content = this.content;
    feedbackData.contact = this.contact;
    feedbackData.screenshots = [...this.screenshotUris];
    feedbackData.timestamp = Date.now();

    try {
      const payload = new Map<string, Object>();
      // Map<string, Object> requires Object-typed values for cloud function API
      payload.set('type', feedbackData.type as Object);
      payload.set('content', feedbackData.content as Object);
      payload.set('contact', feedbackData.contact as Object);
      payload.set('screenshots', feedbackData.screenshots as Object);
      payload.set('timestamp', feedbackData.timestamp as Object);

      const cloudService = HuaweiCloudService.getInstance();
      const result = await cloudService.callFunction('submitFeedback', payload);

      if (result.success) {
        ToastHelper.show(this.getUIContext(), $r('app.string.feedback_thanks'));
        this.resetForm();
      } else {
        await this.cacheFeedbackLocally(feedbackData);
        ToastHelper.show(this.getUIContext(), $r('app.string.feedback_cached'));
      }
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Submit feedback failed: %{public}s', JSON.stringify(e));
      await this.cacheFeedbackLocally(feedbackData);
      ToastHelper.show(this.getUIContext(), $r('app.string.feedback_cached'));
    } finally {
      this.isSubmitting = false;
    }
  }

  private async cacheFeedbackLocally(data: FeedbackData): Promise<void> {
    try {
      const ctx = AppStorage.get<common.Context>('appContext');
      if (!ctx) {
        return;
      }
      const pref = await preferences.getPreferences(ctx, PREFS_FILE);
      const existingStr = pref.getSync(KEY_PENDING_FEEDBACKS, '[]') as string;
      const existing: FeedbackData[] = JSON.parse(existingStr) as FeedbackData[];
      existing.push(data);
      pref.putSync(KEY_PENDING_FEEDBACKS, JSON.stringify(existing));
      await pref.flush();
    } catch (e) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Cache feedback failed: %{public}s', JSON.stringify(e));
    }
  }

  private resetForm(): void {
    this.selectedTypeIndex = 0;
    this.content = '';
    this.contact = '';
    this.screenshotUris = [];
  }

  pageTransition() {
    PageTransitionEnter({ duration: 350, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Right)
    PageTransitionExit({ duration: 250, curve: Curve.FastOutSlowIn })
      .slide(SlideEffect.Left)
  }
}

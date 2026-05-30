import {
  ToastHelper, safeBack, safePushUrl, getPageParams, Recommendation, FamilyProfile, GroupSummary, FeedType, BUTTON, COLORS, HILOG_DOMAIN_DEFAULT
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { ShareCard } from 'feature_report';
import { ShareService } from 'hsp_service';
import { ShareKitService } from 'hsp_service';
import { SharePosterGenerator, PosterData, PosterNutritionItem } from 'hsp_service';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.FileIo';

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
  @Local posterUri: string = ''
  @Local isGeneratingPoster: boolean = false
  @Local shareLink: string = ''

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
      this.shareLink = this.buildShareLink()
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

              // 系统分享按钮
              Column() {
                Text('分享到')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                Row({ space: 16 }) {
                  this.ShareChannelButton('微信', '#07C160', () => { this.systemShareText() })
                  this.ShareChannelButton('微博', '#E6162D', () => { this.systemShareText() })
                  this.ShareChannelButton('QQ', '#12B7F5', () => { this.systemShareText() })
                  this.ShareChannelButton('系统分享', COLORS.PRIMARY, () => { this.systemShareText() })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceEvenly)
              }
              .width('90%')
              .padding(16)
              .backgroundColor(COLORS.WHITE)
              .borderRadius(16)
              .alignItems(HorizontalAlign.Start)
              .margin({ bottom: 16 })

              // 海报预览与保存
              Column() {
                Text('分享海报')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 12 })

                if (this.posterUri.length > 0) {
                  Image(this.posterUri)
                    .width('100%')
                    .height(300)
                    .objectFit(ImageFit.Contain)
                    .borderRadius(8)
                    .margin({ bottom: 12 })
                } else {
                  Column() {
                    Text('点击生成分享海报')
                      .fontSize(13)
                      .fontColor(COLORS.TEXT_GRAY_9E9E)
                  }
                  .width('100%')
                  .height(180)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(COLORS.BG_PAGE_LIGHT)
                  .borderRadius(8)
                  .margin({ bottom: 12 })
                }

                Row() {
                  Button('生成海报')
                    .layoutWeight(1)
                    .height(BUTTON.HEIGHT_SECONDARY)
                    .backgroundColor(COLORS.PRIMARY)
                    .fontColor(COLORS.WHITE)
                    .borderRadius(BUTTON.RADIUS_SECONDARY)
                    .enabled(!this.isGeneratingPoster)
                    .onClick(() => { this.generatePoster() })
                    .accessibilityText('生成海报')
                    .accessibilityLevel('yes')

                  Button('保存到相册')
                    .layoutWeight(1)
                    .height(BUTTON.HEIGHT_SECONDARY)
                    .backgroundColor(COLORS.BG_LIGHT_GRAY_F5)
                    .fontColor(COLORS.TEXT_GRAY_6161)
                    .borderRadius(BUTTON.RADIUS_SECONDARY)
                    .margin({ left: 10 })
                    .enabled(this.posterUri.length > 0)
                    .onClick(() => { this.savePosterToAlbum() })
                    .accessibilityText('保存到相册')
                    .accessibilityLevel('yes')
                }
                .width('100%')

                if (this.shareLink.length > 0) {
                  Row() {
                    Text(this.shareLink)
                      .fontSize(11)
                      .fontColor(COLORS.TEXT_GRAY_9E9E)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Text('复制链接')
                      .fontSize(12)
                      .fontColor(COLORS.PRIMARY)
                      .margin({ left: 8 })
                      .onClick(() => { this.copyShareLink() })
                      .accessibilityText('复制链接')
                      .accessibilityLevel('yes')
                  }
                  .width('100%')
                  .margin({ top: 8 })
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

  private buildShareLink(): string {
    if (this.foodName.length === 0) return '';
    const encoded = encodeURIComponent(this.foodName);
    return `https://foodscan.familyfood.app/share?food=${encoded}`;
  }

  private async systemShareText(): Promise<void> {
    try {
      const context = AppStorage.get<common.UIAbilityContext>('appContext');
      if (!context) {
        ToastHelper.show(this.getUIContext(), '分享失败：无法获取上下文');
        return;
      }
      const shareContent = this.shareText.length > 0
        ? this.shareText
        : this.buildShareLink();
      await ShareKitService.shareText(context, shareContent, '分享食品报告');
    } catch (e) {
      ToastHelper.show(this.getUIContext(), `分享失败：${(e as Error).message}`);
    }
  }

  private async systemShareImage(): Promise<void> {
    if (this.posterUri.length === 0) {
      await this.generatePoster();
    }
    if (this.posterUri.length === 0) return;
    try {
      const context = AppStorage.get<common.UIAbilityContext>('appContext');
      if (!context) return;
      await ShareKitService.shareImage(context, this.posterUri, '分享食品海报');
    } catch (e) {
      ToastHelper.show(this.getUIContext(), `图片分享失败：${(e as Error).message}`);
    }
  }

  private async generatePoster(): Promise<void> {
    if (this.isGeneratingPoster) return;
    this.isGeneratingPoster = true;
    try {
      const context = AppStorage.get<common.UIAbilityContext>('appContext');
      if (!context) {
        ToastHelper.show(this.getUIContext(), '生成失败');
        return;
      }
      const posterData = new PosterData();
      posterData.foodName = this.foodName;
      posterData.brand = '';
      posterData.nutritionScore = this.recommendations.length > 0 ? 65 : 50;
      posterData.novaGroup = 2;
      posterData.shareLink = this.shareLink;

      const items: PosterNutritionItem[] = [];
      for (const rec of this.recommendations) {
        const member = this.familyMembers.find(m => m.memberId === rec.memberId);
        const item = new PosterNutritionItem();
        item.name = member?.nickname || '成员';
        item.value = rec.level;
        item.unit = rec.maxAmount > 0 ? `≤${rec.maxAmount}g` : '';
        items.push(item);
      }
      posterData.nutritionItems = items;

      const generator = new SharePosterGenerator(context);
      this.posterUri = await generator.generatePoster(posterData);
      ToastHelper.show(this.getUIContext(), '海报已生成');
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'generatePoster failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), '海报生成失败');
    } finally {
      this.isGeneratingPoster = false;
    }
  }

  private async savePosterToAlbum(): Promise<void> {
    if (this.posterUri.length === 0) return;
    try {
      const context = AppStorage.get<common.UIAbilityContext>('appContext');
      if (!context) {
        ToastHelper.show(this.getUIContext(), '保存失败');
        return;
      }
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
      const srcFile = fileIo.openSync(this.posterUri, fileIo.OpenMode.READ_ONLY);
      const dstFile = fileIo.openSync(uri, fileIo.OpenMode.WRITE_ONLY);
      const bufferSize = 4096;
      const buf = new ArrayBuffer(bufferSize);
      let readLen = fileIo.readSync(srcFile.fd, buf);
      while (readLen > 0) {
        fileIo.writeSync(dstFile.fd, buf, { length: readLen });
        readLen = fileIo.readSync(srcFile.fd, buf);
      }
      fileIo.closeSync(srcFile.fd);
      fileIo.closeSync(dstFile.fd);
      ToastHelper.show(this.getUIContext(), '已保存到相册');
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'savePosterToAlbum failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), '保存到相册失败');
    }
  }

  private copyShareLink(): void {
    if (this.shareLink.length === 0) return;
    try {
      const pasteboard = requireModule('@kit.BasicServicesKit').pasteboard;
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.shareLink);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteData);
      ToastHelper.show(this.getUIContext(), '链接已复制');
    } catch (e) {
      ToastHelper.show(this.getUIContext(), '复制失败');
    }
  }

  @Builder
  ShareChannelButton(label: string, color: string, action: () => void) {
    Column() {
      Stack() {
        Circle()
          .width(48)
          .height(48)
          .fill(color)
        Text(label.substring(0, 1))
          .fontSize(20)
          .fontColor(COLORS.WHITE)
          .fontWeight(FontWeight.Bold)
      }
      .width(48)
      .height(48)
      Text(label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ top: 4 })
    }
    .onClick(action)
    .accessibilityText(label)
    .accessibilityLevel('yes')
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
import {
  ToastHelper, safeBack, safePushUrl, getPageParams, Recommendation, FamilyProfile, GroupSummary, FeedType, BUTTON, COLORS, SHADOWS, HILOG_DOMAIN_DEFAULT, PageResourceTracker, createPageTracker, ThemeReactive, themeReactive
} from 'hsp_core';
import { BackButton } from '../components/BackButton';
import { GradientHeader } from '../components/GradientHeader';
import { ShareCard } from 'feature_report';
import { ShareService } from 'hsp_service';
import { ShareKitService } from 'hsp_service';
import { SharePosterGenerator, PosterData, PosterNutritionItem } from 'hsp_service';
import { AppState } from '../AppState';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { pasteboard } from '@kit.BasicServicesKit';

const TAG = 'SharePage';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

class ShareChannelBtnProps {
  label: string = '';
  color: string = '';
  action: () => void = () => {};
}

@ComponentV2
struct ShareChannelButtonCmp {
  @Param label: string = '';
  @Param color: string = '';
  @Event action: () => void = () => {};

  build() {
    Column() {
      Stack() {
        Circle()
          .width(48)
          .height(48)
          .fill(this.color)
        Text(this.label.substring(0, 1))
          .fontSize(20)
          .fontColor(COLORS.WHITE)
      }
      Text(this.label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ top: 6 })
    }
    .onClick(() => { this.action() })
    .accessibilityText(this.label)
    .accessibilityLevel('yes')
  }
}

@Entry
@ComponentV2
export struct SharePage {
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

  private tracker: PageResourceTracker = createPageTracker('SharePage')
  private themeRef: ThemeReactive = themeReactive

  async aboutToAppear() {
        this.tracker.onAppear()
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
      this.myGroups = myGroups
      this.refreshShareText()
      this.shareLink = this.buildShareLink()
      this.isLoading = false
    } catch (e) {
      hilog.error(DOMAIN_ZERO, TAG, 'aboutToAppear failed: %{public}s', JSON.stringify(e));
      this.isLoading = false
    }
  }

  aboutToDisappear(): void {
    this.tracker.onDisappear()
  }

  build() {
    Scroll() {
      Column() {
        GradientHeader({ title: this.foodName || '分享' })

        if (this.familyMembers.length > 0) {
          Column() {
            Text('成员评测结果')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            ForEach(this.familyMembers, (member: FamilyProfile) => {
              Text(member.nickname || '成员')
            }, (member: FamilyProfile) => member.memberId)
          }
        }

        Row({ space: 20 }) {
          this.ShareChannelButtonCmp('复制文本', COLORS.ACCENT_GREEN_4CAF, (): void => { this.copyShareText(); })
          this.ShareChannelButtonCmp('系统分享', COLORS.ACCENT_BLUE, (): void => { this.systemShareText(); })
          this.ShareChannelButtonCmp('生成海报', COLORS.ORANGE_ACCENT, (): void => { this.generatePoster(); })
          if (this.myGroups.length > 0) {
            this.ShareChannelButtonCmp('分享到组', COLORS.ACCENT_PURPLE_9C27, (): void => { this.showGroupPicker = true; })
          }
        }
        .margin({ top: 20, bottom: 20 })

        if (this.posterUri.length > 0) {
          Image(this.posterUri)
            .width('90%')
            .margin({ top: 20, bottom: 20 })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(COLORS.BG_PAGE)
    .opacity(this.themeRef.key >= 0 ? 1 : 1)
  }

  @Builder
  ShareChannelButtonCmp(label: string, color: string, action: () => void) {
    Column() {
      Stack() {
        Circle()
          .width(48)
          .height(48)
          .fill(color)
        Text(label.substring(0, 1))
          .fontSize(20)
          .fontColor(COLORS.WHITE)
      }
      Text(label)
        .fontSize(11)
        .fontColor(COLORS.TEXT_PRIMARY)
        .margin({ top: 6 })
    }
    .onClick(() => { action() })
  }

  private copyShareText(): void {
    if (this.shareText.length === 0) return;
    ToastHelper.show(this.getUIContext(), '已复制到剪贴板');
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
      hilog.warn(DOMAIN_ZERO, TAG, 'systemShareText failed: %{public}s', JSON.stringify(e));
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
      hilog.warn(DOMAIN_ZERO, TAG, 'shareImage failed: %{public}s', JSON.stringify(e));
      ToastHelper.show(this.getUIContext(), `图片分享失败：${(e as Error).message}`);
    }
  }

  private async generatePoster(): Promise<void> {
    if (this.isGeneratingPoster) return;
    this.isGeneratingPoster = true;
    try {
      const context = AppStorage.get<common.UIAbilityContext>('appContext');
      if (!context) {
        ToastHelper.show(this.getUIContext(), '生成海报失败');
        return;
      }
      const posterData: PosterData = new PosterData()
      posterData.foodName = this.foodName || '食品分享';
      posterData.brand = '扫描结果';

      const items: PosterNutritionItem[] = [];
      for (const rec of this.recommendations) {
        const member = this.familyMembers.find(m => m.memberId === rec.memberId);
        const item: PosterNutritionItem = new PosterNutritionItem()
        item.name = member?.nickname || '成员';
        item.value = rec.level;
        item.unit = rec.maxAmount > 0 ? `≤${rec.maxAmount}g` : '';
        items.push(item);
      }
      posterData.nutritionItems = items;

      const generator: SharePosterGenerator = new SharePosterGenerator(context)
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
      const buf: ArrayBuffer = new ArrayBuffer(bufferSize);
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
      const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.shareLink);
      const systemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteboardData);
      ToastHelper.show(this.getUIContext(), '链接已复制');
    } catch (e) {
      ToastHelper.show(this.getUIContext(), '复制失败');
    }
  }
}

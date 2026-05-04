// ShareCard.ets
// 分享卡组件 - 生成社交分享卡片
// V3增强：离线Canvas绘制1080x1080px分享图 + 保存到相册

import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Recommendation, getLevelColorValue } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';
import { FoodRecommendation, RecommendationLevel } from '../model/FoodAdapterTypes';
import { COLORS } from '../constants/AppTheme';

const TAG = 'ShareCardGenerator';
const DOMAIN_ZERO = 0;

// ===== 分享图片参数类型 =====

export interface MemberShareInfo {
  name: string;
  levelText: string;
  levelColor: string;
  maxIntake: string;
}

export interface ShareImageParams {
  foodName: string;
  nutriScore: number;
  levelColor: string;
  memberResults: MemberShareInfo[];
  cardType: string;
  qrPlaceholder: string;
}

export class GradientColorPair {
  start: string = '';
  end: string = '';
}

// ===== 分享卡片数据 =====

export interface ShareCardData {
  title: string;
  memberSummaries: string[];
  keyAdvice: string;
  appName: string;
  qrPlaceholder: string;
}

// ===== 分享文案模板 =====

export class ShareCardGenerator {
  // ==================== 图片生成 ====================

  /**
   * 生成分享图片（1080x1080px Canvas绘制）
   * 使用 OffscreenCanvas 离线绘制 → PixelMap → 保存到相册
   */
  static async generateShareImage(context: common.Context, params: ShareImageParams): Promise<string> {
    try {
      // 1. 创建离屏 Canvas（1080x1080px）
      const canvasWidth = 1080;
      const canvasHeight = 1080;
      const offCanvas = new OffscreenCanvas(canvasWidth, canvasHeight);
      const ctx = offCanvas.getContext("2d");

      // 2. 绘制整个画布白色背景
      ctx.fillStyle = COLORS.WHITE;
      ctx.fillRect(0, 0, canvasWidth, canvasHeight);

      // 3. 绘制顶部渐变背景区域 (0 ~ 400px)
      const topGradient = ctx.createLinearGradient(0, 0, 0, 400);
      const topColor = ShareCardGenerator.getTopGradientColor(params.levelColor);
      topGradient.addColorStop(0.0, topColor.start);
      topGradient.addColorStop(1.0, topColor.end);
      ctx.fillStyle = topGradient;
      ctx.fillRect(0, 0, canvasWidth, 400);

      // 4. 绘制食品名称（白色居中）
      ctx.fillStyle = COLORS.WHITE;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.font = 'bold 48px sans-serif';
      ctx.fillText(params.foodName, canvasWidth / 2, 160);

      // 5. 绘制 NutriScore 圆形徽章
      const badgeCenterX = canvasWidth / 2;
      const badgeCenterY = 280;
      const badgeRadius = 80;

      // 白色圆形背景
      ctx.beginPath();
      ctx.arc(badgeCenterX, badgeCenterY, badgeRadius, 0, Math.PI * 2);
      ctx.fillStyle = COLORS.WHITE;
      ctx.fill();
      ctx.closePath();

      // 评分数字（36px）
      ctx.fillStyle = params.levelColor;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.font = 'bold 36px sans-serif';
      ctx.fillText(`${params.nutriScore}`, badgeCenterX, badgeCenterY - 8);

      // 等级字母（24px）
      ctx.font = 'bold 24px sans-serif';
      const levelLetter = ShareCardGenerator.getNutriScoreLevel(params.nutriScore);
      ctx.fillText(levelLetter, badgeCenterX, badgeCenterY + 30);

      // 6. 绘制成员横向排列 (Y=480px 起)
      const memberStartY = 480;
      const memberCardWidth = 240;
      const memberSpacing = (canvasWidth - memberCardWidth * params.memberResults.length) / (params.memberResults.length + 1);

      for (let i = 0; i < params.memberResults.length && i < 4; i++) {
        const member = params.memberResults[i];
        const cardX = memberSpacing + i * (memberCardWidth + memberSpacing);

        // 圆形头像占位（灰色圆）
        const avatarX = cardX + memberCardWidth / 2;
        const avatarY = memberStartY + 40;
        ctx.beginPath();
        ctx.arc(avatarX, avatarY, 40, 0, Math.PI * 2);
        ctx.fillStyle = COLORS.BORDER_LIGHT;
        ctx.fill();
        ctx.closePath();

        // 昵称首字母作为占位文字
        ctx.fillStyle = COLORS.TEXT_GRAY_9E9E;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.font = '24px sans-serif';
        ctx.fillText(member.name.substring(0, 1), avatarX, avatarY);

        // 昵称（成员名称）
        ctx.fillStyle = COLORS.TEXT_GRAY_2121;
        ctx.font = '22px sans-serif';
        ctx.textBaseline = 'top';
        ctx.fillText(member.name, cardX + memberCardWidth / 2, memberStartY + 90);

        // 颜色胶囊（宽100px 高40px）
        const capsuleX = cardX + (memberCardWidth - 100) / 2;
        const capsuleY = memberStartY + 120;
        ctx.beginPath();
        ctx.roundRect(capsuleX, capsuleY, 100, 40, 20);
        ctx.fillStyle = member.levelColor;
        ctx.fill();
        ctx.closePath();

        // 胶囊内文字
        ctx.fillStyle = COLORS.WHITE;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.font = '18px sans-serif';
        ctx.fillText(member.levelText, capsuleX + 50, capsuleY + 20);

        // "最多X克"文字
        if (member.maxIntake.length > 0) {
          ctx.fillStyle = COLORS.TEXT_GRAY_7575;
          ctx.font = '16px sans-serif';
          ctx.textBaseline = 'top';
          ctx.fillText(member.maxIntake, cardX + memberCardWidth / 2, capsuleY + 48);
        }
      }

      // 7. 底部白色区域 (Y=740px 起)
      const bottomStartY = 740;

      // 分隔线
      ctx.beginPath();
      ctx.moveTo(80, bottomStartY);
      ctx.lineTo(canvasWidth - 80, bottomStartY);
      ctx.strokeStyle = COLORS.BORDER_LIGHT;
      ctx.lineWidth = 2;
      ctx.stroke();
      ctx.closePath();

      // App名称
      ctx.fillStyle = COLORS.TEXT_GRAY_3333;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.font = 'bold 28px sans-serif';
      ctx.fillText('家庭食品适配助手', canvasWidth / 2, bottomStartY + 50);

      // 口号
      ctx.fillStyle = COLORS.TEXT_GRAY_9E9E;
      ctx.font = '20px sans-serif';
      ctx.fillText('让关爱趁早', canvasWidth / 2, bottomStartY + 90);

      // 二维码占位（灰色方块 120x120px）
      const qrSize = 120;
      const qrX = (canvasWidth - qrSize) / 2;
      const qrY = bottomStartY + 120;
      ctx.fillStyle = COLORS.BG_LIGHT_GRAY_F5;
      ctx.fillRect(qrX, qrY, qrSize, qrSize);

      // 二维码占位文字
      ctx.fillStyle = COLORS.TEXT_GRAY_BDBD;
      ctx.font = '14px sans-serif';
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText(params.qrPlaceholder, canvasWidth / 2, qrY + qrSize / 2);

      // 8. 从 OffscreenCanvas 获取 PixelMap（通过 getPixelMap）
      const pixelMap = offCanvas.getContext("2d").getPixelMap(0, 0, canvasWidth, canvasHeight);

      // 9. 编码为 PNG buffer
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };
      const buffer: ArrayBuffer = await imagePackerApi.packToData(pixelMap, packOpts);
      imagePackerApi.release();

      // 10. 保存到相册
      const savedUri = await ShareCardGenerator.saveToAlbum(context, buffer);

      hilog.info(DOMAIN_ZERO, TAG, 'Share image generated and saved: %{public}s', savedUri);
      return savedUri;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'generateShareImage failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  /**
   * 保存 ArrayBuffer 图片数据到系统相册
   */
  private static async saveToAlbum(context: common.Context, buffer: ArrayBuffer): Promise<string> {
    try {
      const helper = photoAccessHelper.getPhotoAccessHelper(context);
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
      const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      await fileIo.write(file.fd, buffer);
      await fileIo.close(file.fd);
      return uri;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'saveToAlbum failed: %{public}s', JSON.stringify(error));
      return '';
    }
  }

  /**
   * 根据 NutriScore 获取顶部渐变色
   */
  private static getTopGradientColor(levelColor: string): GradientColorPair {
    const color = levelColor.toLowerCase();
    if (color === '#4caf50' || color === '#66bb6a') {
      return { start: '#66BB6A', end: '#4CAF50' };
    }
    if (color === '#ff9800' || color === '#ffa726') {
      return { start: '#FFA726', end: '#FF9800' };
    }
    if (color === '#ff5722' || color === '#ff7043') {
      return { start: '#FF7043', end: '#FF5722' };
    }
    if (color === '#f44336' || color === '#e53935') {
      return { start: '#F44336', end: '#D32F2F' };
    }
    return { start: COLORS.PRIMARY_LIGHT, end: COLORS.PRIMARY };
  }

  /**
   * NutriScore 分数转等级字母
   */
  private static getNutriScoreLevel(score: number): string {
    if (score >= 80) return 'A';
    if (score >= 60) return 'B';
    if (score >= 40) return 'C';
    if (score >= 20) return 'D';
    return 'E';
  }

  // ==================== 分享文案 ====================

  /**
   * 根据卡片类型生成分享文案
   */
  static getShareText(cardType: string, foodName: string, memberResults: MemberShareInfo[]): string {
    switch (cardType) {
      case 'FAMILY_COMPARE':
        return `给全家人查了这款${foodName}，建议居然不一样...`;
      case 'TODAY_CHANGE':
        return `昨天还能吃40g，今天只能25g，因为...`;
      case 'MEAL_BALANCE':
        return `吃完${foodName}，下一餐这样搭更平衡`;
      case 'CHILD_PROTECTION':
        return `孩子饭前想吃这个？先看看正餐保护提醒`;
      default:
        return `给全家人查了这款${foodName}，看看适合谁吃`;
    }
  }

  /**
   * 生成分享卡片数据
   */
  static generateShareCard(foodName: string, recommendations: FoodRecommendation[]): ShareCardData {
    const memberSummaries: string[] = [];
    let keyAdvice = '';
    let worstLevel: string = 'GREEN';

    for (const rec of recommendations) {
      const levelText = rec.levelText;
      const amountText = rec.maxIntake_g > 0 ? `最多${rec.maxIntake_g}g` : '建议避免';
      memberSummaries.push(`${rec.memberName}: ${levelText}（${amountText}）`);

      if (rec.level === RecommendationLevel.RED) worstLevel = 'RED';
      else if (rec.level === RecommendationLevel.ORANGE && worstLevel !== 'RED') worstLevel = 'ORANGE';
      else if (rec.level === RecommendationLevel.YELLOW && worstLevel === 'GREEN') worstLevel = 'YELLOW';

      if (rec.reason.length > 0 && keyAdvice.length === 0) {
        keyAdvice = rec.reason;
      }
    }

    if (keyAdvice.length === 0) {
      if (worstLevel === 'RED') keyAdvice = '这款食品对部分成员不太友好，建议谨慎选择';
      else if (worstLevel === 'ORANGE') keyAdvice = '部分成员需要注意食用量，适量就好';
      else keyAdvice = '这款食品全家都适合，放心食用吧';
    }

    const title = `给全家人查了这款${foodName}`;

    return {
      title: title,
      memberSummaries: memberSummaries,
      keyAdvice: keyAdvice,
      appName: '家庭食品适配助手',
      qrPlaceholder: '[二维码占位]'
    };
  }

  /**
   * 生成家庭群版分享文案
   */
  static generateFamilyGroupText(foodName: string, recommendations: FoodRecommendation[]): string {
    const parts: string[] = [`妈，这款${foodName}`];
    for (const rec of recommendations) {
      if (rec.level === RecommendationLevel.RED) {
        parts.push(`${rec.memberName}不建议`);
      } else if (rec.maxIntake_g > 0) {
        parts.push(`${rec.memberName}最多${rec.maxIntake_g}g`);
      } else {
        parts.push(`${rec.memberName}可以适量`);
      }
    }
    return parts.join('，');
  }

  /**
   * 生成朋友圈版分享文案
   */
  static generateMomentsText(foodName: string, recommendations: FoodRecommendation[]): string {
    const diffs = recommendations.filter(r => r.level === RecommendationLevel.GREEN).length;
    const total = recommendations.length;
    let line = `扫了一下${foodName}，发现全家人建议居然不一样…`;
    if (diffs < total) {
      line += `\n只有${diffs}位成员可以放心吃，其他成员要注意啦`;
    } else {
      line += `\n全家都能放心吃，太棒了！`;
    }
    return line;
  }

  /**
   * 生成实用版分享文案
   */
  static generatePracticalText(foodName: string, recommendations: FoodRecommendation[]): string {
    let keyIssue = '';
    for (const rec of recommendations) {
      if (rec.reason.includes('钠')) {
        keyIssue = '钠有点高';
        break;
      } else if (rec.reason.includes('糖')) {
        keyIssue = '糖有点多';
        break;
      } else if (rec.reason.includes('脂肪') || rec.reason.includes('油')) {
        keyIssue = '脂肪偏高';
        break;
      }
    }
    if (keyIssue.length === 0) keyIssue = '整体还行';

    const worst = recommendations.reduce((prev, curr) => {
      const order = [RecommendationLevel.GREEN, RecommendationLevel.YELLOW, RecommendationLevel.ORANGE, RecommendationLevel.RED];
      return order.indexOf(curr.level) > order.indexOf(prev.level) ? curr : prev;
    }, recommendations[0]);

    const amountText = worst.maxIntake_g > 0 ? `今天尝${worst.maxIntake_g}g就好` : '少量尝尝就好';

    return `刚扫了${foodName}，${keyIssue}，${amountText}，晚上别再吃咸的了～`;
  }
}

// ===== 组件（原有，兼容旧调用） =====

@Component
export struct ShareCard {
  @Prop foodName: string = '';
  @Prop recommendations: Recommendation[] = [];
  @Prop members: FamilyProfile[] = [];

  build() {
    Column() {
      Column() {
        Text('食品适配助手')
          .fontSize(11)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .margin({ bottom: 4 })
        Text(this.foodName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(COLORS.TEXT_GRAY_2121)
          .margin({ bottom: 16 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 20, bottom: 12 })

      Divider()
        .width('80%')
        .color(COLORS.BORDER_LIGHT)
        .margin({ bottom: 12 })

      Column() {
        ForEach(this.recommendations, (rec: Recommendation, index: number) => {
          this.ShareMemberRow(rec, this.members[index] || new FamilyProfile())
        }, (rec: Recommendation) => rec.memberId)
      }
      .width('100%')
      .padding({ left: 24, right: 24 })

      Column() {
        Text(this.generateSummary())
          .fontSize(11)
          .fontColor(COLORS.TEXT_GRAY_9E9E)
          .margin({ top: 12, bottom: 4 })
        Text('扫码查食品，全家更安心')
          .fontSize(11)
          .fontColor(COLORS.PRIMARY)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 8, bottom: 20 })
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#1A000000', offsetY: 2 })
  }

  @Builder
  ShareMemberRow(rec: Recommendation, member: FamilyProfile) {
    Row() {
      Text(this.getMemberEmoji(member))
        .fontSize(16)
        .margin({ right: 6 })
      Text(member.nickname)
        .fontSize(14)
        .width(36)

      Text(rec.level)
        .fontSize(13)
        .fontColor(COLORS.WHITE)
        .padding({ left: 10, right: 10, top: 3, bottom: 3 })
        .borderRadius(10)
        .backgroundColor(getLevelColorValue(rec.levelColor))
        .margin({ left: 8 })

      if (rec.maxAmount > 0) {
        Text(`最多${rec.maxAmount}g`)
          .fontSize(13)
          .fontColor(COLORS.TEXT_GRAY_2121)
          .margin({ left: 10 })
      }
    }
    .width('100%')
    .margin({ bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  private getMemberEmoji(member: FamilyProfile): string {
    if (member.nickname === '爸爸') return '👨';
    if (member.nickname === '妈妈') return '👩';
    if (member.nickname === '孩子') return '👶';
    return '🧑';
  }

  private generateSummary(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.recommendations.length && i < this.members.length; i++) {
      const rec = this.recommendations[i];
      const member = this.members[i];
      parts.push(`${member.nickname}${rec.level}`);
    }
    return parts.join('·');
  }
}

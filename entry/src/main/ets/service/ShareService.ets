import { FamilyProfile, Recommendation, RecommendLevel, StringRes } from 'hsp_core';
import { CopyTextProvider } from './share/CopyTextProvider';
import { ShareActionResult, ShareProvider, ShareTarget } from './share/ShareProvider';

export class ShareService {
  private provider: ShareProvider;

  constructor(provider: ShareProvider = new CopyTextProvider()) {
    this.provider = provider;
  }

  setProvider(provider: ShareProvider): void {
    this.provider = provider;
  }

  generateShareText(params: ShareParams): string {
    const lines: string[] = [];

    lines.push(`【家庭饮食提醒】${params.foodName}`);
    lines.push('');

    for (const member of params.memberResults) {
      const amountText = member.maxAmount > 0 ? `建议上限 ${member.maxAmount}g` : '建议暂时不吃';
      lines.push(`${member.displayName}：${member.level}，${amountText}`);
    }

    const summary = this.buildSummaryLine(params.memberResults);
    if (summary.length > 0) {
      lines.push('');
      lines.push(summary);
    }

    lines.push('');
    lines.push('更稳妥的做法：先看家庭适配报告，再决定份量和搭配。');
    lines.push('这条文案可直接复制后发到家庭群或微信。');

    return lines.join('\n');
  }

  buildShareParams(foodName: string, recommendations: Recommendation[], members: FamilyProfile[]): ShareParams {
    const memberMap: Map<string, FamilyProfile> = new Map();
    for (const member of members) {
      memberMap.set(member.memberId, member);
    }

    const memberResults: ShareMemberResult[] = [];
    for (const recommendation of recommendations) {
      const member = memberMap.get(recommendation.memberId);
      const mr = new ShareMemberResult();
      mr.displayName = member ? this.getDisplayName(member) : StringRes.FAMILY_MEMBERS;
      mr.level = recommendation.level;
      mr.maxAmount = recommendation.maxAmount;
      memberResults.push(mr);
    }

    const params = new ShareParams();
    params.foodName = foodName.length > 0 ? foodName : StringRes.UNNAMED_FOOD;
    params.memberResults = memberResults;
    return params;
  }

  getCopyHint(): string {
    return this.provider.getCopyHint();
  }

  async shareToFamily(_text: string): Promise<ShareActionResult> {
    return await this.provider.shareText(ShareTarget.FAMILY, _text);
  }

  async shareToWechat(_text: string): Promise<ShareActionResult> {
    return await this.provider.shareText(ShareTarget.WECHAT, _text);
  }

  async saveAsImage(_componentId: string): Promise<ShareActionResult> {
    return await this.provider.saveAsImage(_componentId);
  }

  async saveToAlbum(_imageUri: string): Promise<ShareActionResult> {
    return await this.provider.saveToAlbum(_imageUri);
  }

  generateFamilyShareText(foodName: string, recommendations: Recommendation[], members: FamilyProfile[]): string {
    return this.generateShareText(this.buildShareParams(foodName, recommendations, members));
  }

  private getDisplayName(member: FamilyProfile): string {
    if (member.nickname.length > 0) {
      return member.nickname;
    }
    return StringRes.FAMILY_MEMBERS;
  }

  private buildSummaryLine(memberResults: ShareMemberResult[]): string {
    const avoidCount = memberResults.filter(item => item.level === RecommendLevel.AVOID).length;
    const cautiousCount = memberResults.filter(item => item.level === RecommendLevel.CAUTIOUS).length;

    if (avoidCount > 0) {
      return `重点提醒：家里有 ${avoidCount} 位成员建议暂时不吃，先看完整报告更稳妥。`;
    }

    if (cautiousCount > 0) {
      return `重点提醒：家里有 ${cautiousCount} 位成员今天需要控量，建议小份并搭配清淡正餐。`;
    }

    if (memberResults.length > 0) {
      return '整体结论：这次更适合少量尝试，注意不要连续加餐。';
    }

    return '';
  }
}

export class ShareParams {
  foodName: string = '';
  memberResults: ShareMemberResult[] = [];
}

export class ShareMemberResult {
  displayName: string = '';
  level: RecommendLevel = RecommendLevel.CAUTIOUS;
  maxAmount: number = 0;
}
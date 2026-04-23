// 老人友好模式 - 大字版报告 + 语音播报 + 子女远程建档

import { Recommendation, RecommendLevel } from '../model/Recommendation';
import { FamilyProfile } from '../model/FamilyProfile';
import { FoodLabel } from '../model/FoodLabel';

// 老人友好报告
export class ElderFriendlyReport {
  oneLineConclusion: string = '';   // 一句话结论
  suggestedAmount: string = '';     // 建议份量
  todayReminder: string = '';       // 今日提醒
  voiceText: string = '';           // 语音播报文本
  familyShareText: string = '';     // 家庭群分享文本
}

export class ElderFriendlyEngine {
  /**
   * 生成老人友好报告
   * 大字版：一句话结论 + 建议份量 + 今日提醒
   */
  generate(rec: Recommendation, profile: FamilyProfile, food: FoodLabel): ElderFriendlyReport {
    const report = new ElderFriendlyReport();

    // 一句话结论
    if (rec.level === RecommendLevel.AVOID) {
      report.oneLineConclusion = `这款食品${profile.nickname}不建议吃`;
    } else if (rec.level === RecommendLevel.CAUTIOUS) {
      report.oneLineConclusion = `这款食品${profile.nickname}今天要少吃`;
    } else if (rec.level === RecommendLevel.SMALL_OK) {
      report.oneLineConclusion = `这款食品${profile.nickname}可以少量吃`;
    } else {
      report.oneLineConclusion = `这款食品${profile.nickname}可以吃`;
    }

    // 建议份量
    if (rec.maxAmount > 0) {
      if (rec.maxAmount >= 100) {
        report.suggestedAmount = `建议吃${Math.round(rec.maxAmount / 25)}小份以内`;
      } else {
        report.suggestedAmount = `建议不超过${rec.maxAmount}克`;
      }
    } else {
      report.suggestedAmount = '建议今天不吃';
    }

    // 今日提醒（取第一条原因）
    if (rec.reasons.length > 0) {
      report.todayReminder = rec.reasons[0];
    }
    if (rec.reminders.length > 0) {
      report.todayReminder = rec.reminders[0];
    }

    // 语音播报文本（自然语言，适合TTS）
    report.voiceText = this.generateVoiceText(rec, profile, food);

    // 家庭群分享文本
    report.familyShareText = this.generateFamilyShareText(rec, profile, food);

    return report;
  }

  /**
   * 生成语音播报文本
   * 适合转发给父母听，语气自然不生硬
   */
  private generateVoiceText(rec: Recommendation, profile: FamilyProfile, food: FoodLabel): string {
    const name = profile.nickname;
    const foodName = food.foodName;

    if (rec.level === RecommendLevel.AVOID) {
      return `${name}，这个${foodName}不太适合您，建议今天不要吃了。${rec.reasons.length > 0 ? '主要是因为' + rec.reasons[0] + '。' : ''}`;
    }

    if (rec.level === RecommendLevel.CAUTIOUS) {
      return `${name}，这个${foodName}今天要少吃一点，${rec.maxAmount > 0 ? '建议不超过' + rec.maxAmount + '克' : '尝一点就好'}。${rec.reasons.length > 0 ? rec.reasons[0] + '。' : ''}`;
    }

    if (rec.level === RecommendLevel.SMALL_OK) {
      return `${name}，这个${foodName}可以少量吃，${rec.maxAmount > 0 ? '建议' + rec.maxAmount + '克以内' : '控制份量'}。`;
    }

    return `${name}，这个${foodName}可以吃，注意正常份量就好。`;
  }

  /**
   * 生成家庭群分享文本（自然语言提醒，减少说教感）
   */
  generateFamilyShareText(rec: Recommendation, profile: FamilyProfile, food: FoodLabel): string {
    if (rec.level === RecommendLevel.AVOID) {
      return `${profile.nickname}，这个少吃点，${rec.reasons.length > 0 ? rec.reasons[0] : '不太适合'}`;
    }
    if (rec.level === RecommendLevel.CAUTIOUS) {
      return `${profile.nickname}，这个今天少吃，${rec.maxAmount > 0 ? '最多' + rec.maxAmount + '克' : '尝一点'}`;
    }
    if (rec.level === RecommendLevel.SMALL_OK) {
      return `${profile.nickname}可以少量吃，${rec.maxAmount > 0 ? '最多' + rec.maxAmount + '克' : '控制份量'}`;
    }
    return `${profile.nickname}可以吃这个`;
  }
}

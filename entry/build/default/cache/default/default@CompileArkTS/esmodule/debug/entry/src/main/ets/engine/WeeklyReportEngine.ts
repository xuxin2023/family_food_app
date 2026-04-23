import type { FamilyProfile } from '../model/FamilyProfile';
// 周报数据
export interface WeeklyDietData {
    memberId: string;
    weekStart: string; // YYYY-MM-DD
    weekEnd: string; // YYYY-MM-DD
    totalScans: number; // 本周扫描次数
    highSodiumDays: number; // 高盐天数
    highSugarDays: number; // 高糖天数
    highFatDays: number; // 高脂天数
    sweetNearMealCount: number; // 甜食靠近正餐次数
    lateNightSnackCount: number; // 夜宵次数
    heavyFlavorCount: number; // 重口味次数（烧烤/火锅/卤味等）
    childSnackOverLimit: number; // 儿童零食超标次数
}
// 周报结果
export class WeeklyReport {
    memberId: string = '';
    memberName: string = '';
    weekRange: string = '';
    summary: string = ''; // 一句话总结
    highlights: string[] = []; // 本周重点
    suggestions: string[] = []; // 下周建议
    buyLess: string[] = []; // 少买什么
    buyMore: string[] = []; // 建议备什么
}
// 采购建议
export class PurchaseAdvice {
    buyLess: string[] = [];
    buyMore: string[] = [];
}
export class WeeklyReportEngine {
    /**
     * 生成周报
     */
    generate(data: WeeklyDietData, profile: FamilyProfile): WeeklyReport {
        const report = new WeeklyReport();
        report.memberId = data.memberId;
        report.memberName = profile.nickname;
        report.weekRange = `${data.weekStart} ~ ${data.weekEnd}`;
        // 1. 一句话总结
        report.summary = this.generateSummary(data, profile);
        // 2. 本周重点
        report.highlights = this.generateHighlights(data, profile);
        // 3. 下周建议
        report.suggestions = this.generateSuggestions(data, profile);
        // 4. 采购建议
        const purchase = this.generatePurchaseAdvice(data, profile);
        report.buyLess = purchase.buyLess;
        report.buyMore = purchase.buyMore;
        return report;
    }
    private generateSummary(data: WeeklyDietData, profile: FamilyProfile): string {
        const parts: string[] = [];
        if (profile.isControlBp()) {
            if (data.highSodiumDays >= 3) {
                parts.push(`本周有${data.highSodiumDays}天高盐饮食偏多，控压需注意`);
            }
            else {
                parts.push('本周高盐饮食控制尚可');
            }
        }
        if (profile.isControlSugar()) {
            if (data.highSugarDays >= 3) {
                parts.push(`本周有${data.highSugarDays}天高糖饮食偏多，控糖需注意`);
            }
            else {
                parts.push('本周高糖饮食控制尚可');
            }
        }
        if (profile.isChild()) {
            if (data.sweetNearMealCount > 0) {
                parts.push(`本周甜食靠近正餐${data.sweetNearMealCount}次`);
            }
            if (data.childSnackOverLimit > 0) {
                parts.push(`零食超标${data.childSnackOverLimit}次`);
            }
        }
        if (data.lateNightSnackCount >= 2) {
            parts.push(`夜宵${data.lateNightSnackCount}次，建议减少`);
        }
        if (data.heavyFlavorCount >= 2) {
            parts.push(`重口味${data.heavyFlavorCount}次，注意搭配清淡`);
        }
        return parts.length > 0 ? parts.join('；') + '。' : '本周饮食整体均衡，继续保持。';
    }
    private generateHighlights(data: WeeklyDietData, profile: FamilyProfile): string[] {
        const highlights: string[] = [];
        if (data.highSodiumDays >= 3) {
            highlights.push(`高盐饮食${data.highSodiumDays}天，主要来自调味品、加工肉和方便食品`);
        }
        if (data.highSugarDays >= 3) {
            highlights.push(`高糖饮食${data.highSugarDays}天，注意含糖饮料和甜食`);
        }
        if (data.highFatDays >= 3) {
            highlights.push(`高脂饮食${data.highFatDays}天，注意油炸和烘焙食品`);
        }
        if (data.sweetNearMealCount > 0 && profile.isChild()) {
            highlights.push(`甜食靠近正餐${data.sweetNearMealCount}次，可能影响孩子正餐食欲`);
        }
        if (data.lateNightSnackCount > 0) {
            highlights.push(`夜宵${data.lateNightSnackCount}次，影响睡眠和次日饮食节奏`);
        }
        if (data.heavyFlavorCount > 0) {
            highlights.push(`重口味饮食${data.heavyFlavorCount}次（烧烤/火锅/卤味等）`);
        }
        return highlights;
    }
    private generateSuggestions(data: WeeklyDietData, profile: FamilyProfile): string[] {
        const suggestions: string[] = [];
        if (profile.isControlBp() && data.highSodiumDays >= 2) {
            suggestions.push('下周减少高盐调味品和加工肉，烹饪时少放盐、酱油和蚝油');
        }
        if (profile.isControlSugar() && data.highSugarDays >= 2) {
            suggestions.push('下周减少含糖饮料和甜食，选择低糖或无糖替代');
        }
        if (profile.isChild() && data.childSnackOverLimit >= 2) {
            suggestions.push('下周控制孩子零食次数，正餐前1-2小时不安排甜食');
        }
        if (data.lateNightSnackCount >= 2) {
            suggestions.push('下周避免连续夜宵，晚餐吃饱可减少夜宵冲动');
        }
        if (data.heavyFlavorCount >= 2) {
            suggestions.push('重口味后下一餐注意清淡搭配，增加蔬菜和水分');
        }
        // 正向建议
        if (suggestions.length === 0) {
            suggestions.push('本周饮食整体不错，继续保持均衡搭配');
        }
        suggestions.push('每天保证蔬菜、优质蛋白和适量主食');
        return suggestions;
    }
    private generatePurchaseAdvice(data: WeeklyDietData, profile: FamilyProfile): PurchaseAdvice {
        const advice = new PurchaseAdvice();
        if (data.highSodiumDays >= 2) {
            advice.buyLess.push('高盐调味品、方便面、卤味、加工肉');
            advice.buyMore.push('低盐调味品、新鲜蔬菜、清淡蛋白');
        }
        if (data.highSugarDays >= 2) {
            advice.buyLess.push('含糖饮料、甜食、高糖零食');
            advice.buyMore.push('原味酸奶、水果、坚果');
        }
        if (data.highFatDays >= 2) {
            advice.buyLess.push('油炸食品、高脂烘焙');
            advice.buyMore.push('蒸煮类蛋白、全谷物、蔬菜');
        }
        if (profile.isChild() && data.childSnackOverLimit >= 1) {
            advice.buyLess.push('高糖儿童零食');
            advice.buyMore.push('低糖酸奶、水果、原味坚果、水煮蛋');
        }
        // 默认正向建议
        if (advice.buyMore.length === 0) {
            advice.buyMore.push('蔬菜、水果、优质蛋白、全谷物');
        }
        return advice;
    }
}

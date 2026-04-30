if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ShareCard_Params {
    foodName?: string;
    recommendations?: Recommendation[];
    members?: FamilyProfile[];
}
import { getLevelColorValue } from "@bundle:com.familyfood.helper/entry/ets/model/Recommendation";
import type { Recommendation } from "@bundle:com.familyfood.helper/entry/ets/model/Recommendation";
import { FamilyProfile } from "@bundle:com.familyfood.helper/entry/ets/model/FamilyProfile";
import { RecommendationLevel } from "@bundle:com.familyfood.helper/entry/ets/model/FoodAdapterTypes";
import type { FoodRecommendation } from "@bundle:com.familyfood.helper/entry/ets/model/FoodAdapterTypes";
// ===== 分享卡片数据 =====
export interface ShareCardData {
    /** 标题，如"给全家人查了这款鸡爪" */
    title: string;
    /** 各成员摘要，如"爸爸: 今天谨慎，最多25g" */
    memberSummaries: string[];
    /** 关键建议，如"钠偏高，晚上别再吃卤味了" */
    keyAdvice: string;
    /** App名称 */
    appName: string;
    /** 二维码占位 */
    qrPlaceholder: string;
}
// ===== 分享文案模板 =====
export class ShareCardGenerator {
    /**
     * 生成分享卡片数据
     * @param foodName 食品名称
     * @param recommendations 各成员适配建议
     * @returns ShareCardData
     */
    static generateShareCard(foodName: string, recommendations: FoodRecommendation[]): ShareCardData {
        const memberSummaries: string[] = [];
        let keyAdvice = '';
        let worstLevel: string = 'GREEN';
        for (const rec of recommendations) {
            const levelText = rec.levelText;
            const amountText = rec.maxIntake_g > 0 ? `最多${rec.maxIntake_g}g` : '建议避免';
            memberSummaries.push(`${rec.memberName}: ${levelText}（${amountText}）`);
            if (rec.level === RecommendationLevel.RED)
                worstLevel = 'RED';
            else if (rec.level === RecommendationLevel.ORANGE && worstLevel !== 'RED')
                worstLevel = 'ORANGE';
            else if (rec.level === RecommendationLevel.YELLOW && worstLevel === 'GREEN')
                worstLevel = 'YELLOW';
            if (rec.reason.length > 0 && keyAdvice.length === 0) {
                keyAdvice = rec.reason;
            }
        }
        if (keyAdvice.length === 0) {
            if (worstLevel === 'RED')
                keyAdvice = '这款食品对部分成员不太友好，建议谨慎选择';
            else if (worstLevel === 'ORANGE')
                keyAdvice = '部分成员需要注意食用量，适量就好';
            else
                keyAdvice = '这款食品全家都适合，放心食用吧';
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
     * "妈，这款XX爸最多Xg，你可以Xg，孩子不建议"
     */
    static generateFamilyGroupText(foodName: string, recommendations: FoodRecommendation[]): string {
        const parts: string[] = [`妈，这款${foodName}`];
        for (const rec of recommendations) {
            if (rec.level === RecommendationLevel.RED) {
                parts.push(`${rec.memberName}不建议`);
            }
            else if (rec.maxIntake_g > 0) {
                parts.push(`${rec.memberName}最多${rec.maxIntake_g}g`);
            }
            else {
                parts.push(`${rec.memberName}可以适量`);
            }
        }
        return parts.join('，');
    }
    /**
     * 生成朋友圈版分享文案
     * "扫了一下XX，发现全家人建议居然不一样…"
     */
    static generateMomentsText(foodName: string, recommendations: FoodRecommendation[]): string {
        const diffs = recommendations.filter(r => r.level === RecommendationLevel.GREEN).length;
        const total = recommendations.length;
        let line = `扫了一下${foodName}，发现全家人建议居然不一样…`;
        if (diffs < total) {
            line += `\n只有${diffs}位成员可以放心吃，其他成员要注意啦`;
        }
        else {
            line += `\n全家都能放心吃，太棒了！`;
        }
        return line;
    }
    /**
     * 生成实用版分享文案
     * "刚扫了XX，钠有点高，今天尝一点就好，晚上别再吃咸的了"
     */
    static generatePracticalText(foodName: string, recommendations: FoodRecommendation[]): string {
        let keyIssue = '';
        for (const rec of recommendations) {
            if (rec.reason.includes('钠')) {
                keyIssue = '钠有点高';
                break;
            }
            else if (rec.reason.includes('糖')) {
                keyIssue = '糖有点多';
                break;
            }
            else if (rec.reason.includes('脂肪') || rec.reason.includes('油')) {
                keyIssue = '脂肪偏高';
                break;
            }
        }
        if (keyIssue.length === 0)
            keyIssue = '整体还行';
        const worst = recommendations.reduce((prev, curr) => {
            const order = [RecommendationLevel.GREEN, RecommendationLevel.YELLOW, RecommendationLevel.ORANGE, RecommendationLevel.RED];
            return order.indexOf(curr.level) > order.indexOf(prev.level) ? curr : prev;
        }, recommendations[0]);
        const amountText = worst.maxIntake_g > 0 ? `今天尝${worst.maxIntake_g}g就好` : '少量尝尝就好';
        return `刚扫了${foodName}，${keyIssue}，${amountText}，晚上别再吃咸的了～`;
    }
}
export class ShareCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__foodName = new SynchedPropertySimpleOneWayPU(params.foodName, this, "foodName");
        this.__recommendations = new SynchedPropertyObjectOneWayPU(params.recommendations, this, "recommendations");
        this.__members = new SynchedPropertyObjectOneWayPU(params.members, this, "members");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ShareCard_Params) {
        if (params.foodName === undefined) {
            this.__foodName.set('');
        }
        if (params.recommendations === undefined) {
            this.__recommendations.set([]);
        }
        if (params.members === undefined) {
            this.__members.set([]);
        }
    }
    updateStateVars(params: ShareCard_Params) {
        this.__foodName.reset(params.foodName);
        this.__recommendations.reset(params.recommendations);
        this.__members.reset(params.members);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__foodName.purgeDependencyOnElmtId(rmElmtId);
        this.__recommendations.purgeDependencyOnElmtId(rmElmtId);
        this.__members.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__foodName.aboutToBeDeleted();
        this.__recommendations.aboutToBeDeleted();
        this.__members.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __foodName: SynchedPropertySimpleOneWayPU<string>;
    get foodName() {
        return this.__foodName.get();
    }
    set foodName(newValue: string) {
        this.__foodName.set(newValue);
    }
    private __recommendations: SynchedPropertySimpleOneWayPU<Recommendation[]>;
    get recommendations() {
        return this.__recommendations.get();
    }
    set recommendations(newValue: Recommendation[]) {
        this.__recommendations.set(newValue);
    }
    private __members: SynchedPropertySimpleOneWayPU<FamilyProfile[]>;
    get members() {
        return this.__members.get();
    }
    set members(newValue: FamilyProfile[]) {
        this.__members.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.shadow({ radius: 8, color: '#1A000000', offsetY: 2 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Center);
            Column.padding({ top: 20, bottom: 12 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('食品适配助手');
            Text.fontSize(11);
            Text.fontColor('#9E9E9E');
            Text.margin({ bottom: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.foodName);
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#212121');
            Text.margin({ bottom: 16 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.width('80%');
            Divider.color('#E0E0E0');
            Divider.margin({ bottom: 12 });
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding({ left: 24, right: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const rec = _item;
                this.ShareMemberRow.bind(this)(rec, this.members[index] || new FamilyProfile());
            };
            this.forEachUpdateFunction(elmtId, this.recommendations, forEachItemGenFunction, (rec: Recommendation) => rec.memberId, true, false);
        }, ForEach);
        ForEach.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Center);
            Column.padding({ top: 8, bottom: 20 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.generateSummary());
            Text.fontSize(11);
            Text.fontColor('#9E9E9E');
            Text.margin({ top: 12, bottom: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('扫码查食品，全家更安心');
            Text.fontSize(11);
            Text.fontColor('#1976D2');
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    ShareMemberRow(rec: Recommendation, member: FamilyProfile, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.margin({ bottom: 8 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.getMemberEmoji(member));
            Text.fontSize(16);
            Text.margin({ right: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(member.nickname);
            Text.fontSize(14);
            Text.width(36);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(rec.level);
            Text.fontSize(13);
            Text.fontColor('#FFFFFF');
            Text.padding({ left: 10, right: 10, top: 3, bottom: 3 });
            Text.borderRadius(10);
            Text.backgroundColor(getLevelColorValue(rec.levelColor));
            Text.margin({ left: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (rec.maxAmount > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`最多${rec.maxAmount}g`);
                        Text.fontSize(13);
                        Text.fontColor('#212121');
                        Text.margin({ left: 10 });
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Row.pop();
    }
    private getMemberEmoji(member: FamilyProfile): string {
        if (member.nickname === '爸爸')
            return '👨';
        if (member.nickname === '妈妈')
            return '👩';
        if (member.nickname === '孩子')
            return '👶';
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
    rerender() {
        this.updateDirtyElements();
    }
}

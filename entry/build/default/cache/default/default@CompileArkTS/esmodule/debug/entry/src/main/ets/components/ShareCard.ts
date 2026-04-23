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
            // 卡片头部
            Column.create();
            // 卡片头部
            Column.width('100%');
            // 卡片头部
            Column.alignItems(HorizontalAlign.Center);
            // 卡片头部
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
        // 卡片头部
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 分隔线
            Divider.create();
            // 分隔线
            Divider.width('80%');
            // 分隔线
            Divider.color('#E0E0E0');
            // 分隔线
            Divider.margin({ bottom: 12 });
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 家庭成员结论
            Column.create();
            // 家庭成员结论
            Column.width('100%');
            // 家庭成员结论
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
        // 家庭成员结论
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 卡片底部
            Column.create();
            // 卡片底部
            Column.width('100%');
            // 卡片底部
            Column.alignItems(HorizontalAlign.Center);
            // 卡片底部
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
        // 卡片底部
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

if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface FamilyCompareView_Params {
    recommendations?: Recommendation[];
    members?: FamilyProfile[];
}
import { getLevelColorValue } from "@bundle:com.familyfood.helper/entry/ets/model/Recommendation";
import type { Recommendation } from "@bundle:com.familyfood.helper/entry/ets/model/Recommendation";
import { FamilyProfile } from "@bundle:com.familyfood.helper/entry/ets/model/FamilyProfile";
export class FamilyCompareView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__recommendations = new SynchedPropertyObjectOneWayPU(params.recommendations, this, "recommendations");
        this.__members = new SynchedPropertyObjectOneWayPU(params.members, this, "members");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: FamilyCompareView_Params) {
        if (params.recommendations === undefined) {
            this.__recommendations.set([]);
        }
        if (params.members === undefined) {
            this.__members.set([]);
        }
    }
    updateStateVars(params: FamilyCompareView_Params) {
        this.__recommendations.reset(params.recommendations);
        this.__members.reset(params.members);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__recommendations.purgeDependencyOnElmtId(rmElmtId);
        this.__members.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__recommendations.aboutToBeDeleted();
        this.__members.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
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
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(12);
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('一家人不同结论');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor('#212121');
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 横向对比卡片
            Scroll.create();
            // 横向对比卡片
            Scroll.scrollable(ScrollDirection.Horizontal);
            // 横向对比卡片
            Scroll.width('100%');
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const rec = _item;
                this.MemberCompareCard.bind(this)(rec, this.members[index] || new FamilyProfile());
            };
            this.forEachUpdateFunction(elmtId, this.recommendations, forEachItemGenFunction, (rec: Recommendation) => rec.memberId, true, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        // 横向对比卡片
        Scroll.pop();
        Column.pop();
    }
    MemberCompareCard(rec: Recommendation, member: FamilyProfile, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width(90);
            Column.padding({ top: 12, bottom: 12 });
            Column.margin({ right: 8 });
            Column.borderRadius(12);
            Column.backgroundColor('#F5F5F5');
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 成员emoji
            Text.create(this.getMemberEmoji(member));
            // 成员emoji
            Text.fontSize(28);
            // 成员emoji
            Text.margin({ bottom: 4 });
        }, Text);
        // 成员emoji
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 昵称
            Text.create(member.nickname);
            // 昵称
            Text.fontSize(13);
            // 昵称
            Text.fontColor('#212121');
            // 昵称
            Text.margin({ bottom: 6 });
        }, Text);
        // 昵称
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 等级标识
            Text.create(rec.level);
            // 等级标识
            Text.fontSize(12);
            // 等级标识
            Text.fontColor('#FFFFFF');
            // 等级标识
            Text.padding({ left: 8, right: 8, top: 3, bottom: 3 });
            // 等级标识
            Text.borderRadius(10);
            // 等级标识
            Text.backgroundColor(getLevelColorValue(rec.levelColor));
            // 等级标识
            Text.margin({ bottom: 6 });
        }, Text);
        // 等级标识
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 可吃量
            if (rec.maxAmount > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${rec.maxAmount}g`);
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor('#212121');
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('避免');
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor('#F44336');
                    }, Text);
                    Text.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 第一条原因
            if (rec.reasons.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(rec.reasons[0]);
                        Text.fontSize(10);
                        Text.fontColor('#757575');
                        Text.maxLines(2);
                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                        Text.margin({ top: 4 });
                        Text.constraintSize({ maxWidth: 80 });
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
        Column.pop();
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
    rerender() {
        this.updateDirtyElements();
    }
}

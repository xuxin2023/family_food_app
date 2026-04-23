if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface BalanceAdviceCard_Params {
    balance?: MealBalance;
}
import { MealBalance } from "@bundle:com.familyfood.helper/entry/ets/model/MealBalance";
import type { RiskTag } from "@bundle:com.familyfood.helper/entry/ets/model/MealBalance";
export class BalanceAdviceCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__balance = new SynchedPropertyObjectOneWayPU(params.balance, this, "balance");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: BalanceAdviceCard_Params) {
        if (params.balance === undefined) {
            this.__balance.set(new MealBalance());
        }
    }
    updateStateVars(params: BalanceAdviceCard_Params) {
        this.__balance.reset(params.balance);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__balance.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__balance.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __balance: SynchedPropertySimpleOneWayPU<MealBalance>;
    get balance() {
        return this.__balance.get();
    }
    set balance(newValue: MealBalance) {
        this.__balance.set(newValue);
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
            // 标题
            Row.create();
            // 标题
            Row.width('100%');
            // 标题
            Row.margin({ bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('🍽 美食平衡建议');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.balance.scenario);
            Text.fontSize(12);
            Text.fontColor('#757575');
            Text.padding({ left: 8, right: 8, top: 3, bottom: 3 });
            Text.borderRadius(10);
            Text.backgroundColor('#F5F5F5');
        }, Text);
        Text.pop();
        // 标题
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 本餐分析 - 风险标签
            Text.create('本餐偏高：');
            // 本餐分析 - 风险标签
            Text.fontSize(13);
            // 本餐分析 - 风险标签
            Text.fontColor('#757575');
            // 本餐分析 - 风险标签
            Text.margin({ bottom: 4 });
        }, Text);
        // 本餐分析 - 风险标签
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.margin({ bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const tag = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(tag);
                    Text.fontSize(12);
                    Text.fontColor('#FFFFFF');
                    Text.padding({ left: 8, right: 8, top: 3, bottom: 3 });
                    Text.borderRadius(10);
                    Text.backgroundColor('#FF5722');
                    Text.margin({ right: 6, bottom: 4 });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.balance.riskTags, forEachItemGenFunction, (tag: RiskTag, index: number) => `${index}`, false, true);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 下一餐建议
            Row.create();
            // 下一餐建议
            Row.margin({ bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('💡');
            Text.fontSize(14);
            Text.margin({ right: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('下一餐建议');
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.margin({ bottom: 2 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.balance.nextMealAdvice);
            Text.fontSize(14);
            Text.fontColor('#212121');
        }, Text);
        Text.pop();
        Column.pop();
        // 下一餐建议
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 不再叠加
            if (this.balance.avoidStacking.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.margin({ bottom: 12 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🚫');
                        Text.fontSize(14);
                        Text.margin({ right: 6 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('今天不再叠加');
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.margin({ bottom: 2 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.balance.avoidStacking.join('、'));
                        Text.fontSize(14);
                        Text.fontColor('#FF5722');
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                });
            }
            // 补水提醒
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 补水提醒
            if (this.balance.hydrationReminder) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.margin({ bottom: 8 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('💧');
                        Text.fontSize(16);
                        Text.margin({ right: 6 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('注意补水，避免用含糖饮料代替水');
                        Text.fontSize(14);
                        Text.fontColor('#1976D2');
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
            // 成员特定建议
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 成员特定建议
            if (this.balance.memberSpecificAdvice.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Divider.create();
                        Divider.margin({ bottom: 8 });
                    }, Divider);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('针对您的建议：');
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.margin({ bottom: 4 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.balance.memberSpecificAdvice);
                        Text.fontSize(14);
                        Text.fontColor('#212121');
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
    rerender() {
        this.updateDirtyElements();
    }
}

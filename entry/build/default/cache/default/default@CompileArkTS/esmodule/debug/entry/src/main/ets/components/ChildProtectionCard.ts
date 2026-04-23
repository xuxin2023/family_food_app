if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ChildProtectionCard_Params {
    protection?: ChildProtection;
}
import { ChildProtection } from "@bundle:com.familyfood.helper/entry/ets/model/ChildProtection";
export class ChildProtectionCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__protection = new SynchedPropertyObjectOneWayPU(params.protection, this, "protection");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ChildProtectionCard_Params) {
        if (params.protection === undefined) {
            this.__protection.set(new ChildProtection());
        }
    }
    updateStateVars(params: ChildProtectionCard_Params) {
        this.__protection.reset(params.protection);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__protection.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__protection.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __protection: SynchedPropertySimpleOneWayPU<ChildProtection>;
    get protection() {
        return this.__protection.get();
    }
    set protection(newValue: ChildProtection) {
        this.__protection.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFF8E1');
            Column.borderRadius(12);
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 标题
            Row.create();
            // 标题
            Row.width('100%');
            // 标题
            Row.margin({ bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('👶 儿童保护提醒');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        // 标题
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 正餐保护
            if (this.protection.mealProtection.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.margin({ bottom: 8 });
                        Row.alignItems(VerticalAlign.Top);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🍽');
                        Text.fontSize(16);
                        Text.margin({ right: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('正餐保护');
                        Text.fontSize(12);
                        Text.fontColor('#FF9800');
                        Text.margin({ bottom: 2 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.protection.mealProtection);
                        Text.fontSize(13);
                        Text.fontColor('#212121');
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                });
            }
            // 睡前保护
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 睡前保护
            if (this.protection.bedtimeProtection.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.margin({ bottom: 8 });
                        Row.alignItems(VerticalAlign.Top);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🌙');
                        Text.fontSize(16);
                        Text.margin({ right: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('睡前保护');
                        Text.fontSize(12);
                        Text.fontColor('#9C27B0');
                        Text.margin({ bottom: 2 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.protection.bedtimeProtection);
                        Text.fontSize(13);
                        Text.fontColor('#212121');
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                });
            }
            // 口味保护
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 口味保护
            if (this.protection.tasteProtection.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.margin({ bottom: 8 });
                        Row.alignItems(VerticalAlign.Top);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('👅');
                        Text.fontSize(16);
                        Text.margin({ right: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('口味保护');
                        Text.fontSize(12);
                        Text.fontColor('#4CAF50');
                        Text.margin({ bottom: 2 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.protection.tasteProtection);
                        Text.fontSize(13);
                        Text.fontColor('#212121');
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                });
            }
            // 抵消提醒
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 抵消提醒
            if (this.protection.counteractReminder) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('⚠');
                        Text.fontSize(16);
                        Text.margin({ right: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('不建议用"不吃饭"来抵消甜食');
                        Text.fontSize(13);
                        Text.fontColor('#FF5722');
                        Text.fontWeight(FontWeight.Medium);
                        Text.layoutWeight(1);
                    }, Text);
                    Text.pop();
                    Row.pop();
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

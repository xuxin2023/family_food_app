if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface NutritionRadarChart_Params {
    dimensions?: NutritionDimension[];
}
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from "@bundle:com.familyfood.helper/entry/ets/constants/AppTheme";
export interface NutritionDimension {
    label: string;
    value: number;
    target: number;
    unit: string;
    color: string;
}
export class NutritionRadarChart extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__dimensions = new SynchedPropertyObjectOneWayPU(params.dimensions, this, "dimensions");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: NutritionRadarChart_Params) {
        if (params.dimensions === undefined) {
            this.__dimensions.set([]);
        }
    }
    updateStateVars(params: NutritionRadarChart_Params) {
        this.__dimensions.reset(params.dimensions);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__dimensions.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__dimensions.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __dimensions: SynchedPropertySimpleOneWayPU<NutritionDimension[]>;
    get dimensions() {
        return this.__dimensions.get();
    }
    set dimensions(newValue: NutritionDimension[]) {
        this.__dimensions.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(SPACING.LG);
            Column.backgroundColor(COLORS.BG_CARD);
            Column.borderRadius(RADIUS.LG);
            Column.shadow({ radius: 6, color: COLORS.SHADOW_LIGHT, offsetY: 2 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.dimensions.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('📊 营养均衡分析');
                        Text.fontSize(FONT_SIZE.SUBTITLE);
                        Text.fontWeight(FONT_WEIGHT.BOLD);
                        Text.fontColor(COLORS.TEXT_PRIMARY);
                        Text.width('100%');
                        Text.margin({ bottom: SPACING.MD });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 各维度进度条
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const dim = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Column.create();
                                Column.width('100%');
                            }, Column);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.width('100%');
                                Row.margin({ bottom: SPACING.XS });
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(dim.label);
                                Text.fontSize(FONT_SIZE.BODY);
                                Text.fontColor(COLORS.TEXT_PRIMARY);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Blank.create();
                            }, Blank);
                            Blank.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`${dim.value}${dim.unit}`);
                                Text.fontSize(FONT_SIZE.SMALL);
                                Text.fontColor(dim.color);
                                Text.fontWeight(FONT_WEIGHT.MEDIUM);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(` / ${dim.target}${dim.unit}`);
                                Text.fontSize(FONT_SIZE.TINY);
                                Text.fontColor(COLORS.TEXT_HINT);
                            }, Text);
                            Text.pop();
                            Row.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                // 进度条
                                Row.create();
                                // 进度条
                                Row.width('100%');
                                // 进度条
                                Row.height(8);
                                // 进度条
                                Row.backgroundColor(COLORS.BG_SECTION);
                                // 进度条
                                Row.borderRadius(RADIUS.SM);
                                // 进度条
                                Row.margin({ bottom: SPACING.SM });
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.width(`${Math.min((dim.value / dim.target) * 100, 100)}%`);
                                Row.height(8);
                                Row.backgroundColor(dim.color);
                                Row.borderRadius(RADIUS.SM);
                            }, Row);
                            Row.pop();
                            // 进度条
                            Row.pop();
                            Column.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.dimensions, forEachItemGenFunction, (dim: NutritionDimension, index: number) => `dim_${index}`, false, true);
                    }, ForEach);
                    // 各维度进度条
                    ForEach.pop();
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

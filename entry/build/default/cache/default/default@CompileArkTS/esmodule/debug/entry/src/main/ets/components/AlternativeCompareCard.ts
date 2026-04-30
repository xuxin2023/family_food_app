if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface AlternativeCompareCard_Params {
    currentItem?: AlternativeCompareItem | null;
    alternatives?: AlternativeCompareItem[];
}
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from "@bundle:com.familyfood.helper/entry/ets/constants/AppTheme";
import type { YukaGrade } from './YukaScoreCard';
// 替代品对比项
export interface AlternativeCompareItem {
    name: string;
    brand: string;
    score: number;
    grade: YukaGrade;
    gradeLabel: string;
    gradeColor: string;
    improvements: string[];
    isCurrent: boolean;
}
export class AlternativeCompareCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__currentItem = new SynchedPropertyObjectOneWayPU(params.currentItem, this, "currentItem");
        this.__alternatives = new SynchedPropertyObjectOneWayPU(params.alternatives, this, "alternatives");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: AlternativeCompareCard_Params) {
        if (params.currentItem === undefined) {
            this.__currentItem.set(null);
        }
        if (params.alternatives === undefined) {
            this.__alternatives.set([]);
        }
    }
    updateStateVars(params: AlternativeCompareCard_Params) {
        this.__currentItem.reset(params.currentItem);
        this.__alternatives.reset(params.alternatives);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__currentItem.purgeDependencyOnElmtId(rmElmtId);
        this.__alternatives.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__currentItem.aboutToBeDeleted();
        this.__alternatives.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __currentItem: SynchedPropertySimpleOneWayPU<AlternativeCompareItem | null>;
    get currentItem() {
        return this.__currentItem.get();
    }
    set currentItem(newValue: AlternativeCompareItem | null) {
        this.__currentItem.set(newValue);
    }
    private __alternatives: SynchedPropertySimpleOneWayPU<AlternativeCompareItem[]>;
    get alternatives() {
        return this.__alternatives.get();
    }
    set alternatives(newValue: AlternativeCompareItem[]) {
        this.__alternatives.set(newValue);
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
            if (this.currentItem !== null || this.alternatives.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🔄 更健康的选择');
                        Text.fontSize(FONT_SIZE.SUBTITLE);
                        Text.fontWeight(FONT_WEIGHT.BOLD);
                        Text.fontColor(COLORS.TEXT_PRIMARY);
                        Text.width('100%');
                        Text.margin({ bottom: SPACING.MD });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 当前食品
                        if (this.currentItem !== null) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.buildCompareItem.bind(this)(ObservedObject.GetRawObject(this.currentItem), true);
                            });
                        }
                        // 替代品
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 替代品
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const alt = _item;
                            this.buildCompareItem.bind(this)(alt, false);
                        };
                        this.forEachUpdateFunction(elmtId, this.alternatives, forEachItemGenFunction, (alt: AlternativeCompareItem, index: number) => `alt_${index}`, false, true);
                    }, ForEach);
                    // 替代品
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
    buildCompareItem(item: AlternativeCompareItem, isCurrent: boolean, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding(SPACING.MD);
            Row.backgroundColor(isCurrent ? COLORS.BG_SECTION : COLORS.BG_CARD);
            Row.borderRadius(RADIUS.MD);
            Row.margin({ bottom: SPACING.SM });
            Row.border({
                width: isCurrent ? 1 : 0,
                color: COLORS.BORDER
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 评分圆圈
            Column.create();
            // 评分圆圈
            Column.width(56);
            // 评分圆圈
            Column.height(56);
            // 评分圆圈
            Column.borderRadius(RADIUS.FULL);
            // 评分圆圈
            Column.backgroundColor(item.gradeColor);
            // 评分圆圈
            Column.justifyContent(FlexAlign.Center);
            // 评分圆圈
            Column.alignItems(HorizontalAlign.Center);
            // 评分圆圈
            Column.margin({ right: SPACING.MD });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${item.score}`);
            Text.fontSize(FONT_SIZE.TITLE);
            Text.fontWeight(FONT_WEIGHT.BOLD);
            Text.fontColor(COLORS.TEXT_WHITE);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(item.gradeLabel);
            Text.fontSize(FONT_SIZE.TINY);
            Text.fontColor(COLORS.TEXT_WHITE);
            Text.margin({ top: -2 });
        }, Text);
        Text.pop();
        // 评分圆圈
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 食品信息
            Column.create();
            // 食品信息
            Column.alignItems(HorizontalAlign.Start);
            // 食品信息
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(item.name);
            Text.fontSize(FONT_SIZE.BODY_LG);
            Text.fontWeight(FONT_WEIGHT.MEDIUM);
            Text.fontColor(COLORS.TEXT_PRIMARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (item.brand.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(item.brand);
                        Text.fontSize(FONT_SIZE.SMALL);
                        Text.fontColor(COLORS.TEXT_HINT);
                        Text.margin({ top: SPACING.XS });
                    }, Text);
                    Text.pop();
                });
            }
            // 改进点
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 改进点
            if (!isCurrent && item.improvements.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Flex.create({ wrap: FlexWrap.Wrap });
                        Flex.margin({ top: SPACING.XS });
                    }, Flex);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const imp = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`✓ ${imp}`);
                                Text.fontSize(FONT_SIZE.TINY);
                                Text.fontColor(COLORS.SUCCESS);
                                Text.padding({ left: SPACING.XS, right: SPACING.XS, top: 2, bottom: 2 });
                                Text.backgroundColor(COLORS.ACCENT_GREEN_ULTRA_LIGHT);
                                Text.borderRadius(RADIUS.XS);
                                Text.margin({ right: SPACING.XS, top: SPACING.XS });
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, item.improvements, forEachItemGenFunction, (imp: string, idx: number) => `imp_${idx}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                    Flex.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 食品信息
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 当前标记
            if (isCurrent) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('当前');
                        Text.fontSize(FONT_SIZE.TINY);
                        Text.fontColor(COLORS.TEXT_HINT);
                        Text.padding({ left: SPACING.SM, right: SPACING.SM, top: 2, bottom: 2 });
                        Text.backgroundColor(COLORS.BG_SECTION);
                        Text.borderRadius(RADIUS.XS);
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
    rerender() {
        this.updateDirtyElements();
    }
}

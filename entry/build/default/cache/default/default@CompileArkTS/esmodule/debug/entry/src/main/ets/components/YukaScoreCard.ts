if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface YukaScoreCard_Params {
    scoreResult?: YukaScoreResult | null;
    animateScore?: number;
}
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from "@bundle:com.familyfood.helper/entry/ets/constants/AppTheme";
// 评分等级
export enum YukaGrade {
    EXCELLENT = "EXCELLENT",
    GOOD = "GOOD",
    MEDIUM = "MEDIUM",
    POOR = "POOR"
}
// 评分结果
export interface YukaScoreResult {
    score: number;
    grade: YukaGrade;
    gradeLabel: string;
    gradeColor: string;
    gradeBgColor: string;
    positivePoints: YukaScorePoint[];
    negativePoints: YukaScorePoint[];
    summary: string;
}
// 评分明细项
export interface YukaScorePoint {
    label: string;
    detail: string;
    isPositive: boolean;
    severity?: string;
}
// 评分等级信息
export interface YukaGradeInfo {
    grade: YukaGrade;
    label: string;
    color: string;
    bgColor: string;
}
// 获取评分等级信息
export function getYukaGradeInfo(score: number): YukaGradeInfo {
    if (score >= 75) {
        return {
            grade: YukaGrade.EXCELLENT,
            label: '优秀',
            color: COLORS.SUCCESS,
            bgColor: COLORS.ACCENT_GREEN_LIGHT
        };
    }
    else if (score >= 50) {
        return {
            grade: YukaGrade.GOOD,
            label: '良好',
            color: COLORS.ACCENT_GREEN,
            bgColor: COLORS.ACCENT_GREEN_ULTRA_LIGHT
        };
    }
    else if (score >= 25) {
        return {
            grade: YukaGrade.MEDIUM,
            label: '中等',
            color: COLORS.WARNING,
            bgColor: COLORS.WARNING_LIGHT
        };
    }
    else {
        return {
            grade: YukaGrade.POOR,
            label: '差',
            color: COLORS.DANGER,
            bgColor: COLORS.DANGER_LIGHT
        };
    }
}
export class YukaScoreCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__scoreResult = new SynchedPropertyObjectOneWayPU(params.scoreResult, this, "scoreResult");
        this.__animateScore = new ObservedPropertySimplePU(0, this, "animateScore");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: YukaScoreCard_Params) {
        if (params.scoreResult === undefined) {
            this.__scoreResult.set(null);
        }
        if (params.animateScore !== undefined) {
            this.animateScore = params.animateScore;
        }
    }
    updateStateVars(params: YukaScoreCard_Params) {
        this.__scoreResult.reset(params.scoreResult);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__scoreResult.purgeDependencyOnElmtId(rmElmtId);
        this.__animateScore.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__scoreResult.aboutToBeDeleted();
        this.__animateScore.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __scoreResult: SynchedPropertySimpleOneWayPU<YukaScoreResult | null>;
    get scoreResult() {
        return this.__scoreResult.get();
    }
    set scoreResult(newValue: YukaScoreResult | null) {
        this.__scoreResult.set(newValue);
    }
    private __animateScore: ObservedPropertySimplePU<number>;
    get animateScore() {
        return this.__animateScore.get();
    }
    set animateScore(newValue: number) {
        this.__animateScore.set(newValue);
    }
    aboutToAppear() {
        if (this.scoreResult !== null) {
            this.animateScoreIn();
        }
    }
    animateScoreIn() {
        if (this.scoreResult === null) {
            return;
        }
        const target = this.scoreResult.score;
        const duration = 800;
        const interval = 16;
        const steps = duration / interval;
        let currentStep = 0;
        const timer = setInterval(() => {
            currentStep++;
            const progress = Math.min(currentStep / steps, 1);
            const eased = 1 - Math.pow(1 - progress, 3);
            this.animateScore = Math.round(eased * target);
            if (currentStep >= steps) {
                clearInterval(timer);
                this.animateScore = target;
            }
        }, interval);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.backgroundColor(COLORS.BG_CARD);
            Column.borderRadius(RADIUS.LG);
            Column.shadow({ radius: 8, color: COLORS.SHADOW_LIGHT, offsetY: 2 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.scoreResult !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 大数字评分区
                        Column.create();
                        // 大数字评分区
                        Column.width('100%');
                        // 大数字评分区
                        Column.padding(SPACING.XL);
                        // 大数字评分区
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${this.animateScore}`);
                        Text.fontSize(56);
                        Text.fontWeight(FONT_WEIGHT.BOLD);
                        Text.fontColor(this.scoreResult.gradeColor);
                        Text.lineHeight(60);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.scoreResult.gradeLabel);
                        Text.fontSize(FONT_SIZE.SUBTITLE);
                        Text.fontWeight(FONT_WEIGHT.MEDIUM);
                        Text.fontColor(COLORS.TEXT_WHITE);
                        Text.padding({ left: SPACING.LG, right: SPACING.LG, top: SPACING.XS, bottom: SPACING.XS });
                        Text.backgroundColor(this.scoreResult.gradeColor);
                        Text.borderRadius(RADIUS.FULL);
                        Text.margin({ top: SPACING.SM });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.scoreResult.summary);
                        Text.fontSize(FONT_SIZE.BODY);
                        Text.fontColor(COLORS.TEXT_SECONDARY);
                        Text.textAlign(TextAlign.Center);
                        Text.margin({ top: SPACING.MD });
                        Text.lineHeight(22);
                    }, Text);
                    Text.pop();
                    // 大数字评分区
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 成分明细
                        Column.create();
                        // 成分明细
                        Column.width('100%');
                        // 成分明细
                        Column.padding(SPACING.LG);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 正面成分
                        if (this.scoreResult.positivePoints.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.width('100%');
                                    Column.margin({ bottom: SPACING.MD });
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('✅ 正面成分');
                                    Text.fontSize(FONT_SIZE.BODY);
                                    Text.fontWeight(FONT_WEIGHT.MEDIUM);
                                    Text.fontColor(COLORS.SUCCESS);
                                    Text.width('100%');
                                    Text.margin({ bottom: SPACING.SM });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const point = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Row.create();
                                            Row.width('100%');
                                            Row.padding(SPACING.SM);
                                            Row.backgroundColor(COLORS.ACCENT_GREEN_ULTRA_LIGHT);
                                            Row.borderRadius(RADIUS.MD);
                                            Row.margin({ bottom: SPACING.XS });
                                        }, Row);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create('●');
                                            Text.fontSize(FONT_SIZE.TINY);
                                            Text.fontColor(COLORS.SUCCESS);
                                            Text.margin({ right: SPACING.SM });
                                        }, Text);
                                        Text.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Column.create();
                                            Column.alignItems(HorizontalAlign.Start);
                                            Column.layoutWeight(1);
                                        }, Column);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(point.label);
                                            Text.fontSize(FONT_SIZE.BODY);
                                            Text.fontWeight(FONT_WEIGHT.MEDIUM);
                                            Text.fontColor(COLORS.TEXT_PRIMARY);
                                        }, Text);
                                        Text.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(point.detail);
                                            Text.fontSize(FONT_SIZE.SMALL);
                                            Text.fontColor(COLORS.TEXT_HINT);
                                            Text.margin({ top: SPACING.XS });
                                        }, Text);
                                        Text.pop();
                                        Column.pop();
                                        Row.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.scoreResult.positivePoints, forEachItemGenFunction, (point: YukaScorePoint, index: number) => `positive_${index}`, false, true);
                                }, ForEach);
                                ForEach.pop();
                                Column.pop();
                            });
                        }
                        // 负面成分
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // 负面成分
                        if (this.scoreResult.negativePoints.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create();
                                    Column.width('100%');
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('⚠️ 需要关注');
                                    Text.fontSize(FONT_SIZE.BODY);
                                    Text.fontWeight(FONT_WEIGHT.MEDIUM);
                                    Text.fontColor(COLORS.WARNING);
                                    Text.width('100%');
                                    Text.margin({ bottom: SPACING.SM });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const point = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Row.create();
                                            Row.width('100%');
                                            Row.padding(SPACING.SM);
                                            Row.backgroundColor(this.getSeverityBgColor(point.severity));
                                            Row.borderRadius(RADIUS.MD);
                                            Row.margin({ bottom: SPACING.XS });
                                        }, Row);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create('●');
                                            Text.fontSize(FONT_SIZE.TINY);
                                            Text.fontColor(this.getSeverityColor(point.severity));
                                            Text.margin({ right: SPACING.SM });
                                        }, Text);
                                        Text.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Column.create();
                                            Column.alignItems(HorizontalAlign.Start);
                                            Column.layoutWeight(1);
                                        }, Column);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Row.create();
                                            Row.alignItems(VerticalAlign.Center);
                                        }, Row);
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(point.label);
                                            Text.fontSize(FONT_SIZE.BODY);
                                            Text.fontWeight(FONT_WEIGHT.MEDIUM);
                                            Text.fontColor(COLORS.TEXT_PRIMARY);
                                        }, Text);
                                        Text.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            If.create();
                                            if (point.severity === 'high') {
                                                this.ifElseBranchUpdateFunction(0, () => {
                                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                                        Text.create('高风险');
                                                        Text.fontSize(FONT_SIZE.TINY);
                                                        Text.fontColor(COLORS.TEXT_WHITE);
                                                        Text.backgroundColor(COLORS.DANGER);
                                                        Text.padding({ left: SPACING.XS, right: SPACING.XS, top: 2, bottom: 2 });
                                                        Text.borderRadius(RADIUS.XS);
                                                        Text.margin({ left: SPACING.SM });
                                                    }, Text);
                                                    Text.pop();
                                                });
                                            }
                                            else if (point.severity === 'medium') {
                                                this.ifElseBranchUpdateFunction(1, () => {
                                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                                        Text.create('中风险');
                                                        Text.fontSize(FONT_SIZE.TINY);
                                                        Text.fontColor(COLORS.TEXT_WHITE);
                                                        Text.backgroundColor(COLORS.WARNING);
                                                        Text.padding({ left: SPACING.XS, right: SPACING.XS, top: 2, bottom: 2 });
                                                        Text.borderRadius(RADIUS.XS);
                                                        Text.margin({ left: SPACING.SM });
                                                    }, Text);
                                                    Text.pop();
                                                });
                                            }
                                            else {
                                                this.ifElseBranchUpdateFunction(2, () => {
                                                });
                                            }
                                        }, If);
                                        If.pop();
                                        Row.pop();
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(point.detail);
                                            Text.fontSize(FONT_SIZE.SMALL);
                                            Text.fontColor(COLORS.TEXT_HINT);
                                            Text.margin({ top: SPACING.XS });
                                        }, Text);
                                        Text.pop();
                                        Column.pop();
                                        Row.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.scoreResult.negativePoints, forEachItemGenFunction, (point: YukaScorePoint, index: number) => `negative_${index}`, false, true);
                                }, ForEach);
                                ForEach.pop();
                                Column.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    // 成分明细
                    Column.pop();
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
    private getSeverityColor(severity?: string): string {
        if (severity === 'high') {
            return COLORS.DANGER;
        }
        else if (severity === 'medium') {
            return COLORS.WARNING;
        }
        return COLORS.TEXT_HINT;
    }
    private getSeverityBgColor(severity?: string): string {
        if (severity === 'high') {
            return COLORS.DANGER_LIGHT;
        }
        else if (severity === 'medium') {
            return COLORS.WARNING_LIGHT;
        }
        return COLORS.BG_SECTION;
    }
    rerender() {
        this.updateDirtyElements();
    }
}

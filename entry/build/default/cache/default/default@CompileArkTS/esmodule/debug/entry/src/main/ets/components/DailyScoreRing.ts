if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface DailyScoreRing_Params {
    scoreData?: DailyScoreData | null;
    animateProgress?: number;
}
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from "@bundle:com.familyfood.helper/entry/ets/constants/AppTheme";
export interface DailyScoreData {
    score: number;
    label: string;
    color: string;
    caloriePercent: number;
    proteinPercent: number;
    fatPercent: number;
    carbPercent: number;
    sodiumPercent: number;
    sugarPercent: number;
}
export class DailyScoreRing extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__scoreData = new SynchedPropertyObjectOneWayPU(params.scoreData, this, "scoreData");
        this.__animateProgress = new ObservedPropertySimplePU(0, this, "animateProgress");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: DailyScoreRing_Params) {
        if (params.scoreData === undefined) {
            this.__scoreData.set(null);
        }
        if (params.animateProgress !== undefined) {
            this.animateProgress = params.animateProgress;
        }
    }
    updateStateVars(params: DailyScoreRing_Params) {
        this.__scoreData.reset(params.scoreData);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__scoreData.purgeDependencyOnElmtId(rmElmtId);
        this.__animateProgress.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__scoreData.aboutToBeDeleted();
        this.__animateProgress.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __scoreData: SynchedPropertySimpleOneWayPU<DailyScoreData | null>;
    get scoreData() {
        return this.__scoreData.get();
    }
    set scoreData(newValue: DailyScoreData | null) {
        this.__scoreData.set(newValue);
    }
    private __animateProgress: ObservedPropertySimplePU<number>;
    get animateProgress() {
        return this.__animateProgress.get();
    }
    set animateProgress(newValue: number) {
        this.__animateProgress.set(newValue);
    }
    aboutToAppear() {
        if (this.scoreData !== null) {
            this.animateRing();
        }
    }
    animateRing() {
        const target = 1;
        const duration = 1000;
        const interval = 16;
        const steps = duration / interval;
        let currentStep = 0;
        const timer = setInterval(() => {
            currentStep++;
            const progress = Math.min(currentStep / steps, 1);
            const eased = 1 - Math.pow(1 - progress, 3);
            this.animateProgress = eased * target;
            if (currentStep >= steps) {
                clearInterval(timer);
                this.animateProgress = target;
            }
        }, interval);
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
            if (this.scoreData !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 环形进度
                        Stack.create();
                        // 环形进度
                        Stack.width(140);
                        // 环形进度
                        Stack.height(140);
                        // 环形进度
                        Stack.margin({ right: SPACING.LG });
                    }, Stack);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Circle.create();
                        Circle.width(140);
                        Circle.height(140);
                        Circle.fill(COLORS.BG_SECTION);
                        Circle.strokeWidth(10);
                        Circle.stroke(COLORS.BORDER);
                    }, Circle);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${this.scoreData.score}`);
                        Text.fontSize(36);
                        Text.fontWeight(FONT_WEIGHT.BOLD);
                        Text.fontColor(this.scoreData.color);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.scoreData.label);
                        Text.fontSize(FONT_SIZE.TINY);
                        Text.fontColor(this.scoreData.color);
                        Text.margin({ top: SPACING.XS });
                    }, Text);
                    Text.pop();
                    Column.pop();
                    // 环形进度
                    Stack.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 右侧进度条
                        Column.create();
                        // 右侧进度条
                        Column.alignItems(HorizontalAlign.Start);
                        // 右侧进度条
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('今日摄入');
                        Text.fontSize(FONT_SIZE.BODY);
                        Text.fontWeight(FONT_WEIGHT.MEDIUM);
                        Text.fontColor(COLORS.TEXT_PRIMARY);
                        Text.margin({ bottom: SPACING.SM });
                    }, Text);
                    Text.pop();
                    this.buildProgressBar.bind(this)('热量', this.scoreData.caloriePercent, COLORS.PRIMARY);
                    this.buildProgressBar.bind(this)('蛋白质', this.scoreData.proteinPercent, COLORS.ACCENT_BLUE);
                    this.buildProgressBar.bind(this)('脂肪', this.scoreData.fatPercent, COLORS.WARNING);
                    this.buildProgressBar.bind(this)('碳水', this.scoreData.carbPercent, COLORS.ACCENT_PURPLE);
                    this.buildProgressBar.bind(this)('钠', this.scoreData.sodiumPercent, COLORS.DANGER);
                    // 右侧进度条
                    Column.pop();
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
    buildProgressBar(label: string, percent: number, color: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.margin({ bottom: 2 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(FONT_SIZE.TINY);
            Text.fontColor(COLORS.TEXT_SECONDARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${Math.round(percent)}%`);
            Text.fontSize(FONT_SIZE.TINY);
            Text.fontColor(color);
            Text.fontWeight(FONT_WEIGHT.MEDIUM);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.height(4);
            Row.backgroundColor(COLORS.BG_SECTION);
            Row.borderRadius(RADIUS.SM);
            Row.margin({ bottom: SPACING.XS });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width(`${Math.min(percent, 100)}%`);
            Row.height(4);
            Row.backgroundColor(color);
            Row.borderRadius(RADIUS.SM);
        }, Row);
        Row.pop();
        Row.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}

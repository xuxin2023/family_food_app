if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface WeeklyReportPage_Params {
    reports?: WeeklyReport[];
    weekLabel?: string;
    appState?: AppState;
}
import router from "@ohos:router";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import type { FamilyProfile } from '../model/FamilyProfile';
import { MealScenario } from "@bundle:com.familyfood.helper/entry/ets/model/MealBalance";
import { WeeklyReportEngine } from "@bundle:com.familyfood.helper/entry/ets/engine/WeeklyReportEngine";
import type { WeeklyDietData, WeeklyReport } from "@bundle:com.familyfood.helper/entry/ets/engine/WeeklyReportEngine";
import type { ScanHistoryRecord } from '../repository/HistoryRepository';
import { DateUtil } from "@bundle:com.familyfood.helper/entry/ets/utils/DateUtil";
// 周范围
class WeekRange {
    startDate: string = '';
    endDate: string = '';
}
class WeeklyReportPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__reports = new ObservedPropertyObjectPU([], this, "reports");
        this.__weekLabel = new ObservedPropertySimplePU('', this, "weekLabel");
        this.appState = AppState.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: WeeklyReportPage_Params) {
        if (params.reports !== undefined) {
            this.reports = params.reports;
        }
        if (params.weekLabel !== undefined) {
            this.weekLabel = params.weekLabel;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
    }
    updateStateVars(params: WeeklyReportPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__reports.purgeDependencyOnElmtId(rmElmtId);
        this.__weekLabel.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__reports.aboutToBeDeleted();
        this.__weekLabel.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __reports: ObservedPropertyObjectPU<WeeklyReport[]>;
    get reports() {
        return this.__reports.get();
    }
    set reports(newValue: WeeklyReport[]) {
        this.__reports.set(newValue);
    }
    private __weekLabel: ObservedPropertySimplePU<string>;
    get weekLabel() {
        return this.__weekLabel.get();
    }
    set weekLabel(newValue: string) {
        this.__weekLabel.set(newValue);
    }
    private appState: AppState;
    async aboutToAppear() {
        const members = await this.appState.getAllMembers();
        const weekRange = this.getCurrentWeekRange();
        this.weekLabel = `${weekRange.startDate} ~ ${weekRange.endDate}`;
        const scanHistory = await this.appState.getRecentScanHistory(200);
        const reports: WeeklyReport[] = [];
        const engine = new WeeklyReportEngine();
        for (const member of members) {
            const data = await this.buildWeeklyData(member, weekRange.startDate, weekRange.endDate, scanHistory);
            reports.push(engine.generate(data, member));
        }
        this.reports = reports;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.backgroundColor('#FAFAFA');
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ left: 16, right: 16, top: 16, bottom: 16 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.fontSize(24);
            Text.fontColor('#1976D2');
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('家庭周报');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.weekLabel.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.weekLabel);
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.width('92%');
                        Text.margin({ bottom: 12 });
                        Text.textAlign(TextAlign.Start);
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
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.reports.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.height('70%');
                        Column.justifyContent(FlexAlign.Center);
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('本周还没有可展示的记录');
                        Text.fontSize(16);
                        Text.fontColor('#616161');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('先去扫码、查看报告或记录一餐，再回来查看周报');
                        Text.fontSize(12);
                        Text.fontColor('#9E9E9E');
                        Text.margin({ top: 8 });
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const report = _item;
                            this.MemberWeeklyCard.bind(this)(report);
                        };
                        this.forEachUpdateFunction(elmtId, this.reports, forEachItemGenFunction, (report: WeeklyReport) => report.memberId, false, false);
                    }, ForEach);
                    ForEach.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
        Scroll.pop();
    }
    MemberWeeklyCard(report: WeeklyReport, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 12 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(report.memberName);
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(report.summary);
            Text.fontSize(14);
            Text.fontColor('#212121');
            Text.margin({ bottom: 10 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (report.highlights.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('本周重点');
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.margin({ bottom: 6 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const item = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`• ${item}`);
                                Text.fontSize(12);
                                Text.fontColor('#616161');
                                Text.margin({ bottom: 4 });
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, report.highlights, forEachItemGenFunction, (item: string, index: number) => `${index}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (report.suggestions.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('下周建议');
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.margin({ top: 8, bottom: 6 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const item = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`• ${item}`);
                                Text.fontSize(12);
                                Text.fontColor('#616161');
                                Text.margin({ bottom: 4 });
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, report.suggestions, forEachItemGenFunction, (item: string, index: number) => `${index}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (report.buyLess.length > 0 || report.buyMore.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('采购建议');
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.margin({ top: 8, bottom: 6 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (report.buyLess.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(`少买：${report.buyLess.join('、')}`);
                                    Text.fontSize(12);
                                    Text.fontColor('#D32F2F');
                                    Text.margin({ bottom: 4 });
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
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (report.buyMore.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(`备一些：${report.buyMore.join('、')}`);
                                    Text.fontSize(12);
                                    Text.fontColor('#2E7D32');
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
    private getCurrentWeekRange(): WeekRange {
        const today = new Date();
        const day = today.getDay();
        const diffToMonday = day === 0 ? 6 : day - 1;
        const start = new Date(today);
        start.setHours(0, 0, 0, 0);
        start.setDate(today.getDate() - diffToMonday);
        const end = new Date(start);
        end.setDate(start.getDate() + 6);
        const range = new WeekRange();
        range.startDate = DateUtil.formatDate(start);
        range.endDate = DateUtil.formatDate(end);
        return range;
    }
    private async buildWeeklyData(member: FamilyProfile, startDate: string, endDate: string, scanHistory: ScanHistoryRecord[]): Promise<WeeklyDietData> {
        const records = await this.appState.getDietRecordsByDateRange(member.memberId, startDate, endDate);
        const highSodiumDays: Set<string> = new Set();
        const highSugarDays: Set<string> = new Set();
        const highFatDays: Set<string> = new Set();
        let sweetNearMealCount = 0;
        let lateNightSnackCount = 0;
        let heavyFlavorCount = 0;
        let childSnackOverLimit = 0;
        for (const record of records) {
            if (record.sodiumIntake >= 800) {
                highSodiumDays.add(record.date);
            }
            if (record.sugarIntake >= 15) {
                highSugarDays.add(record.date);
            }
            if (record.fatIntake >= 20) {
                highFatDays.add(record.date);
            }
            if (record.scenario === MealScenario.MILK_TEA || record.scenario === MealScenario.DESSERT || record.sugarIntake >= 15) {
                sweetNearMealCount++;
            }
            if (record.scenario === MealScenario.LATE_NIGHT) {
                lateNightSnackCount++;
            }
            if (record.scenario === MealScenario.BBQ ||
                record.scenario === MealScenario.HOTPOT ||
                record.scenario === MealScenario.LUWEI ||
                record.scenario === MealScenario.INSTANT_NOODLE ||
                record.scenario === MealScenario.FRIED_CHICKEN) {
                heavyFlavorCount++;
            }
            if (member.isChild() &&
                (record.scenario === MealScenario.MILK_TEA || record.scenario === MealScenario.DESSERT || record.sugarIntake >= 15)) {
                childSnackOverLimit++;
            }
        }
        const totalScans = scanHistory.filter(record => record.memberId === member.memberId && this.timestampInRange(record.scannedAt, startDate, endDate)).length;
        const data: WeeklyDietData = {
            memberId: member.memberId,
            weekStart: startDate,
            weekEnd: endDate,
            totalScans: totalScans,
            highSodiumDays: highSodiumDays.size,
            highSugarDays: highSugarDays.size,
            highFatDays: highFatDays.size,
            sweetNearMealCount: sweetNearMealCount,
            lateNightSnackCount: lateNightSnackCount,
            heavyFlavorCount: heavyFlavorCount,
            childSnackOverLimit: childSnackOverLimit
        };
        return data;
    }
    private timestampInRange(timestamp: number, startDate: string, endDate: string): boolean {
        const date = DateUtil.formatDate(new Date(timestamp));
        return date >= startDate && date <= endDate;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "WeeklyReportPage";
    }
}
registerNamedRoute(() => new WeeklyReportPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/WeeklyReportPage", pageFullPath: "entry/src/main/ets/pages/WeeklyReportPage", integratedHsp: "false", moduleType: "followWithHap" });

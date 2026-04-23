if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HistoryPage_Params {
    familyMembers?: FamilyProfile[];
    historyRecords?: ScanHistoryRecord[];
    selectedMemberId?: string;
    appState?: AppState;
}
import router from "@ohos:router";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import type { FamilyProfile } from '../model/FamilyProfile';
import type { ScanHistoryRecord } from '../repository/HistoryRepository';
import { DateUtil } from "@bundle:com.familyfood.helper/entry/ets/utils/DateUtil";
class HistoryPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__familyMembers = new ObservedPropertyObjectPU([], this, "familyMembers");
        this.__historyRecords = new ObservedPropertyObjectPU([], this, "historyRecords");
        this.__selectedMemberId = new ObservedPropertySimplePU('all', this, "selectedMemberId");
        this.appState = AppState.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HistoryPage_Params) {
        if (params.familyMembers !== undefined) {
            this.familyMembers = params.familyMembers;
        }
        if (params.historyRecords !== undefined) {
            this.historyRecords = params.historyRecords;
        }
        if (params.selectedMemberId !== undefined) {
            this.selectedMemberId = params.selectedMemberId;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
    }
    updateStateVars(params: HistoryPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__familyMembers.purgeDependencyOnElmtId(rmElmtId);
        this.__historyRecords.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedMemberId.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__familyMembers.aboutToBeDeleted();
        this.__historyRecords.aboutToBeDeleted();
        this.__selectedMemberId.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __familyMembers: ObservedPropertyObjectPU<FamilyProfile[]>;
    get familyMembers() {
        return this.__familyMembers.get();
    }
    set familyMembers(newValue: FamilyProfile[]) {
        this.__familyMembers.set(newValue);
    }
    private __historyRecords: ObservedPropertyObjectPU<ScanHistoryRecord[]>;
    get historyRecords() {
        return this.__historyRecords.get();
    }
    set historyRecords(newValue: ScanHistoryRecord[]) {
        this.__historyRecords.set(newValue);
    }
    private __selectedMemberId: ObservedPropertySimplePU<string>;
    get selectedMemberId() {
        return this.__selectedMemberId.get();
    }
    set selectedMemberId(newValue: string) {
        this.__selectedMemberId.set(newValue);
    }
    private appState: AppState;
    async aboutToAppear() {
        this.familyMembers = await this.appState.getAllMembers();
        this.historyRecords = await this.appState.getRecentScanHistory(100);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor('#FAFAFA');
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
            Text.create('历史记录');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.scrollable(ScrollDirection.Horizontal);
            Scroll.width('100%');
            Scroll.padding({ left: 16, right: 16 });
            Scroll.margin({ bottom: 14 });
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('全部');
            Text.fontSize(13);
            Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
            Text.borderRadius(16);
            Text.backgroundColor(this.selectedMemberId === 'all' ? '#1976D2' : '#FFFFFF');
            Text.fontColor(this.selectedMemberId === 'all' ? '#FFFFFF' : '#212121');
            Text.margin({ right: 8 });
            Text.onClick(() => { this.selectedMemberId = 'all'; });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const member = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(member.nickname);
                    Text.fontSize(13);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.borderRadius(16);
                    Text.backgroundColor(this.selectedMemberId === member.memberId ? '#1976D2' : '#FFFFFF');
                    Text.fontColor(this.selectedMemberId === member.memberId ? '#FFFFFF' : '#212121');
                    Text.margin({ right: 8 });
                    Text.onClick(() => { this.selectedMemberId = member.memberId; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.familyMembers, forEachItemGenFunction, (member: FamilyProfile) => member.memberId, false, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        Scroll.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.getVisibleRecords().length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                        Column.alignItems(HorizontalAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('还没有历史记录');
                        Text.fontSize(16);
                        Text.fontColor('#616161');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('先去拍标签或扫码，再回来查看');
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
                        List.create();
                        List.width('100%');
                        List.layoutWeight(1);
                        List.padding({ left: 16, right: 16 });
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const record = _item;
                            {
                                const itemCreation = (elmtId, isInitialRender) => {
                                    ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                                    ListItem.create(deepRenderFunction, true);
                                    if (!isInitialRender) {
                                        ListItem.pop();
                                    }
                                    ViewStackProcessor.StopGetAccessRecording();
                                };
                                const itemCreation2 = (elmtId, isInitialRender) => {
                                    ListItem.create(deepRenderFunction, true);
                                };
                                const deepRenderFunction = (elmtId, isInitialRender) => {
                                    itemCreation(elmtId, isInitialRender);
                                    this.HistoryCard.bind(this)(record);
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.getVisibleRecords(), forEachItemGenFunction, (record: ScanHistoryRecord) => `${record.id}`, false, false);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    HistoryCard(record: ScanHistoryRecord, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(14);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(14);
            Column.margin({ bottom: 8 });
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(record.foodName);
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.getMemberName(record.memberId));
            Text.fontSize(12);
            Text.fontColor('#757575');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(DateUtil.formatTimestamp(record.scannedAt));
            Text.fontSize(11);
            Text.fontColor('#9E9E9E');
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.margin({ top: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(record.level);
            Text.fontSize(12);
            Text.fontColor(this.getLevelColor(record.level));
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (record.maxAmount > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(` · 建议上限 ${Math.round(record.maxAmount)} g`);
                        Text.fontSize(12);
                        Text.fontColor('#616161');
                        Text.margin({ left: 6 });
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
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (record.reasons.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(record.reasons[0]);
                        Text.fontSize(12);
                        Text.fontColor('#616161');
                        Text.margin({ top: 8 });
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
    private getVisibleRecords(): ScanHistoryRecord[] {
        if (this.selectedMemberId === 'all') {
            return this.historyRecords;
        }
        return this.historyRecords.filter(record => record.memberId === this.selectedMemberId);
    }
    private getMemberName(memberId: string): string {
        const member = this.familyMembers.find(item => item.memberId === memberId);
        return member ? member.nickname : memberId;
    }
    private getLevelColor(level: string): string {
        if (level === '适合')
            return '#43A047';
        if (level === '少量可以')
            return '#FB8C00';
        if (level === '今天谨慎')
            return '#F4511E';
        if (level === '建议避免')
            return '#D32F2F';
        return '#757575';
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "HistoryPage";
    }
}
registerNamedRoute(() => new HistoryPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/HistoryPage", pageFullPath: "entry/src/main/ets/pages/HistoryPage", integratedHsp: "false", moduleType: "followWithHap" });

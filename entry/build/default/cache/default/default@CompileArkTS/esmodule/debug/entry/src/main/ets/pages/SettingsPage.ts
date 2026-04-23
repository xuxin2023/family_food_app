if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingsPage_Params {
    familyMembers?: FamilyProfile[];
    selectedMemberId?: string;
    stepLevel?: StepLevel;
    sleepStatus?: SleepStatus;
    hadHighSodiumToday?: boolean;
    hadHighSugarToday?: boolean;
    appState?: AppState;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import type { FamilyProfile } from '../model/FamilyProfile';
import { HealthSignal, StepLevel, SleepStatus, BpStatus, BsStatus, DataSource } from "@bundle:com.familyfood.helper/entry/ets/model/HealthSignal";
import { DateUtil } from "@bundle:com.familyfood.helper/entry/ets/utils/DateUtil";
class SettingsPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__familyMembers = new ObservedPropertyObjectPU([], this, "familyMembers");
        this.__selectedMemberId = new ObservedPropertySimplePU('', this, "selectedMemberId");
        this.__stepLevel = new ObservedPropertySimplePU(StepLevel.NORMAL, this, "stepLevel");
        this.__sleepStatus = new ObservedPropertySimplePU(SleepStatus.GOOD, this, "sleepStatus");
        this.__hadHighSodiumToday = new ObservedPropertySimplePU(false, this, "hadHighSodiumToday");
        this.__hadHighSugarToday = new ObservedPropertySimplePU(false, this, "hadHighSugarToday");
        this.appState = AppState.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingsPage_Params) {
        if (params.familyMembers !== undefined) {
            this.familyMembers = params.familyMembers;
        }
        if (params.selectedMemberId !== undefined) {
            this.selectedMemberId = params.selectedMemberId;
        }
        if (params.stepLevel !== undefined) {
            this.stepLevel = params.stepLevel;
        }
        if (params.sleepStatus !== undefined) {
            this.sleepStatus = params.sleepStatus;
        }
        if (params.hadHighSodiumToday !== undefined) {
            this.hadHighSodiumToday = params.hadHighSodiumToday;
        }
        if (params.hadHighSugarToday !== undefined) {
            this.hadHighSugarToday = params.hadHighSugarToday;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
    }
    updateStateVars(params: SettingsPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__familyMembers.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedMemberId.purgeDependencyOnElmtId(rmElmtId);
        this.__stepLevel.purgeDependencyOnElmtId(rmElmtId);
        this.__sleepStatus.purgeDependencyOnElmtId(rmElmtId);
        this.__hadHighSodiumToday.purgeDependencyOnElmtId(rmElmtId);
        this.__hadHighSugarToday.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__familyMembers.aboutToBeDeleted();
        this.__selectedMemberId.aboutToBeDeleted();
        this.__stepLevel.aboutToBeDeleted();
        this.__sleepStatus.aboutToBeDeleted();
        this.__hadHighSodiumToday.aboutToBeDeleted();
        this.__hadHighSugarToday.aboutToBeDeleted();
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
    private __selectedMemberId: ObservedPropertySimplePU<string>;
    get selectedMemberId() {
        return this.__selectedMemberId.get();
    }
    set selectedMemberId(newValue: string) {
        this.__selectedMemberId.set(newValue);
    }
    private __stepLevel: ObservedPropertySimplePU<StepLevel>;
    get stepLevel() {
        return this.__stepLevel.get();
    }
    set stepLevel(newValue: StepLevel) {
        this.__stepLevel.set(newValue);
    }
    private __sleepStatus: ObservedPropertySimplePU<SleepStatus>;
    get sleepStatus() {
        return this.__sleepStatus.get();
    }
    set sleepStatus(newValue: SleepStatus) {
        this.__sleepStatus.set(newValue);
    }
    private __hadHighSodiumToday: ObservedPropertySimplePU<boolean>;
    get hadHighSodiumToday() {
        return this.__hadHighSodiumToday.get();
    }
    set hadHighSodiumToday(newValue: boolean) {
        this.__hadHighSodiumToday.set(newValue);
    }
    private __hadHighSugarToday: ObservedPropertySimplePU<boolean>;
    get hadHighSugarToday() {
        return this.__hadHighSugarToday.get();
    }
    set hadHighSugarToday(newValue: boolean) {
        this.__hadHighSugarToday.set(newValue);
    }
    private appState: AppState;
    async aboutToAppear() {
        this.familyMembers = await this.appState.getAllMembers();
        if (this.familyMembers.length > 0) {
            this.selectedMemberId = this.familyMembers[0].memberId;
            this.loadMemberSignal(this.selectedMemberId);
        }
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
            Text.create('设置');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 14 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('P0 MVP 只使用本地手动状态');
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('当前不接真实 Health Kit，不接真实订阅付费。你可以为每个家庭成员手动设置今天的活动、睡眠和偏咸/偏甜状态。');
            Text.fontSize(12);
            Text.fontColor('#616161');
            Text.lineHeight(18);
        }, Text);
        Text.pop();
        Column.pop();
        this.MemberSelector.bind(this)();
        this.ManualHealthPanel.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('保存今日状态');
            Button.width('90%');
            Button.height(50);
            Button.backgroundColor('#1976D2');
            Button.borderRadius(25);
            Button.margin({ top: 8, bottom: 24 });
            Button.onClick(() => { this.saveManualStatus(); });
        }, Button);
        Button.pop();
        Column.pop();
        Scroll.pop();
    }
    MemberSelector(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 14 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('设置谁的今日状态');
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
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
                    Text.onClick(() => {
                        this.selectedMemberId = member.memberId;
                        this.loadMemberSignal(member.memberId);
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.familyMembers, forEachItemGenFunction, (member: FamilyProfile) => member.memberId, false, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        Column.pop();
    }
    ManualHealthPanel(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('手动今日状态');
            Text.fontSize(17);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('活动量');
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.margin({ bottom: 14 });
        }, Row);
        this.OptionChip.bind(this)('活动少', this.stepLevel === StepLevel.LOW, () => { this.stepLevel = StepLevel.LOW; });
        this.OptionChip.bind(this)('正常', this.stepLevel === StepLevel.NORMAL, () => { this.stepLevel = StepLevel.NORMAL; });
        this.OptionChip.bind(this)('运动多', this.stepLevel === StepLevel.HIGH, () => { this.stepLevel = StepLevel.HIGH; });
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('睡眠');
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.margin({ bottom: 14 });
        }, Row);
        this.OptionChip.bind(this)('好', this.sleepStatus === SleepStatus.GOOD, () => { this.sleepStatus = SleepStatus.GOOD; });
        this.OptionChip.bind(this)('一般', this.sleepStatus === SleepStatus.FAIR, () => { this.sleepStatus = SleepStatus.FAIR; });
        this.OptionChip.bind(this)('差', this.sleepStatus === SleepStatus.POOR, () => { this.sleepStatus = SleepStatus.POOR; });
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今天已经吃过');
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
        }, Row);
        this.OptionChip.bind(this)('高盐', this.hadHighSodiumToday, () => { this.hadHighSodiumToday = !this.hadHighSodiumToday; });
        this.OptionChip.bind(this)('高糖', this.hadHighSugarToday, () => { this.hadHighSugarToday = !this.hadHighSugarToday; });
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('这些状态会直接影响今天的适配报告和美食额度判断。');
            Text.fontSize(12);
            Text.fontColor('#9E9E9E');
            Text.margin({ top: 12 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    OptionChip(label: string, active: boolean, onClick: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(13);
            Text.padding({ left: 12, right: 12, top: 8, bottom: 8 });
            Text.borderRadius(18);
            Text.backgroundColor(active ? '#1976D2' : '#F5F5F5');
            Text.fontColor(active ? '#FFFFFF' : '#212121');
            Text.margin({ right: 8 });
            Text.onClick(onClick);
        }, Text);
        Text.pop();
    }
    private loadMemberSignal(memberId: string) {
        const signal = this.appState.getHealthSignal(memberId);
        this.stepLevel = signal.stepLevel;
        this.sleepStatus = signal.sleepStatus;
        this.hadHighSodiumToday = signal.hadHighSodiumToday;
        this.hadHighSugarToday = signal.hadHighSugarToday;
    }
    private saveManualStatus() {
        if (this.selectedMemberId.length === 0) {
            return;
        }
        const signal = new HealthSignal();
        signal.memberId = this.selectedMemberId;
        signal.date = DateUtil.getToday();
        signal.stepLevel = this.stepLevel;
        signal.activityCaloriesLevel = this.stepLevel;
        signal.sleepStatus = this.sleepStatus;
        signal.manualBpStatus = this.hadHighSodiumToday ? BpStatus.ELEVATED : BpStatus.NORMAL;
        signal.manualBsStatus = this.hadHighSugarToday ? BsStatus.ELEVATED : BsStatus.NORMAL;
        signal.hadHighSodiumToday = this.hadHighSodiumToday;
        signal.hadHighSugarToday = this.hadHighSugarToday;
        signal.source = DataSource.MANUAL;
        this.appState.updateHealthSignal(signal);
        promptAction.showToast({ message: '今日状态已保存' });
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SettingsPage";
    }
}
registerNamedRoute(() => new SettingsPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/SettingsPage", pageFullPath: "entry/src/main/ets/pages/SettingsPage", integratedHsp: "false", moduleType: "followWithHap" });

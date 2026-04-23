if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SharePage_Params {
    foodName?: string;
    recommendations?: Recommendation[];
    familyMembers?: FamilyProfile[];
    shareText?: string;
    copyHint?: string;
    isWorking?: boolean;
    appState?: AppState;
    shareService?: ShareService;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import type { Recommendation } from '../model/Recommendation';
import type { FamilyProfile } from '../model/FamilyProfile';
import { ShareCard } from "@bundle:com.familyfood.helper/entry/ets/components/ShareCard";
import { ShareService } from "@bundle:com.familyfood.helper/entry/ets/service/ShareService";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import type { ShareActionResult } from '../service/share/ShareProvider';
class SharePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__foodName = new ObservedPropertySimplePU('', this, "foodName");
        this.__recommendations = new ObservedPropertyObjectPU([], this, "recommendations");
        this.__familyMembers = new ObservedPropertyObjectPU([], this, "familyMembers");
        this.__shareText = new ObservedPropertySimplePU('', this, "shareText");
        this.__copyHint = new ObservedPropertySimplePU('', this, "copyHint");
        this.__isWorking = new ObservedPropertySimplePU(false, this, "isWorking");
        this.appState = AppState.getInstance();
        this.shareService = new ShareService();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SharePage_Params) {
        if (params.foodName !== undefined) {
            this.foodName = params.foodName;
        }
        if (params.recommendations !== undefined) {
            this.recommendations = params.recommendations;
        }
        if (params.familyMembers !== undefined) {
            this.familyMembers = params.familyMembers;
        }
        if (params.shareText !== undefined) {
            this.shareText = params.shareText;
        }
        if (params.copyHint !== undefined) {
            this.copyHint = params.copyHint;
        }
        if (params.isWorking !== undefined) {
            this.isWorking = params.isWorking;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
        if (params.shareService !== undefined) {
            this.shareService = params.shareService;
        }
    }
    updateStateVars(params: SharePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__foodName.purgeDependencyOnElmtId(rmElmtId);
        this.__recommendations.purgeDependencyOnElmtId(rmElmtId);
        this.__familyMembers.purgeDependencyOnElmtId(rmElmtId);
        this.__shareText.purgeDependencyOnElmtId(rmElmtId);
        this.__copyHint.purgeDependencyOnElmtId(rmElmtId);
        this.__isWorking.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__foodName.aboutToBeDeleted();
        this.__recommendations.aboutToBeDeleted();
        this.__familyMembers.aboutToBeDeleted();
        this.__shareText.aboutToBeDeleted();
        this.__copyHint.aboutToBeDeleted();
        this.__isWorking.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __foodName: ObservedPropertySimplePU<string>;
    get foodName() {
        return this.__foodName.get();
    }
    set foodName(newValue: string) {
        this.__foodName.set(newValue);
    }
    private __recommendations: ObservedPropertyObjectPU<Recommendation[]>;
    get recommendations() {
        return this.__recommendations.get();
    }
    set recommendations(newValue: Recommendation[]) {
        this.__recommendations.set(newValue);
    }
    private __familyMembers: ObservedPropertyObjectPU<FamilyProfile[]>;
    get familyMembers() {
        return this.__familyMembers.get();
    }
    set familyMembers(newValue: FamilyProfile[]) {
        this.__familyMembers.set(newValue);
    }
    private __shareText: ObservedPropertySimplePU<string>;
    get shareText() {
        return this.__shareText.get();
    }
    set shareText(newValue: string) {
        this.__shareText.set(newValue);
    }
    private __copyHint: ObservedPropertySimplePU<string>;
    get copyHint() {
        return this.__copyHint.get();
    }
    set copyHint(newValue: string) {
        this.__copyHint.set(newValue);
    }
    private __isWorking: ObservedPropertySimplePU<boolean>;
    get isWorking() {
        return this.__isWorking.get();
    }
    set isWorking(newValue: boolean) {
        this.__isWorking.set(newValue);
    }
    private appState: AppState;
    private shareService: ShareService;
    async aboutToAppear() {
        const params = router.getParams() as Record<string, Object>;
        if (params) {
            this.foodName = (params.foodName as string) || '';
            this.recommendations = (params.recommendations as Recommendation[]) || [];
            this.familyMembers = (params.members as FamilyProfile[]) || [];
        }
        if (this.familyMembers.length === 0) {
            this.familyMembers = await this.appState.getAllMembers();
        }
        this.copyHint = this.shareService.getCopyHint();
        this.refreshShareText();
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
            Text.create('分享文案');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.recommendations.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    if (!If.canRetake('shareCardComponent')) {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.id('shareCardComponent');
                            Column.width('90%');
                            Column.margin({ bottom: 16 });
                        }, Column);
                        {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                if (isInitialRender) {
                                    let componentCall = new ShareCard(this, {
                                        foodName: this.foodName,
                                        recommendations: this.recommendations,
                                        members: this.familyMembers
                                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/SharePage.ets", line: 56, col: 13 });
                                    ViewPU.create(componentCall);
                                    let paramsLambda = () => {
                                        return {
                                            foodName: this.foodName,
                                            recommendations: this.recommendations,
                                            members: this.familyMembers
                                        };
                                    };
                                    componentCall.paramsGenerator_ = paramsLambda;
                                }
                                else {
                                    this.updateStateVarsOfChildByElmtId(elmtId, {
                                        foodName: this.foodName,
                                        recommendations: this.recommendations,
                                        members: this.familyMembers
                                    });
                                }
                            }, { name: "ShareCard" });
                        }
                        Column.pop();
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('90%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 16 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('可复制分享文案');
            Text.fontSize(17);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.copyHint);
            Text.fontSize(12);
            Text.fontColor('#757575');
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextArea.create({ text: this.shareText, placeholder: '报告生成后，这里会出现可复制文案。' });
            TextArea.width('100%');
            TextArea.height(220);
            TextArea.padding(12);
            TextArea.backgroundColor('#F7F8FA');
            TextArea.borderRadius(12);
            TextArea.onChange((value: string) => { this.shareText = value; });
        }, TextArea);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.margin({ top: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('刷新文案');
            Button.layoutWeight(1);
            Button.height(44);
            Button.backgroundColor('#E3F2FD');
            Button.fontColor('#1976D2');
            Button.borderRadius(22);
            Button.onClick(() => { this.refreshShareText(); });
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('复制说明');
            Button.layoutWeight(1);
            Button.height(44);
            Button.backgroundColor('#F5F5F5');
            Button.fontColor('#616161');
            Button.borderRadius(22);
            Button.margin({ left: 10 });
            Button.onClick(() => {
                promptAction.showToast({ message: this.copyHint });
            });
        }, Button);
        Button.pop();
        Row.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('90%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('未接入的系统能力');
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('P0 版先保证文案可复制；系统分享、图片生成、保存相册都不会再提示假成功。');
            Text.fontSize(12);
            Text.fontColor('#757575');
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('系统分享');
            Button.layoutWeight(1);
            Button.height(44);
            Button.backgroundColor('#EEEEEE');
            Button.fontColor('#616161');
            Button.borderRadius(22);
            Button.onClick(() => { this.handleUnsupportedAction('family'); });
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('微信分享');
            Button.layoutWeight(1);
            Button.height(44);
            Button.backgroundColor('#EEEEEE');
            Button.fontColor('#616161');
            Button.borderRadius(22);
            Button.margin({ left: 10 });
            Button.onClick(() => { this.handleUnsupportedAction('wechat'); });
        }, Button);
        Button.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('保存图片 / 相册');
            Button.width('100%');
            Button.height(44);
            Button.backgroundColor('#EEEEEE');
            Button.fontColor('#616161');
            Button.borderRadius(22);
            Button.margin({ top: 10 });
            Button.onClick(() => { this.handleUnsupportedAction('image'); });
        }, Button);
        Button.pop();
        Column.pop();
        Column.pop();
        Scroll.pop();
    }
    private refreshShareText() {
        this.shareText = this.shareService.generateShareText(this.shareService.buildShareParams(this.foodName, this.recommendations, this.familyMembers));
    }
    private async handleUnsupportedAction(action: 'family' | 'wechat' | 'image') {
        if (this.isWorking) {
            return;
        }
        this.isWorking = true;
        let result: ShareActionResult;
        if (action === 'family') {
            result = await this.shareService.shareToFamily(this.shareText);
        }
        else if (action === 'wechat') {
            result = await this.shareService.shareToWechat(this.shareText);
        }
        else {
            result = await this.shareService.saveAsImage('shareCardComponent');
        }
        promptAction.showToast({ message: result.message });
        this.isWorking = false;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SharePage";
    }
}
registerNamedRoute(() => new SharePage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/SharePage", pageFullPath: "entry/src/main/ets/pages/SharePage", integratedHsp: "false", moduleType: "followWithHap" });

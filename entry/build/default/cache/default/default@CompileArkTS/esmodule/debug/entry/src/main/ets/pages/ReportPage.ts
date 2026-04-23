if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ReportPage_Params {
    foodLabel?: FoodLabel;
    familyMembers?: FamilyProfile[];
    recommendations?: Recommendation[];
    selectedMemberId?: string;
    selectedRecommendation?: Recommendation | null;
    childProtection?: ChildProtection | null;
    credibilityResult?: CredibilityResult;
    appState?: AppState;
    foodId?: string;
    historySaved?: boolean;
}
import router from "@ohos:router";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import { FoodLabel } from "@bundle:com.familyfood.helper/entry/ets/model/FoodLabel";
import type { FamilyProfile } from '../model/FamilyProfile';
import { getLevelColorValue } from "@bundle:com.familyfood.helper/entry/ets/model/Recommendation";
import type { Recommendation } from "@bundle:com.familyfood.helper/entry/ets/model/Recommendation";
import type { ChildProtection } from '../model/ChildProtection';
import { CredibilityResult } from "@bundle:com.familyfood.helper/entry/ets/model/CredibilityResult";
import { FoodLabelCard } from "@bundle:com.familyfood.helper/entry/ets/components/FoodLabelCard";
import { FamilyCompareView } from "@bundle:com.familyfood.helper/entry/ets/components/FamilyCompareView";
import { ChildProtectionCard } from "@bundle:com.familyfood.helper/entry/ets/components/ChildProtectionCard";
import { CredibilityCard } from "@bundle:com.familyfood.helper/entry/ets/components/CredibilityCard";
class ReportPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__foodLabel = new ObservedPropertyObjectPU(new FoodLabel(), this, "foodLabel");
        this.__familyMembers = new ObservedPropertyObjectPU([], this, "familyMembers");
        this.__recommendations = new ObservedPropertyObjectPU([], this, "recommendations");
        this.__selectedMemberId = new ObservedPropertySimplePU('', this, "selectedMemberId");
        this.__selectedRecommendation = new ObservedPropertyObjectPU(null, this, "selectedRecommendation");
        this.__childProtection = new ObservedPropertyObjectPU(null, this, "childProtection");
        this.__credibilityResult = new ObservedPropertyObjectPU(new CredibilityResult(), this, "credibilityResult");
        this.appState = AppState.getInstance();
        this.foodId = '';
        this.historySaved = false;
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ReportPage_Params) {
        if (params.foodLabel !== undefined) {
            this.foodLabel = params.foodLabel;
        }
        if (params.familyMembers !== undefined) {
            this.familyMembers = params.familyMembers;
        }
        if (params.recommendations !== undefined) {
            this.recommendations = params.recommendations;
        }
        if (params.selectedMemberId !== undefined) {
            this.selectedMemberId = params.selectedMemberId;
        }
        if (params.selectedRecommendation !== undefined) {
            this.selectedRecommendation = params.selectedRecommendation;
        }
        if (params.childProtection !== undefined) {
            this.childProtection = params.childProtection;
        }
        if (params.credibilityResult !== undefined) {
            this.credibilityResult = params.credibilityResult;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
        if (params.foodId !== undefined) {
            this.foodId = params.foodId;
        }
        if (params.historySaved !== undefined) {
            this.historySaved = params.historySaved;
        }
    }
    updateStateVars(params: ReportPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__foodLabel.purgeDependencyOnElmtId(rmElmtId);
        this.__familyMembers.purgeDependencyOnElmtId(rmElmtId);
        this.__recommendations.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedMemberId.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedRecommendation.purgeDependencyOnElmtId(rmElmtId);
        this.__childProtection.purgeDependencyOnElmtId(rmElmtId);
        this.__credibilityResult.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__foodLabel.aboutToBeDeleted();
        this.__familyMembers.aboutToBeDeleted();
        this.__recommendations.aboutToBeDeleted();
        this.__selectedMemberId.aboutToBeDeleted();
        this.__selectedRecommendation.aboutToBeDeleted();
        this.__childProtection.aboutToBeDeleted();
        this.__credibilityResult.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __foodLabel: ObservedPropertyObjectPU<FoodLabel>;
    get foodLabel() {
        return this.__foodLabel.get();
    }
    set foodLabel(newValue: FoodLabel) {
        this.__foodLabel.set(newValue);
    }
    private __familyMembers: ObservedPropertyObjectPU<FamilyProfile[]>;
    get familyMembers() {
        return this.__familyMembers.get();
    }
    set familyMembers(newValue: FamilyProfile[]) {
        this.__familyMembers.set(newValue);
    }
    private __recommendations: ObservedPropertyObjectPU<Recommendation[]>;
    get recommendations() {
        return this.__recommendations.get();
    }
    set recommendations(newValue: Recommendation[]) {
        this.__recommendations.set(newValue);
    }
    private __selectedMemberId: ObservedPropertySimplePU<string>;
    get selectedMemberId() {
        return this.__selectedMemberId.get();
    }
    set selectedMemberId(newValue: string) {
        this.__selectedMemberId.set(newValue);
    }
    private __selectedRecommendation: ObservedPropertyObjectPU<Recommendation | null>;
    get selectedRecommendation() {
        return this.__selectedRecommendation.get();
    }
    set selectedRecommendation(newValue: Recommendation | null) {
        this.__selectedRecommendation.set(newValue);
    }
    private __childProtection: ObservedPropertyObjectPU<ChildProtection | null>;
    get childProtection() {
        return this.__childProtection.get();
    }
    set childProtection(newValue: ChildProtection | null) {
        this.__childProtection.set(newValue);
    }
    private __credibilityResult: ObservedPropertyObjectPU<CredibilityResult>;
    get credibilityResult() {
        return this.__credibilityResult.get();
    }
    set credibilityResult(newValue: CredibilityResult) {
        this.__credibilityResult.set(newValue);
    }
    private appState: AppState;
    private foodId: string;
    private historySaved: boolean;
    async aboutToAppear() {
        const params = router.getParams() as Record<string, string>;
        if (params) {
            this.foodId = params.foodId || '';
            this.selectedMemberId = params.memberId || '';
        }
        await this.loadReportData();
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
            Text.create('\u5BB6\u5EAD\u9002\u914D\u62A5\u544A');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.margin({ bottom: 14 });
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new FoodLabelCard(this, { foodLabel: this.foodLabel }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/ReportPage.ets", line: 54, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            foodLabel: this.foodLabel
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        foodLabel: this.foodLabel
                    });
                }
            }, { name: "FoodLabelCard" });
        }
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.familyMembers.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.MemberSelector.bind(this)();
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
            if (this.recommendations.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('92%');
                        Column.margin({ bottom: 14 });
                    }, Column);
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new FamilyCompareView(this, { recommendations: this.recommendations, members: this.familyMembers }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/ReportPage.ets", line: 65, col: 13 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        recommendations: this.recommendations,
                                        members: this.familyMembers
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    recommendations: this.recommendations, members: this.familyMembers
                                });
                            }
                        }, { name: "FamilyCompareView" });
                    }
                    Column.pop();
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
            if (this.selectedRecommendation !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.SelectedMemberSummary.bind(this)();
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
            if (this.childProtection !== null && this.childProtection.hasAnyAdvice()) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('92%');
                        Column.margin({ bottom: 14 });
                    }, Column);
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new ChildProtectionCard(this, { protection: this.childProtection }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/ReportPage.ets", line: 77, col: 13 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        protection: this.childProtection
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    protection: this.childProtection
                                });
                            }
                        }, { name: "ChildProtectionCard" });
                    }
                    Column.pop();
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
            Column.width('92%');
            Column.margin({ bottom: 20 });
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new CredibilityCard(this, { result: this.credibilityResult }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/ReportPage.ets", line: 84, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            result: this.credibilityResult
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        result: this.credibilityResult
                    });
                }
            }, { name: "CredibilityCard" });
        }
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('\u751F\u6210\u5206\u4EAB\u6587\u6848');
            Button.width('90%');
            Button.height(50);
            Button.backgroundColor('#1976D2');
            Button.borderRadius(25);
            Button.margin({ bottom: 24 });
            Button.onClick(() => {
                router.pushUrl({
                    url: 'pages/SharePage',
                    params: {
                        foodName: this.foodLabel.foodName,
                        recommendations: this.recommendations,
                        members: this.familyMembers
                    }
                });
            });
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
            Text.create('\u67E5\u770B\u8C01\u7684\u7ED3\u8BBA');
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.margin({ bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
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
                    Text.onClick(() => { this.selectMember(member.memberId); });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.familyMembers, forEachItemGenFunction, (member: FamilyProfile) => member.memberId, false, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        Column.pop();
    }
    SelectedMemberSummary(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.selectedRecommendation !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
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
                        Row.create();
                        Row.width('100%');
                        Row.margin({ bottom: 10 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${this.familyMembers.find(item => item.memberId === this.selectedMemberId)?.nickname || ''} \u7684\u7ED3\u8BBA`);
                        Text.fontSize(17);
                        Text.fontWeight(FontWeight.Bold);
                        Text.layoutWeight(1);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.selectedRecommendation.level);
                        Text.fontSize(12);
                        Text.fontColor('#FFFFFF');
                        Text.padding({ left: 10, right: 10, top: 4, bottom: 4 });
                        Text.borderRadius(12);
                        Text.backgroundColor(getLevelColorValue(this.selectedRecommendation.levelColor));
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.selectedRecommendation.maxAmount > 0 ? `\u5EFA\u8BAE\u4E0A\u9650\uFF1A${this.selectedRecommendation.maxAmount} g` : '\u5EFA\u8BAE\u907F\u514D\u98DF\u7528');
                        Text.fontSize(14);
                        Text.fontColor('#212121');
                        Text.margin({ bottom: 10 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.selectedRecommendation.reasons.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('\u539F\u56E0');
                                    Text.fontSize(13);
                                    Text.fontColor('#757575');
                                    Text.margin({ bottom: 6 });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const reason = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(`\u2022 ${reason}`);
                                            Text.fontSize(13);
                                            Text.fontColor('#212121');
                                            Text.margin({ bottom: 4 });
                                        }, Text);
                                        Text.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.selectedRecommendation.reasons, forEachItemGenFunction, (reason: string, index: number) => `${index}`, false, true);
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
                        if (this.selectedRecommendation.reminders.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('\u63D0\u9192');
                                    Text.fontSize(13);
                                    Text.fontColor('#757575');
                                    Text.margin({ top: 10, bottom: 6 });
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const reminder = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(`\u2022 ${reminder}`);
                                            Text.fontSize(13);
                                            Text.fontColor('#616161');
                                            Text.margin({ bottom: 4 });
                                        }, Text);
                                        Text.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.selectedRecommendation.reminders, forEachItemGenFunction, (reminder: string, index: number) => `${index}`, false, true);
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
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
    }
    private async loadReportData() {
        this.familyMembers = await this.appState.getAllMembers();
        if (this.foodId.length > 0) {
            const savedFood = await this.appState.findFoodById(this.foodId);
            if (savedFood) {
                this.foodLabel = savedFood;
            }
        }
        if (this.foodLabel.foodId.length === 0) {
            this.foodLabel = new FoodLabel();
            this.foodLabel.foodId = 'food_missing';
            this.foodLabel.foodName = '\u672A\u627E\u5230\u5BF9\u5E94 FoodLabel';
        }
        if (this.selectedMemberId.length === 0 && this.familyMembers.length > 0) {
            this.selectedMemberId = this.familyMembers[0].memberId;
        }
        this.recommendations = this.appState.calculateFamilyComparison(this.foodLabel);
        this.credibilityResult = this.appState.calculateCredibility(this.foodLabel);
        this.selectMember(this.selectedMemberId);
        if (!this.historySaved) {
            for (const recommendation of this.recommendations) {
                await this.appState.saveScanHistory(recommendation.memberId, this.foodLabel, recommendation);
            }
            this.historySaved = true;
        }
    }
    private selectMember(memberId: string) {
        this.selectedMemberId = memberId;
        this.selectedRecommendation = this.recommendations.find(item => item.memberId === memberId) || null;
        const member = this.familyMembers.find(item => item.memberId === memberId) || null;
        if (member && member.isChild()) {
            this.childProtection = this.appState.calculateChildProtection(memberId, this.foodLabel);
        }
        else {
            this.childProtection = null;
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ReportPage";
    }
}
registerNamedRoute(() => new ReportPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/ReportPage", pageFullPath: "entry/src/main/ets/pages/ReportPage", integratedHsp: "false", moduleType: "followWithHap" });

if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface BalancePage_Params {
    familyMembers?: FamilyProfile[];
    selectedMemberId?: string;
    currentBudget?: DailyBudget;
    balanceResult?: MealBalance | null;
    childProtection?: ChildProtection | null;
    positiveAdvice?: PositiveAdvice | null;
    selectedScenario?: MealScenario | null;
    appState?: AppState;
    scenarios?: ScenarioOption[];
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import type { FamilyProfile } from '../model/FamilyProfile';
import { DailyBudget } from "@bundle:com.familyfood.helper/entry/ets/model/DailyBudget";
import { FoodLabel, FoodSource } from "@bundle:com.familyfood.helper/entry/ets/model/FoodLabel";
import { MealScenario } from "@bundle:com.familyfood.helper/entry/ets/model/MealBalance";
import type { MealBalance } from "@bundle:com.familyfood.helper/entry/ets/model/MealBalance";
import type { ChildProtection } from '../model/ChildProtection';
import type { PositiveAdvice } from '../engine/PositiveAdviceEngine';
import { BalanceAdviceCard } from "@bundle:com.familyfood.helper/entry/ets/components/BalanceAdviceCard";
import { ChildProtectionCard } from "@bundle:com.familyfood.helper/entry/ets/components/ChildProtectionCard";
// 美食场景选项
class ScenarioOption {
    emoji: string = '';
    label: string = '';
    value: MealScenario = MealScenario.BBQ;
}
class BalancePage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__familyMembers = new ObservedPropertyObjectPU([], this, "familyMembers");
        this.__selectedMemberId = new ObservedPropertySimplePU('', this, "selectedMemberId");
        this.__currentBudget = new ObservedPropertyObjectPU(new DailyBudget(), this, "currentBudget");
        this.__balanceResult = new ObservedPropertyObjectPU(null, this, "balanceResult");
        this.__childProtection = new ObservedPropertyObjectPU(null, this, "childProtection");
        this.__positiveAdvice = new ObservedPropertyObjectPU(null, this, "positiveAdvice");
        this.__selectedScenario = new ObservedPropertySimplePU(null, this, "selectedScenario");
        this.appState = AppState.getInstance();
        this.scenarios = [];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: BalancePage_Params) {
        if (params.familyMembers !== undefined) {
            this.familyMembers = params.familyMembers;
        }
        if (params.selectedMemberId !== undefined) {
            this.selectedMemberId = params.selectedMemberId;
        }
        if (params.currentBudget !== undefined) {
            this.currentBudget = params.currentBudget;
        }
        if (params.balanceResult !== undefined) {
            this.balanceResult = params.balanceResult;
        }
        if (params.childProtection !== undefined) {
            this.childProtection = params.childProtection;
        }
        if (params.positiveAdvice !== undefined) {
            this.positiveAdvice = params.positiveAdvice;
        }
        if (params.selectedScenario !== undefined) {
            this.selectedScenario = params.selectedScenario;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
        if (params.scenarios !== undefined) {
            this.scenarios = params.scenarios;
        }
    }
    updateStateVars(params: BalancePage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__familyMembers.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedMemberId.purgeDependencyOnElmtId(rmElmtId);
        this.__currentBudget.purgeDependencyOnElmtId(rmElmtId);
        this.__balanceResult.purgeDependencyOnElmtId(rmElmtId);
        this.__childProtection.purgeDependencyOnElmtId(rmElmtId);
        this.__positiveAdvice.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedScenario.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__familyMembers.aboutToBeDeleted();
        this.__selectedMemberId.aboutToBeDeleted();
        this.__currentBudget.aboutToBeDeleted();
        this.__balanceResult.aboutToBeDeleted();
        this.__childProtection.aboutToBeDeleted();
        this.__positiveAdvice.aboutToBeDeleted();
        this.__selectedScenario.aboutToBeDeleted();
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
    private __currentBudget: ObservedPropertyObjectPU<DailyBudget>;
    get currentBudget() {
        return this.__currentBudget.get();
    }
    set currentBudget(newValue: DailyBudget) {
        this.__currentBudget.set(newValue);
    }
    private __balanceResult: ObservedPropertyObjectPU<MealBalance | null>;
    get balanceResult() {
        return this.__balanceResult.get();
    }
    set balanceResult(newValue: MealBalance | null) {
        this.__balanceResult.set(newValue);
    }
    private __childProtection: ObservedPropertyObjectPU<ChildProtection | null>;
    get childProtection() {
        return this.__childProtection.get();
    }
    set childProtection(newValue: ChildProtection | null) {
        this.__childProtection.set(newValue);
    }
    private __positiveAdvice: ObservedPropertyObjectPU<PositiveAdvice | null>;
    get positiveAdvice() {
        return this.__positiveAdvice.get();
    }
    set positiveAdvice(newValue: PositiveAdvice | null) {
        this.__positiveAdvice.set(newValue);
    }
    private __selectedScenario: ObservedPropertySimplePU<MealScenario | null>;
    get selectedScenario() {
        return this.__selectedScenario.get();
    }
    set selectedScenario(newValue: MealScenario | null) {
        this.__selectedScenario.set(newValue);
    }
    private appState: AppState;
    private scenarios: ScenarioOption[];
    aboutToAppear() {
        // 初始化场景选项
        const bbq = new ScenarioOption();
        bbq.emoji = '🍖';
        bbq.label = '烧烤';
        bbq.value = MealScenario.BBQ;
        this.scenarios.push(bbq);
        const hotpot = new ScenarioOption();
        hotpot.emoji = '🍲';
        hotpot.label = '火锅';
        hotpot.value = MealScenario.HOTPOT;
        this.scenarios.push(hotpot);
        const friedChicken = new ScenarioOption();
        friedChicken.emoji = '🍗';
        friedChicken.label = '炸鸡';
        friedChicken.value = MealScenario.FRIED_CHICKEN;
        this.scenarios.push(friedChicken);
        const milkTea = new ScenarioOption();
        milkTea.emoji = '🧋';
        milkTea.label = '奶茶';
        milkTea.value = MealScenario.MILK_TEA;
        this.scenarios.push(milkTea);
        const dessert = new ScenarioOption();
        dessert.emoji = '🍰';
        dessert.label = '甜品';
        dessert.value = MealScenario.DESSERT;
        this.scenarios.push(dessert);
        const luwei = new ScenarioOption();
        luwei.emoji = '🥘';
        luwei.label = '卤味';
        luwei.value = MealScenario.LUWEI;
        this.scenarios.push(luwei);
        const instantNoodle = new ScenarioOption();
        instantNoodle.emoji = '🍜';
        instantNoodle.label = '方便面';
        instantNoodle.value = MealScenario.INSTANT_NOODLE;
        this.scenarios.push(instantNoodle);
        const lateNight = new ScenarioOption();
        lateNight.emoji = '🌙';
        lateNight.label = '夜宵';
        lateNight.value = MealScenario.LATE_NIGHT;
        this.scenarios.push(lateNight);
        this.loadData();
    }
    async loadData() {
        this.familyMembers = await this.appState.getAllMembers();
        if (this.familyMembers.length > 0) {
            this.selectedMemberId = this.familyMembers[0].memberId;
            this.refreshBudget();
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
            Text.create('记录美食');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.MemberSelector.bind(this)();
        this.BudgetCard.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今天吃了什么');
            Text.fontSize(14);
            Text.fontColor('#757575');
            Text.width('92%');
            Text.margin({ bottom: 8 });
            Text.textAlign(TextAlign.Start);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start });
            Flex.width('92%');
            Flex.margin({ bottom: 12 });
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const scenario = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.width(88);
                    Column.height(88);
                    Column.justifyContent(FlexAlign.Center);
                    Column.alignItems(HorizontalAlign.Center);
                    Column.borderRadius(14);
                    Column.backgroundColor(this.selectedScenario === scenario.value ? '#E3F2FD' : '#FFFFFF');
                    Column.border({
                        width: this.selectedScenario === scenario.value ? 2 : 1,
                        color: this.selectedScenario === scenario.value ? '#1976D2' : '#E0E0E0',
                        style: BorderStyle.Solid,
                        radius: 14
                    });
                    Column.margin({ right: 8, bottom: 10 });
                    Column.onClick(() => { this.handleScenarioSelection(scenario.value); });
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(scenario.emoji);
                    Text.fontSize(28);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(scenario.label);
                    Text.fontSize(12);
                    Text.fontColor('#212121');
                    Text.margin({ top: 4 });
                }, Text);
                Text.pop();
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.scenarios, forEachItemGenFunction, (scenario: ScenarioOption) => scenario.value, false, false);
        }, ForEach);
        ForEach.pop();
        Flex.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.balanceResult !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('92%');
                        Column.margin({ bottom: 12 });
                    }, Column);
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new BalanceAdviceCard(this, { balance: this.balanceResult }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/BalancePage.ets", line: 152, col: 13 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        balance: this.balanceResult
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    balance: this.balanceResult
                                });
                            }
                        }, { name: "BalanceAdviceCard" });
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
            if (this.childProtection !== null && this.childProtection.hasAnyAdvice()) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('92%');
                        Column.margin({ bottom: 12 });
                    }, Column);
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new ChildProtectionCard(this, { protection: this.childProtection }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/BalancePage.ets", line: 160, col: 13 });
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
            If.create();
            if (this.positiveAdvice !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.PositiveAdviceCard.bind(this)(ObservedObject.GetRawObject(this.positiveAdvice));
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
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
            Column.margin({ bottom: 12 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('谁吃了');
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
                        this.refreshBudget();
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
    BudgetCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 16 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今日美食额度');
            Text.fontSize(17);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ bottom: 10 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.justifyContent(FlexAlign.SpaceBetween);
            Row.margin({ bottom: 8 });
        }, Row);
        this.BudgetMetric.bind(this)('钠', `${Math.round(this.currentBudget.sodiumRemaining)} / ${Math.round(this.currentBudget.sodiumBudget)} mg`);
        this.BudgetMetric.bind(this)('糖', `${Math.round(this.currentBudget.sugarRemaining)} / ${Math.round(this.currentBudget.sugarBudget)} g`);
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.justifyContent(FlexAlign.SpaceBetween);
        }, Row);
        this.BudgetMetric.bind(this)('热量', `${Math.round(this.currentBudget.calorieRemaining)} / ${Math.round(this.currentBudget.calorieBudget)} kcal`);
        this.BudgetMetric.bind(this)('脂肪', `${Math.round(this.currentBudget.fatRemaining)} / ${Math.round(this.currentBudget.fatBudget)} g`);
        Row.pop();
        Column.pop();
    }
    BudgetMetric(label: string, value: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('48%');
            Column.padding(10);
            Column.backgroundColor('#F7F8FA');
            Column.borderRadius(12);
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(12);
            Text.fontColor('#757575');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(value);
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor('#212121');
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    PositiveAdviceCard(advice: PositiveAdvice | null, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (advice !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('92%');
                        Column.padding(16);
                        Column.backgroundColor('#FFFFFF');
                        Column.borderRadius(16);
                        Column.alignItems(HorizontalAlign.Start);
                        Column.margin({ bottom: 24 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('建议补什么');
                        Text.fontSize(16);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor('#2E7D32');
                        Text.margin({ bottom: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const item = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`• ${item}`);
                                Text.fontSize(13);
                                Text.fontColor('#212121');
                                Text.margin({ bottom: 4 });
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, advice.whatToSupplement, forEachItemGenFunction, (item: string, index: number) => `${index}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (advice.howToSupplement.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('下一餐建议');
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
                                            Text.fontSize(13);
                                            Text.fontColor('#616161');
                                            Text.margin({ bottom: 4 });
                                        }, Text);
                                        Text.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, advice.howToSupplement, forEachItemGenFunction, (item: string, index: number) => `${index}`, false, true);
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
    private refreshBudget() {
        if (this.selectedMemberId.length === 0) {
            return;
        }
        this.currentBudget = this.appState.getDailyBudget(this.selectedMemberId);
    }
    private async handleScenarioSelection(scenario: MealScenario) {
        if (this.selectedMemberId.length === 0) {
            return;
        }
        this.selectedScenario = scenario;
        const food = this.createFoodForScenario(scenario);
        await this.appState.saveFoodLabel(food);
        this.balanceResult = this.appState.calculateMealBalance(scenario, this.selectedMemberId);
        this.positiveAdvice = this.appState.generatePositiveAdvice(scenario, this.selectedMemberId);
        const member = this.familyMembers.find(item => item.memberId === this.selectedMemberId) || null;
        if (member && member.isChild()) {
            this.childProtection = this.appState.calculateChildProtection(this.selectedMemberId, food);
        }
        else {
            this.childProtection = null;
        }
        await this.appState.saveDietRecord(this.selectedMemberId, scenario, food.foodId, 100, food.nutrition.sodium, food.nutrition.sugar, food.nutrition.calories, food.nutrition.fat);
        this.refreshBudget();
        promptAction.showToast({ message: '已记录到今日美食额度' });
    }
    private createFoodForScenario(scenario: MealScenario): FoodLabel {
        const label = new FoodLabel();
        label.foodId = `scenario_${scenario}_${Date.now()}`;
        label.foodName = scenario;
        label.source = FoodSource.USER_UPLOAD;
        label.identifiedAt = Date.now();
        switch (scenario) {
            case MealScenario.BBQ:
                label.nutrition.sodium = 950;
                label.nutrition.sugar = 6;
                label.nutrition.calories = 320;
                label.nutrition.fat = 18;
                break;
            case MealScenario.HOTPOT:
                label.nutrition.sodium = 1300;
                label.nutrition.sugar = 5;
                label.nutrition.calories = 420;
                label.nutrition.fat = 25;
                break;
            case MealScenario.FRIED_CHICKEN:
                label.nutrition.sodium = 780;
                label.nutrition.sugar = 4;
                label.nutrition.calories = 360;
                label.nutrition.fat = 22;
                break;
            case MealScenario.MILK_TEA:
                label.nutrition.sodium = 120;
                label.nutrition.sugar = 22;
                label.nutrition.calories = 280;
                label.nutrition.fat = 9;
                break;
            case MealScenario.DESSERT:
                label.nutrition.sodium = 90;
                label.nutrition.sugar = 26;
                label.nutrition.calories = 340;
                label.nutrition.fat = 14;
                break;
            case MealScenario.LUWEI:
                label.nutrition.sodium = 1100;
                label.nutrition.sugar = 7;
                label.nutrition.calories = 260;
                label.nutrition.fat = 12;
                break;
            case MealScenario.INSTANT_NOODLE:
                label.nutrition.sodium = 1600;
                label.nutrition.sugar = 5;
                label.nutrition.calories = 470;
                label.nutrition.fat = 20;
                break;
            case MealScenario.LATE_NIGHT:
                label.nutrition.sodium = 680;
                label.nutrition.sugar = 8;
                label.nutrition.calories = 300;
                label.nutrition.fat = 13;
                break;
            default:
                label.nutrition.sodium = 300;
                label.nutrition.sugar = 5;
                label.nutrition.calories = 200;
                label.nutrition.fat = 8;
                break;
        }
        label.nutrition.carbohydrate = 25;
        label.nutrition.protein = 10;
        return label;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "BalancePage";
    }
}
registerNamedRoute(() => new BalancePage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/BalancePage", pageFullPath: "entry/src/main/ets/pages/BalancePage", integratedHsp: "false", moduleType: "followWithHap" });

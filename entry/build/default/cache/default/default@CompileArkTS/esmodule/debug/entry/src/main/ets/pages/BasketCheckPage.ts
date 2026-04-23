if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface BasketCheckPage_Params {
    basketItems?: FoodLabel[];
    checkResult?: BasketCheckResult | null;
    appState?: AppState;
}
import router from "@ohos:router";
import { FoodLabel, FoodSource, NutritionPer100g } from "@bundle:com.familyfood.helper/entry/ets/model/FoodLabel";
import type { BasketCheckResult } from '../engine/BasketCheckEngine';
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
class BasketCheckPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__basketItems = new ObservedPropertyObjectPU([], this, "basketItems");
        this.__checkResult = new ObservedPropertyObjectPU(null, this, "checkResult");
        this.appState = AppState.getInstance();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: BasketCheckPage_Params) {
        if (params.basketItems !== undefined) {
            this.basketItems = params.basketItems;
        }
        if (params.checkResult !== undefined) {
            this.checkResult = params.checkResult;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
    }
    updateStateVars(params: BasketCheckPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__basketItems.purgeDependencyOnElmtId(rmElmtId);
        this.__checkResult.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__basketItems.aboutToBeDeleted();
        this.__checkResult.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __basketItems: ObservedPropertyObjectPU<FoodLabel[]>;
    get basketItems() {
        return this.__basketItems.get();
    }
    set basketItems(newValue: FoodLabel[]) {
        this.__basketItems.set(newValue);
    }
    private __checkResult: ObservedPropertyObjectPU<BasketCheckResult | null>;
    get checkResult() {
        return this.__checkResult.get();
    }
    set checkResult(newValue: BasketCheckResult | null) {
        this.__checkResult.set(newValue);
    }
    private appState: AppState;
    async aboutToAppear() {
        // 从AppState获取购物篮数据
        this.basketItems = this.appState.getBasketItems();
        if (this.basketItems.length === 0) {
            // 无数据时使用示例
            this.basketItems = this.createFallbackBasket();
        }
        this.checkResult = this.appState.checkBasket();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.backgroundColor('#FAFAFA');
            Scroll.scrollable(ScrollDirection.Vertical);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部导航
            Row.create();
            // 顶部导航
            Row.width('100%');
            // 顶部导航
            Row.padding({ left: 16, right: 16, top: 16, bottom: 16 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.fontSize(24);
            Text.fontColor('#1976D2');
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('购物篮检查');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        // 顶部导航
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 篮子概览
            Row.create();
            // 篮子概览
            Row.width('100%');
            // 篮子概览
            Row.padding({ left: 16, right: 16 });
            // 篮子概览
            Row.margin({ bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`🛒 ${this.basketItems.length}款食品`);
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.checkResult && this.checkResult.hasRisk()) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('需要注意');
                        Text.fontSize(14);
                        Text.fontColor('#FF5722');
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('整体尚可');
                        Text.fontSize(14);
                        Text.fontColor('#4CAF50');
                    }, Text);
                    Text.pop();
                });
            }
        }, If);
        If.pop();
        // 篮子概览
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 警告列表
            if (this.checkResult && this.checkResult.warnings.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.padding(16);
                        Column.backgroundColor('#FFF3E0');
                        Column.borderRadius(12);
                        Column.margin({ left: 16, right: 16, bottom: 12 });
                        Column.alignItems(HorizontalAlign.Start);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('⚠ 购物篮提醒');
                        Text.fontSize(16);
                        Text.fontWeight(FontWeight.Medium);
                        Text.margin({ bottom: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const warning = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.margin({ bottom: 6 });
                                Row.width('100%');
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('•');
                                Text.fontSize(14);
                                Text.fontColor('#FF5722');
                                Text.margin({ right: 6 });
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(warning);
                                Text.fontSize(14);
                                Text.fontColor('#212121');
                            }, Text);
                            Text.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.checkResult.warnings, forEachItemGenFunction, (warning: string, index: number) => `${index}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                    Column.pop();
                });
            }
            // 采购建议
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 采购建议
            if (this.checkResult && this.checkResult.suggestions.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.width('100%');
                        Column.padding(16);
                        Column.backgroundColor('#E8F5E9');
                        Column.borderRadius(12);
                        Column.margin({ left: 16, right: 16, bottom: 12 });
                        Column.alignItems(HorizontalAlign.Start);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('💡 采购建议');
                        Text.fontSize(16);
                        Text.fontWeight(FontWeight.Medium);
                        Text.margin({ bottom: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const suggestion = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.margin({ bottom: 6 });
                                Row.width('100%');
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('•');
                                Text.fontSize(14);
                                Text.fontColor('#4CAF50');
                                Text.margin({ right: 6 });
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(suggestion);
                                Text.fontSize(14);
                                Text.fontColor('#212121');
                            }, Text);
                            Text.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.checkResult.suggestions, forEachItemGenFunction, (suggestion: string, index: number) => `${index}`, false, true);
                    }, ForEach);
                    ForEach.pop();
                    Column.pop();
                });
            }
            // 食品列表
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 食品列表
            Text.create('篮内食品');
            // 食品列表
            Text.fontSize(14);
            // 食品列表
            Text.fontColor('#757575');
            // 食品列表
            Text.margin({ left: 16, top: 8, bottom: 8 });
        }, Text);
        // 食品列表
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const item = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.width('100%');
                    Row.padding(12);
                    Row.backgroundColor('#FFFFFF');
                    Row.borderRadius(8);
                    Row.margin({ left: 16, right: 16, bottom: 4 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.alignItems(HorizontalAlign.Start);
                    Column.layoutWeight(1);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(item.foodName);
                    Text.fontSize(14);
                    Text.fontWeight(FontWeight.Medium);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.margin({ top: 4 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (item.isHighSodium()) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('高盐');
                                Text.fontSize(11);
                                Text.fontColor('#FFFFFF');
                                Text.backgroundColor('#FF5722');
                                Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                                Text.borderRadius(8);
                                Text.margin({ right: 4 });
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
                    if (item.isHighSugar()) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('高糖');
                                Text.fontSize(11);
                                Text.fontColor('#FFFFFF');
                                Text.backgroundColor('#FF9800');
                                Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                                Text.borderRadius(8);
                                Text.margin({ right: 4 });
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
                    if (item.isHighFat()) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('高脂');
                                Text.fontSize(11);
                                Text.fontColor('#FFFFFF');
                                Text.backgroundColor('#F44336');
                                Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                                Text.borderRadius(8);
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
                Column.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, this.basketItems, forEachItemGenFunction, (item: FoodLabel) => item.foodId, false, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 继续扫描按钮
            Button.createWithLabel('继续扫描添加');
            // 继续扫描按钮
            Button.width('90%');
            // 继续扫描按钮
            Button.height(48);
            // 继续扫描按钮
            Button.backgroundColor('#1976D2');
            // 继续扫描按钮
            Button.borderRadius(24);
            // 继续扫描按钮
            Button.margin({ top: 16, bottom: 32 });
            // 继续扫描按钮
            Button.onClick(() => {
                router.pushUrl({ url: 'pages/ScanPage' });
            });
        }, Button);
        // 继续扫描按钮
        Button.pop();
        Column.pop();
        Scroll.pop();
    }
    private createFallbackBasket(): FoodLabel[] {
        const items: FoodLabel[] = [];
        const now = Date.now();
        const item1 = new FoodLabel();
        item1.foodId = 'b1';
        item1.foodName = '即食鸡爪（香辣味）';
        item1.nutrition = new NutritionPer100g();
        item1.nutrition.sodium = 1200;
        item1.nutrition.sugar = 3;
        item1.nutrition.calories = 230;
        item1.nutrition.fat = 12;
        item1.nutrition.saturatedFat = 3;
        item1.nutrition.carbohydrate = 8;
        item1.nutrition.protein = 15;
        item1.ingredients = ['鸡爪', '食用盐', '酱油'];
        item1.source = FoodSource.USER_UPLOAD;
        item1.identifiedAt = now;
        items.push(item1);
        const item2 = new FoodLabel();
        item2.foodId = 'b2';
        item2.foodName = '儿童酸奶';
        item2.nutrition = new NutritionPer100g();
        item2.nutrition.sodium = 80;
        item2.nutrition.sugar = 18;
        item2.nutrition.calories = 90;
        item2.nutrition.fat = 3;
        item2.nutrition.saturatedFat = 1.5;
        item2.nutrition.carbohydrate = 15;
        item2.nutrition.protein = 3;
        item2.ingredients = ['生牛乳', '白砂糖', '果胶'];
        item2.source = FoodSource.USER_UPLOAD;
        item2.identifiedAt = now;
        items.push(item2);
        const item3 = new FoodLabel();
        item3.foodId = 'b3';
        item3.foodName = '火锅底料（牛油麻辣）';
        item3.nutrition = new NutritionPer100g();
        item3.nutrition.sodium = 3500;
        item3.nutrition.sugar = 5;
        item3.nutrition.calories = 450;
        item3.nutrition.fat = 35;
        item3.nutrition.saturatedFat = 18;
        item3.nutrition.carbohydrate = 10;
        item3.nutrition.protein = 5;
        item3.ingredients = ['牛油', '辣椒', '食用盐', '花椒'];
        item3.source = FoodSource.USER_UPLOAD;
        item3.identifiedAt = now;
        items.push(item3);
        return items;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "BasketCheckPage";
    }
}
registerNamedRoute(() => new BasketCheckPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/BasketCheckPage", pageFullPath: "entry/src/main/ets/pages/BasketCheckPage", integratedHsp: "false", moduleType: "followWithHap" });

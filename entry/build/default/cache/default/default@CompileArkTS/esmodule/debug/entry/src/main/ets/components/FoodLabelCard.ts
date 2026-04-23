if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface FoodLabelCard_Params {
    foodLabel?: FoodLabel;
}
import { FoodLabel } from "@bundle:com.familyfood.helper/entry/ets/model/FoodLabel";
export class FoodLabelCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__foodLabel = new SynchedPropertyObjectOneWayPU(params.foodLabel, this, "foodLabel");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: FoodLabelCard_Params) {
        if (params.foodLabel === undefined) {
            this.__foodLabel.set(new FoodLabel());
        }
    }
    updateStateVars(params: FoodLabelCard_Params) {
        this.__foodLabel.reset(params.foodLabel);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__foodLabel.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__foodLabel.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __foodLabel: SynchedPropertySimpleOneWayPU<FoodLabel>;
    get foodLabel() {
        return this.__foodLabel.get();
    }
    set foodLabel(newValue: FoodLabel) {
        this.__foodLabel.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(12);
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 食品名称
            Text.create(this.foodLabel.foodName);
            // 食品名称
            Text.fontSize(18);
            // 食品名称
            Text.fontWeight(FontWeight.Bold);
            // 食品名称
            Text.fontColor('#212121');
            // 食品名称
            Text.margin({ bottom: 12 });
        }, Text);
        // 食品名称
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 营养成分网格
            Text.create('营养成分（每100g）');
            // 营养成分网格
            Text.fontSize(13);
            // 营养成分网格
            Text.fontColor('#757575');
            // 营养成分网格
            Text.margin({ bottom: 6 });
        }, Text);
        // 营养成分网格
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Grid.create();
            Grid.columnsTemplate('1fr 1fr 1fr');
            Grid.rowsGap(6);
            Grid.columnsGap(6);
            Grid.width('100%');
            Grid.margin({ bottom: 12 });
        }, Grid);
        {
            const itemCreation2 = (elmtId, isInitialRender) => {
                GridItem.create(() => { }, false);
            };
            const observedDeepRender = () => {
                this.observeComponentCreation2(itemCreation2, GridItem);
                this.NutritionItem.bind(this)('钠', `${this.foodLabel.nutrition.sodium}mg`, this.foodLabel.isHighSodium());
                GridItem.pop();
            };
            observedDeepRender();
        }
        {
            const itemCreation2 = (elmtId, isInitialRender) => {
                GridItem.create(() => { }, false);
            };
            const observedDeepRender = () => {
                this.observeComponentCreation2(itemCreation2, GridItem);
                this.NutritionItem.bind(this)('糖', `${this.foodLabel.nutrition.sugar}g`, this.foodLabel.isHighSugar());
                GridItem.pop();
            };
            observedDeepRender();
        }
        {
            const itemCreation2 = (elmtId, isInitialRender) => {
                GridItem.create(() => { }, false);
            };
            const observedDeepRender = () => {
                this.observeComponentCreation2(itemCreation2, GridItem);
                this.NutritionItem.bind(this)('热量', `${this.foodLabel.nutrition.calories}kcal`, this.foodLabel.isHighCalorie());
                GridItem.pop();
            };
            observedDeepRender();
        }
        {
            const itemCreation2 = (elmtId, isInitialRender) => {
                GridItem.create(() => { }, false);
            };
            const observedDeepRender = () => {
                this.observeComponentCreation2(itemCreation2, GridItem);
                this.NutritionItem.bind(this)('脂肪', `${this.foodLabel.nutrition.fat}g`, this.foodLabel.isHighFat());
                GridItem.pop();
            };
            observedDeepRender();
        }
        {
            const itemCreation2 = (elmtId, isInitialRender) => {
                GridItem.create(() => { }, false);
            };
            const observedDeepRender = () => {
                this.observeComponentCreation2(itemCreation2, GridItem);
                this.NutritionItem.bind(this)('碳水', `${this.foodLabel.nutrition.carbohydrate}g`, false);
                GridItem.pop();
            };
            observedDeepRender();
        }
        {
            const itemCreation2 = (elmtId, isInitialRender) => {
                GridItem.create(() => { }, false);
            };
            const observedDeepRender = () => {
                this.observeComponentCreation2(itemCreation2, GridItem);
                this.NutritionItem.bind(this)('蛋白质', `${this.foodLabel.nutrition.protein}g`, false);
                GridItem.pop();
            };
            observedDeepRender();
        }
        Grid.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 配料表
            if (this.foodLabel.ingredients.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('配料');
                        Text.fontSize(13);
                        Text.fontColor('#757575');
                        Text.margin({ bottom: 4 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.foodLabel.ingredients.join('、'));
                        Text.fontSize(12);
                        Text.fontColor('#616161');
                        Text.maxLines(3);
                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
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
    NutritionItem(name: string, value: string, isHigh: boolean, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding(8);
            Column.backgroundColor(isHigh ? '#FFF3E0' : '#F5F5F5');
            Column.borderRadius(8);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(name);
            Text.fontSize(11);
            Text.fontColor('#9E9E9E');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(value);
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(isHigh ? '#FF5722' : '#212121');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}

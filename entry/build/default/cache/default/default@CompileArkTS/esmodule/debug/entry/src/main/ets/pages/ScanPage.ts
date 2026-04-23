if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ScanPage_Params {
    scanMode?: string;
    foodLabel?: FoodLabel;
    isRecognizing?: boolean;
    showEditPanel?: boolean;
    scanLimitReached?: boolean;
    remainingScans?: number;
    recognizedText?: string;
    recognitionHint?: string;
    ocrConfidence?: number;
    editFoodName?: string;
    editSodium?: string;
    editSugar?: string;
    editCalories?: string;
    editFat?: string;
    editCarbohydrate?: string;
    editProtein?: string;
    editIngredients?: string;
    editManufacturer?: string;
    editScNumber?: string;
    editPrincipal?: string;
    editTrustee?: string;
    memberId?: string;
    appState?: AppState;
    foodInputService?: FoodInputService;
}
import type common from "@ohos:app.ability.common";
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { FoodLabel } from "@bundle:com.familyfood.helper/entry/ets/model/FoodLabel";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import { FoodInputService } from "@bundle:com.familyfood.helper/entry/ets/service/FoodInputService";
import type { FoodInputResult } from "@bundle:com.familyfood.helper/entry/ets/service/FoodInputService";
import { SubscriptionTier } from "@bundle:com.familyfood.helper/entry/ets/model/PricingModel";
class ScanPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__scanMode = new ObservedPropertySimplePU('camera', this, "scanMode");
        this.__foodLabel = new ObservedPropertyObjectPU(new FoodLabel(), this, "foodLabel");
        this.__isRecognizing = new ObservedPropertySimplePU(false, this, "isRecognizing");
        this.__showEditPanel = new ObservedPropertySimplePU(false, this, "showEditPanel");
        this.__scanLimitReached = new ObservedPropertySimplePU(false, this, "scanLimitReached");
        this.__remainingScans = new ObservedPropertySimplePU(3, this, "remainingScans");
        this.__recognizedText = new ObservedPropertySimplePU('', this, "recognizedText");
        this.__recognitionHint = new ObservedPropertySimplePU('', this, "recognitionHint");
        this.__ocrConfidence = new ObservedPropertySimplePU(1, this, "ocrConfidence");
        this.__editFoodName = new ObservedPropertySimplePU('', this, "editFoodName");
        this.__editSodium = new ObservedPropertySimplePU('0', this, "editSodium");
        this.__editSugar = new ObservedPropertySimplePU('0', this, "editSugar");
        this.__editCalories = new ObservedPropertySimplePU('0', this, "editCalories");
        this.__editFat = new ObservedPropertySimplePU('0', this, "editFat");
        this.__editCarbohydrate = new ObservedPropertySimplePU('0', this, "editCarbohydrate");
        this.__editProtein = new ObservedPropertySimplePU('0', this, "editProtein");
        this.__editIngredients = new ObservedPropertySimplePU('', this, "editIngredients");
        this.__editManufacturer = new ObservedPropertySimplePU('', this, "editManufacturer");
        this.__editScNumber = new ObservedPropertySimplePU('', this, "editScNumber");
        this.__editPrincipal = new ObservedPropertySimplePU('', this, "editPrincipal");
        this.__editTrustee = new ObservedPropertySimplePU('', this, "editTrustee");
        this.memberId = '';
        this.appState = AppState.getInstance();
        this.foodInputService = new FoodInputService();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ScanPage_Params) {
        if (params.scanMode !== undefined) {
            this.scanMode = params.scanMode;
        }
        if (params.foodLabel !== undefined) {
            this.foodLabel = params.foodLabel;
        }
        if (params.isRecognizing !== undefined) {
            this.isRecognizing = params.isRecognizing;
        }
        if (params.showEditPanel !== undefined) {
            this.showEditPanel = params.showEditPanel;
        }
        if (params.scanLimitReached !== undefined) {
            this.scanLimitReached = params.scanLimitReached;
        }
        if (params.remainingScans !== undefined) {
            this.remainingScans = params.remainingScans;
        }
        if (params.recognizedText !== undefined) {
            this.recognizedText = params.recognizedText;
        }
        if (params.recognitionHint !== undefined) {
            this.recognitionHint = params.recognitionHint;
        }
        if (params.ocrConfidence !== undefined) {
            this.ocrConfidence = params.ocrConfidence;
        }
        if (params.editFoodName !== undefined) {
            this.editFoodName = params.editFoodName;
        }
        if (params.editSodium !== undefined) {
            this.editSodium = params.editSodium;
        }
        if (params.editSugar !== undefined) {
            this.editSugar = params.editSugar;
        }
        if (params.editCalories !== undefined) {
            this.editCalories = params.editCalories;
        }
        if (params.editFat !== undefined) {
            this.editFat = params.editFat;
        }
        if (params.editCarbohydrate !== undefined) {
            this.editCarbohydrate = params.editCarbohydrate;
        }
        if (params.editProtein !== undefined) {
            this.editProtein = params.editProtein;
        }
        if (params.editIngredients !== undefined) {
            this.editIngredients = params.editIngredients;
        }
        if (params.editManufacturer !== undefined) {
            this.editManufacturer = params.editManufacturer;
        }
        if (params.editScNumber !== undefined) {
            this.editScNumber = params.editScNumber;
        }
        if (params.editPrincipal !== undefined) {
            this.editPrincipal = params.editPrincipal;
        }
        if (params.editTrustee !== undefined) {
            this.editTrustee = params.editTrustee;
        }
        if (params.memberId !== undefined) {
            this.memberId = params.memberId;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
        if (params.foodInputService !== undefined) {
            this.foodInputService = params.foodInputService;
        }
    }
    updateStateVars(params: ScanPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__scanMode.purgeDependencyOnElmtId(rmElmtId);
        this.__foodLabel.purgeDependencyOnElmtId(rmElmtId);
        this.__isRecognizing.purgeDependencyOnElmtId(rmElmtId);
        this.__showEditPanel.purgeDependencyOnElmtId(rmElmtId);
        this.__scanLimitReached.purgeDependencyOnElmtId(rmElmtId);
        this.__remainingScans.purgeDependencyOnElmtId(rmElmtId);
        this.__recognizedText.purgeDependencyOnElmtId(rmElmtId);
        this.__recognitionHint.purgeDependencyOnElmtId(rmElmtId);
        this.__ocrConfidence.purgeDependencyOnElmtId(rmElmtId);
        this.__editFoodName.purgeDependencyOnElmtId(rmElmtId);
        this.__editSodium.purgeDependencyOnElmtId(rmElmtId);
        this.__editSugar.purgeDependencyOnElmtId(rmElmtId);
        this.__editCalories.purgeDependencyOnElmtId(rmElmtId);
        this.__editFat.purgeDependencyOnElmtId(rmElmtId);
        this.__editCarbohydrate.purgeDependencyOnElmtId(rmElmtId);
        this.__editProtein.purgeDependencyOnElmtId(rmElmtId);
        this.__editIngredients.purgeDependencyOnElmtId(rmElmtId);
        this.__editManufacturer.purgeDependencyOnElmtId(rmElmtId);
        this.__editScNumber.purgeDependencyOnElmtId(rmElmtId);
        this.__editPrincipal.purgeDependencyOnElmtId(rmElmtId);
        this.__editTrustee.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__scanMode.aboutToBeDeleted();
        this.__foodLabel.aboutToBeDeleted();
        this.__isRecognizing.aboutToBeDeleted();
        this.__showEditPanel.aboutToBeDeleted();
        this.__scanLimitReached.aboutToBeDeleted();
        this.__remainingScans.aboutToBeDeleted();
        this.__recognizedText.aboutToBeDeleted();
        this.__recognitionHint.aboutToBeDeleted();
        this.__ocrConfidence.aboutToBeDeleted();
        this.__editFoodName.aboutToBeDeleted();
        this.__editSodium.aboutToBeDeleted();
        this.__editSugar.aboutToBeDeleted();
        this.__editCalories.aboutToBeDeleted();
        this.__editFat.aboutToBeDeleted();
        this.__editCarbohydrate.aboutToBeDeleted();
        this.__editProtein.aboutToBeDeleted();
        this.__editIngredients.aboutToBeDeleted();
        this.__editManufacturer.aboutToBeDeleted();
        this.__editScNumber.aboutToBeDeleted();
        this.__editPrincipal.aboutToBeDeleted();
        this.__editTrustee.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __scanMode: ObservedPropertySimplePU<string>;
    get scanMode() {
        return this.__scanMode.get();
    }
    set scanMode(newValue: string) {
        this.__scanMode.set(newValue);
    }
    private __foodLabel: ObservedPropertyObjectPU<FoodLabel>;
    get foodLabel() {
        return this.__foodLabel.get();
    }
    set foodLabel(newValue: FoodLabel) {
        this.__foodLabel.set(newValue);
    }
    private __isRecognizing: ObservedPropertySimplePU<boolean>;
    get isRecognizing() {
        return this.__isRecognizing.get();
    }
    set isRecognizing(newValue: boolean) {
        this.__isRecognizing.set(newValue);
    }
    private __showEditPanel: ObservedPropertySimplePU<boolean>;
    get showEditPanel() {
        return this.__showEditPanel.get();
    }
    set showEditPanel(newValue: boolean) {
        this.__showEditPanel.set(newValue);
    }
    private __scanLimitReached: ObservedPropertySimplePU<boolean>;
    get scanLimitReached() {
        return this.__scanLimitReached.get();
    }
    set scanLimitReached(newValue: boolean) {
        this.__scanLimitReached.set(newValue);
    }
    private __remainingScans: ObservedPropertySimplePU<number>;
    get remainingScans() {
        return this.__remainingScans.get();
    }
    set remainingScans(newValue: number) {
        this.__remainingScans.set(newValue);
    }
    private __recognizedText: ObservedPropertySimplePU<string>;
    get recognizedText() {
        return this.__recognizedText.get();
    }
    set recognizedText(newValue: string) {
        this.__recognizedText.set(newValue);
    }
    private __recognitionHint: ObservedPropertySimplePU<string>;
    get recognitionHint() {
        return this.__recognitionHint.get();
    }
    set recognitionHint(newValue: string) {
        this.__recognitionHint.set(newValue);
    }
    private __ocrConfidence: ObservedPropertySimplePU<number>;
    get ocrConfidence() {
        return this.__ocrConfidence.get();
    }
    set ocrConfidence(newValue: number) {
        this.__ocrConfidence.set(newValue);
    }
    private __editFoodName: ObservedPropertySimplePU<string>;
    get editFoodName() {
        return this.__editFoodName.get();
    }
    set editFoodName(newValue: string) {
        this.__editFoodName.set(newValue);
    }
    private __editSodium: ObservedPropertySimplePU<string>;
    get editSodium() {
        return this.__editSodium.get();
    }
    set editSodium(newValue: string) {
        this.__editSodium.set(newValue);
    }
    private __editSugar: ObservedPropertySimplePU<string>;
    get editSugar() {
        return this.__editSugar.get();
    }
    set editSugar(newValue: string) {
        this.__editSugar.set(newValue);
    }
    private __editCalories: ObservedPropertySimplePU<string>;
    get editCalories() {
        return this.__editCalories.get();
    }
    set editCalories(newValue: string) {
        this.__editCalories.set(newValue);
    }
    private __editFat: ObservedPropertySimplePU<string>;
    get editFat() {
        return this.__editFat.get();
    }
    set editFat(newValue: string) {
        this.__editFat.set(newValue);
    }
    private __editCarbohydrate: ObservedPropertySimplePU<string>;
    get editCarbohydrate() {
        return this.__editCarbohydrate.get();
    }
    set editCarbohydrate(newValue: string) {
        this.__editCarbohydrate.set(newValue);
    }
    private __editProtein: ObservedPropertySimplePU<string>;
    get editProtein() {
        return this.__editProtein.get();
    }
    set editProtein(newValue: string) {
        this.__editProtein.set(newValue);
    }
    private __editIngredients: ObservedPropertySimplePU<string>;
    get editIngredients() {
        return this.__editIngredients.get();
    }
    set editIngredients(newValue: string) {
        this.__editIngredients.set(newValue);
    }
    private __editManufacturer: ObservedPropertySimplePU<string>;
    get editManufacturer() {
        return this.__editManufacturer.get();
    }
    set editManufacturer(newValue: string) {
        this.__editManufacturer.set(newValue);
    }
    private __editScNumber: ObservedPropertySimplePU<string>;
    get editScNumber() {
        return this.__editScNumber.get();
    }
    set editScNumber(newValue: string) {
        this.__editScNumber.set(newValue);
    }
    private __editPrincipal: ObservedPropertySimplePU<string>;
    get editPrincipal() {
        return this.__editPrincipal.get();
    }
    set editPrincipal(newValue: string) {
        this.__editPrincipal.set(newValue);
    }
    private __editTrustee: ObservedPropertySimplePU<string>;
    get editTrustee() {
        return this.__editTrustee.get();
    }
    set editTrustee(newValue: string) {
        this.__editTrustee.set(newValue);
    }
    private memberId: string;
    private appState: AppState;
    private foodInputService: FoodInputService;
    aboutToAppear() {
        const params = router.getParams() as Record<string, string>;
        if (params) {
            this.memberId = params.memberId || '';
        }
        this.refreshScanQuota();
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
            Text.create('识别食品标签');
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.ModeSelector.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.appState.getCurrentTier() === SubscriptionTier.FREE) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('100%');
                        Row.padding({ left: 16, right: 16 });
                        Row.margin({ bottom: 12 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.scanLimitReached ? '今日扫描次数已用完' : `今日剩余扫描：${this.remainingScans} 次`);
                        Text.fontSize(12);
                        Text.fontColor(this.scanLimitReached ? '#D32F2F' : '#F57C00');
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.ResultCard.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showEditPanel) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.EditPanel.bind(this)();
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
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Center);
            Column.margin({ top: 16, bottom: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.foodLabel.foodId.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.scanMode === 'barcode' ? '扫码录入' : '拍标签 / 生成草稿');
                        Button.width('90%');
                        Button.height(52);
                        Button.backgroundColor('#1976D2');
                        Button.borderRadius(26);
                        Button.onClick(() => { this.startRecognition(); });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('手动录入');
                        Button.width('90%');
                        Button.height(48);
                        Button.backgroundColor('#E3F2FD');
                        Button.fontColor('#1976D2');
                        Button.borderRadius(24);
                        Button.margin({ top: 10 });
                        Button.onClick(() => { this.startManualEntry(); });
                    }, Button);
                    Button.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('查看适配报告');
                        Button.width('90%');
                        Button.height(52);
                        Button.backgroundColor('#43A047');
                        Button.borderRadius(26);
                        Button.onClick(() => { this.viewReport(); });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.width('90%');
                        Row.margin({ top: 10 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.showEditPanel ? '收起修正面板' : '手动修正');
                        Button.layoutWeight(1);
                        Button.height(46);
                        Button.backgroundColor('#E3F2FD');
                        Button.fontColor('#1976D2');
                        Button.borderRadius(23);
                        Button.onClick(() => {
                            this.showEditPanel = !this.showEditPanel;
                            if (this.showEditPanel) {
                                this.loadEditFormFromLabel();
                            }
                        });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('保存 FoodLabel');
                        Button.layoutWeight(1);
                        Button.height(46);
                        Button.backgroundColor('#FFF3E0');
                        Button.fontColor('#EF6C00');
                        Button.borderRadius(23);
                        Button.margin({ left: 10 });
                        Button.onClick(() => { this.saveDraft(); });
                    }, Button);
                    Button.pop();
                    Row.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
        Column.pop();
        Scroll.pop();
    }
    ModeSelector(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.width('100%');
            Row.padding({ left: 16, right: 16 });
            Row.margin({ bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('拍标签');
            Text.fontSize(15);
            Text.padding({ left: 20, right: 20, top: 8, bottom: 8 });
            Text.borderRadius(20);
            Text.backgroundColor(this.scanMode === 'camera' ? '#1976D2' : '#FFFFFF');
            Text.fontColor(this.scanMode === 'camera' ? '#FFFFFF' : '#212121');
            Text.onClick(() => { this.scanMode = 'camera'; });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('扫码');
            Text.fontSize(15);
            Text.padding({ left: 20, right: 20, top: 8, bottom: 8 });
            Text.borderRadius(20);
            Text.backgroundColor(this.scanMode === 'barcode' ? '#1976D2' : '#FFFFFF');
            Text.fontColor(this.scanMode === 'barcode' ? '#FFFFFF' : '#212121');
            Text.margin({ left: 10 });
            Text.onClick(() => { this.scanMode = 'barcode'; });
        }, Text);
        Text.pop();
        Row.pop();
    }
    ResultCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.padding(20);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.isRecognizing) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        LoadingProgress.create();
                        LoadingProgress.width(40);
                        LoadingProgress.height(40);
                        LoadingProgress.color('#1976D2');
                    }, LoadingProgress);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('正在处理中...');
                        Text.fontSize(14);
                        Text.fontColor('#757575');
                        Text.margin({ top: 12 });
                    }, Text);
                    Text.pop();
                });
            }
            else if (this.foodLabel.foodId.length === 0) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('识别后会在这里生成一个可编辑的 FoodLabel 草稿');
                        Text.fontSize(15);
                        Text.fontColor('#616161');
                        Text.textAlign(TextAlign.Center);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('P0 版支持扫码命中本地库，或先生成草稿后手动修正');
                        Text.fontSize(12);
                        Text.fontColor('#9E9E9E');
                        Text.textAlign(TextAlign.Center);
                        Text.margin({ top: 8 });
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.foodLabel.foodName.length > 0 ? this.foodLabel.foodName : '待补充食品名称');
                        Text.fontSize(20);
                        Text.fontWeight(FontWeight.Bold);
                        Text.margin({ bottom: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.recognitionHint.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.recognitionHint);
                                    Text.fontSize(12);
                                    Text.fontColor('#1976D2');
                                    Text.textAlign(TextAlign.Center);
                                    Text.margin({ bottom: 6 });
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
                        if (this.recognizedText.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.recognizedText);
                                    Text.fontSize(12);
                                    Text.fontColor('#757575');
                                    Text.textAlign(TextAlign.Center);
                                    Text.margin({ bottom: 8 });
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
                        Row.create();
                        Row.width('100%');
                        Row.justifyContent(FlexAlign.SpaceAround);
                        Row.margin({ bottom: 8 });
                    }, Row);
                    this.MetricChip.bind(this)('钠', `${this.foodLabel.nutrition.sodium} mg`);
                    this.MetricChip.bind(this)('糖', `${this.foodLabel.nutrition.sugar} g`);
                    this.MetricChip.bind(this)('热量', `${this.foodLabel.nutrition.calories} kcal`);
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.foodLabel.barcode.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(`条码：${this.foodLabel.barcode}`);
                                    Text.fontSize(12);
                                    Text.fontColor('#616161');
                                    Text.margin({ bottom: 6 });
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
                        Text.create(this.showEditPanel ? '请核对下方字段后保存或查看报告' : '如信息不完整，可展开手动修正面板补全');
                        Text.fontSize(12);
                        Text.fontColor('#9E9E9E');
                        Text.textAlign(TextAlign.Center);
                    }, Text);
                    Text.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    MetricChip(label: string, value: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.padding(8);
            Column.backgroundColor('#F5F5F5');
            Column.borderRadius(10);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.fontSize(11);
            Text.fontColor('#9E9E9E');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(value);
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor('#212121');
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    EditPanel(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('92%');
            Column.padding(16);
            Column.backgroundColor('#FFFFFF');
            Column.borderRadius(16);
            Column.margin({ top: 14 });
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('手动修正');
            Text.fontSize(17);
            Text.fontWeight(FontWeight.Bold);
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.FormInput.bind(this)('食品名称', this.editFoodName, '输入食品名称', (value: string) => { this.editFoodName = value; });
        this.FormInput.bind(this)('钠（mg/100g）', this.editSodium, '0', (value: string) => { this.editSodium = value; });
        this.FormInput.bind(this)('糖（g/100g）', this.editSugar, '0', (value: string) => { this.editSugar = value; });
        this.FormInput.bind(this)('热量（kcal/100g）', this.editCalories, '0', (value: string) => { this.editCalories = value; });
        this.FormInput.bind(this)('脂肪（g/100g）', this.editFat, '0', (value: string) => { this.editFat = value; });
        this.FormInput.bind(this)('碳水（g/100g）', this.editCarbohydrate, '0', (value: string) => { this.editCarbohydrate = value; });
        this.FormInput.bind(this)('蛋白质（g/100g）', this.editProtein, '0', (value: string) => { this.editProtein = value; });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 12 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('配料');
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextArea.create({ text: this.editIngredients, placeholder: '一行一个，或用逗号分隔' });
            TextArea.width('100%');
            TextArea.height(100);
            TextArea.padding(10);
            TextArea.backgroundColor('#F7F8FA');
            TextArea.borderRadius(12);
            TextArea.onChange((value: string) => { this.editIngredients = value; });
        }, TextArea);
        Column.pop();
        this.FormInput.bind(this)('生产商', this.editManufacturer, '输入生产商', (value: string) => { this.editManufacturer = value; });
        this.FormInput.bind(this)('SC 编号', this.editScNumber, '输入 SC 编号', (value: string) => { this.editScNumber = value; });
        this.FormInput.bind(this)('委托方', this.editPrincipal, '输入委托方', (value: string) => { this.editPrincipal = value; });
        this.FormInput.bind(this)('受托方', this.editTrustee, '输入受托方', (value: string) => { this.editTrustee = value; });
        Column.pop();
    }
    FormInput(title: string, value: string, placeholder: string, onChange: (value: string) => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 12 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.fontSize(13);
            Text.fontColor('#757575');
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ text: value, placeholder });
            TextInput.width('100%');
            TextInput.height(44);
            TextInput.padding({ left: 12, right: 12 });
            TextInput.backgroundColor('#F7F8FA');
            TextInput.borderRadius(12);
            TextInput.onChange(onChange);
        }, TextInput);
        Column.pop();
    }
    private refreshScanQuota() {
        this.scanLimitReached = !this.appState.canScanToday();
        const remaining = this.appState.getRemainingScansToday();
        this.remainingScans = remaining === -1 ? 999 : remaining;
    }
    private startManualEntry() {
        this.applyFoodInputResult(this.foodInputService.createManualDraft());
    }
    private async startRecognition() {
        if (!this.appState.canScanToday()) {
            this.scanLimitReached = true;
            promptAction.showToast({ message: '今日扫描次数已用完' });
            return;
        }
        this.isRecognizing = true;
        try {
            if (this.scanMode === 'barcode') {
                const context = getContext(this) as common.Context;
                const result = await this.foodInputService.scanBarcode(context);
                if (result) {
                    this.applyFoodInputResult(result);
                }
            }
            else {
                this.applyFoodInputResult(this.foodInputService.createCameraDraft());
            }
            if (this.foodLabel.foodId.length > 0) {
                this.appState.recordScan();
            }
        }
        catch (error) {
            promptAction.showToast({ message: '识别失败，已切换到手动录入' });
            this.startManualEntry();
        }
        finally {
            this.isRecognizing = false;
            this.refreshScanQuota();
        }
    }
    private loadEditFormFromLabel() {
        this.editFoodName = this.foodLabel.foodName;
        this.editSodium = `${this.foodLabel.nutrition.sodium}`;
        this.editSugar = `${this.foodLabel.nutrition.sugar}`;
        this.editCalories = `${this.foodLabel.nutrition.calories}`;
        this.editFat = `${this.foodLabel.nutrition.fat}`;
        this.editCarbohydrate = `${this.foodLabel.nutrition.carbohydrate}`;
        this.editProtein = `${this.foodLabel.nutrition.protein}`;
        this.editIngredients = this.foodLabel.ingredients.join('\n');
        this.editManufacturer = this.foodLabel.manufacturer;
        this.editScNumber = this.foodLabel.scNumber;
        this.editPrincipal = this.foodLabel.principal;
        this.editTrustee = this.foodLabel.trustee;
    }
    private applyEditFormToLabel() {
        if (this.foodLabel.foodId.length === 0) {
            this.foodLabel.foodId = `food_${Date.now()}`;
        }
        if (this.foodLabel.identifiedAt <= 0) {
            this.foodLabel.identifiedAt = Date.now();
        }
        this.foodLabel.foodName = this.editFoodName.trim();
        this.foodLabel.nutrition.sodium = this.parseNumber(this.editSodium);
        this.foodLabel.nutrition.sugar = this.parseNumber(this.editSugar);
        this.foodLabel.nutrition.calories = this.parseNumber(this.editCalories);
        this.foodLabel.nutrition.fat = this.parseNumber(this.editFat);
        this.foodLabel.nutrition.carbohydrate = this.parseNumber(this.editCarbohydrate);
        this.foodLabel.nutrition.protein = this.parseNumber(this.editProtein);
        this.foodLabel.ingredients = this.editIngredients
            .split(/\r?\n|,|，|、/)
            .map(item => item.trim())
            .filter(item => item.length > 0);
        this.foodLabel.manufacturer = this.editManufacturer.trim();
        this.foodLabel.scNumber = this.editScNumber.trim();
        this.foodLabel.principal = this.editPrincipal.trim();
        this.foodLabel.trustee = this.editTrustee.trim();
    }
    private applyFoodInputResult(result: FoodInputResult) {
        this.foodLabel = result.foodLabel;
        this.recognizedText = result.recognizedText;
        this.recognitionHint = result.hint;
        this.ocrConfidence = result.confidence;
        this.showEditPanel = result.requiresManualReview;
        if (this.showEditPanel) {
            this.loadEditFormFromLabel();
        }
    }
    private parseNumber(value: string): number {
        const result = Number.parseFloat(value);
        return Number.isFinite(result) ? result : 0;
    }
    private async persistCurrentFoodLabel(showSuccessToast: boolean): Promise<boolean> {
        if (this.showEditPanel) {
            this.applyEditFormToLabel();
        }
        if (this.foodLabel.foodName.trim().length === 0) {
            promptAction.showToast({ message: '请先补全食品名称' });
            return false;
        }
        await this.appState.saveFoodLabel(this.foodLabel);
        if (showSuccessToast) {
            promptAction.showToast({ message: 'FoodLabel 已保存' });
        }
        return true;
    }
    private async saveDraft() {
        await this.persistCurrentFoodLabel(true);
    }
    private async viewReport() {
        const saved = await this.persistCurrentFoodLabel(false);
        if (!saved) {
            return;
        }
        router.pushUrl({
            url: 'pages/ReportPage',
            params: {
                memberId: this.memberId,
                foodId: this.foodLabel.foodId
            }
        });
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ScanPage";
    }
}
registerNamedRoute(() => new ScanPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/ScanPage", pageFullPath: "entry/src/main/ets/pages/ScanPage", integratedHsp: "false", moduleType: "followWithHap" });

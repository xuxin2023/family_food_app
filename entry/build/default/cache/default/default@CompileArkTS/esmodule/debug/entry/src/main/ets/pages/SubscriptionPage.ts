if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SubscriptionPage_Params {
    currentTier?: SubscriptionTier;
    products?: IapProduct[];
    isPurchasing?: boolean;
    selectedProductId?: string;
    appState?: AppState;
    iapService?: IapService;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppState } from "@bundle:com.familyfood.helper/entry/ets/AppState";
import { SubscriptionTier, PRICING_PLANS } from "@bundle:com.familyfood.helper/entry/ets/model/PricingModel";
import { IapService } from "@bundle:com.familyfood.helper/entry/ets/service/IapService";
import type { IapProduct, PurchaseResult } from "@bundle:com.familyfood.helper/entry/ets/service/IapService";
import { COLORS, RADIUS, SPACING, FONT_SIZE, FONT_WEIGHT } from "@bundle:com.familyfood.helper/entry/ets/constants/AppTheme";
class SubscriptionPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__currentTier = new ObservedPropertySimplePU(SubscriptionTier.FREE, this, "currentTier");
        this.__products = new ObservedPropertyObjectPU([], this, "products");
        this.__isPurchasing = new ObservedPropertySimplePU(false, this, "isPurchasing");
        this.__selectedProductId = new ObservedPropertySimplePU('', this, "selectedProductId");
        this.appState = AppState.getInstance();
        this.iapService = new IapService();
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SubscriptionPage_Params) {
        if (params.currentTier !== undefined) {
            this.currentTier = params.currentTier;
        }
        if (params.products !== undefined) {
            this.products = params.products;
        }
        if (params.isPurchasing !== undefined) {
            this.isPurchasing = params.isPurchasing;
        }
        if (params.selectedProductId !== undefined) {
            this.selectedProductId = params.selectedProductId;
        }
        if (params.appState !== undefined) {
            this.appState = params.appState;
        }
        if (params.iapService !== undefined) {
            this.iapService = params.iapService;
        }
    }
    updateStateVars(params: SubscriptionPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__currentTier.purgeDependencyOnElmtId(rmElmtId);
        this.__products.purgeDependencyOnElmtId(rmElmtId);
        this.__isPurchasing.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedProductId.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__currentTier.aboutToBeDeleted();
        this.__products.aboutToBeDeleted();
        this.__isPurchasing.aboutToBeDeleted();
        this.__selectedProductId.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __currentTier: ObservedPropertySimplePU<SubscriptionTier>;
    get currentTier() {
        return this.__currentTier.get();
    }
    set currentTier(newValue: SubscriptionTier) {
        this.__currentTier.set(newValue);
    }
    private __products: ObservedPropertyObjectPU<IapProduct[]>;
    get products() {
        return this.__products.get();
    }
    set products(newValue: IapProduct[]) {
        this.__products.set(newValue);
    }
    private __isPurchasing: ObservedPropertySimplePU<boolean>;
    get isPurchasing() {
        return this.__isPurchasing.get();
    }
    set isPurchasing(newValue: boolean) {
        this.__isPurchasing.set(newValue);
    }
    private __selectedProductId: ObservedPropertySimplePU<string>;
    get selectedProductId() {
        return this.__selectedProductId.get();
    }
    set selectedProductId(newValue: string) {
        this.__selectedProductId.set(newValue);
    }
    private appState: AppState;
    private iapService: IapService;
    async aboutToAppear() {
        this.currentTier = this.appState.getCurrentTier();
        this.products = await this.iapService.getAvailableProducts();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.linearGradient({
                direction: GradientDirection.Bottom,
                colors: [[COLORS.BG_GRADIENT_START, 0], [COLORS.BG_GRADIENT_END, 1]]
            });
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
            Text.create('←');
            Text.fontSize(FONT_SIZE.LARGE);
            Text.fontColor(COLORS.PRIMARY);
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('升级家庭版');
            Text.fontSize(FONT_SIZE.TITLE_LG);
            Text.fontWeight(FONT_WEIGHT.BOLD);
            Text.fontColor(COLORS.TEXT_PRIMARY);
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('90%');
            Column.padding(SPACING.LG);
            Column.backgroundColor(COLORS.BG_CARD);
            Column.borderRadius(RADIUS.LG);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ bottom: 16 });
            Column.shadow({ radius: 8, color: COLORS.SHADOW_LIGHT, offsetX: 0, offsetY: 2 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('为什么升级？');
            Text.fontSize(FONT_SIZE.SUBTITLE);
            Text.fontWeight(FONT_WEIGHT.BOLD);
            Text.fontColor(COLORS.TEXT_PRIMARY);
            Text.margin({ bottom: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('免费版每天只能扫3次，只有1个家庭成员。');
            Text.fontSize(FONT_SIZE.BODY);
            Text.fontColor(COLORS.TEXT_SECONDARY);
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('升级后，爸爸/妈妈/孩子/我，每个人都有专属建议。');
            Text.fontSize(FONT_SIZE.BODY);
            Text.fontColor(COLORS.TEXT_SECONDARY);
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('卖的不是"无限扫码"，而是"更懂你家每个人"。');
            Text.fontSize(FONT_SIZE.BODY);
            Text.fontWeight(FONT_WEIGHT.MEDIUM);
            Text.fontColor(COLORS.PRIMARY_DARK);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const plan = _item;
                this.PlanCard.bind(this)(plan, index);
            };
            this.forEachUpdateFunction(elmtId, PRICING_PLANS, forEachItemGenFunction, (plan: SubscriptionPlan, index: number) => `${index}`, true, true);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.currentTier !== SubscriptionTier.FREE) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.margin({ top: 12, bottom: 24 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('🔄 恢复购买');
                        Text.fontSize(FONT_SIZE.BODY);
                        Text.fontColor(COLORS.ACCENT_BLUE);
                        Text.onClick(() => { this.handleRestore(); });
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
        Column.pop();
        Scroll.pop();
    }
    PlanCard(plan: SubscriptionPlan, index: number, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('90%');
            Column.padding(SPACING.LG);
            Column.backgroundColor(index === 1 ? COLORS.BG_CARD_HIGHLIGHT : COLORS.BG_CARD);
            Column.borderRadius(RADIUS.LG);
            Column.margin({ bottom: 12 });
            Column.alignItems(HorizontalAlign.Start);
            Column.border(index === 1 ? { width: 2, color: COLORS.PRIMARY } : undefined);
            Column.shadow({ radius: 6, color: COLORS.SHADOW_LIGHT, offsetX: 0, offsetY: 2 });
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
            Text.create(plan.tier);
            Text.fontSize(FONT_SIZE.TITLE);
            Text.fontWeight(FONT_WEIGHT.BOLD);
            Text.fontColor(COLORS.TEXT_PRIMARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(plan.price + (plan.isYearly ? '/年' : ''));
            Text.fontSize(FONT_SIZE.SUBTITLE);
            Text.fontColor(COLORS.PRIMARY_DARK);
            Text.fontWeight(FONT_WEIGHT.MEDIUM);
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.currentTier === plan.tier) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('当前');
                        Text.fontSize(FONT_SIZE.SMALL);
                        Text.fontColor(COLORS.TEXT_WHITE);
                        Text.padding({ left: 12, right: 12, top: 4, bottom: 4 });
                        Text.backgroundColor(COLORS.SUCCESS);
                        Text.borderRadius(RADIUS.SM);
                    }, Text);
                    Text.pop();
                });
            }
            else if (index === 1) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('推荐');
                        Text.fontSize(FONT_SIZE.SMALL);
                        Text.fontColor(COLORS.TEXT_WHITE);
                        Text.padding({ left: 12, right: 12, top: 4, bottom: 4 });
                        Text.backgroundColor(COLORS.PRIMARY);
                        Text.borderRadius(RADIUS.SM);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                });
            }
        }, If);
        If.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.width('100%');
            Column.margin({ top: 12 });
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const feature = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.margin({ bottom: 4 });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('✓');
                    Text.fontSize(FONT_SIZE.BODY);
                    Text.fontColor(COLORS.SUCCESS);
                    Text.margin({ right: 8 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(feature);
                    Text.fontSize(FONT_SIZE.BODY);
                    Text.fontColor(COLORS.TEXT_SECONDARY);
                }, Text);
                Text.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, plan.features, forEachItemGenFunction, (feature: string) => feature, false, false);
        }, ForEach);
        ForEach.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.currentTier !== plan.tier && index > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.isPurchasing && this.selectedProductId === this.getProductId(plan.tier)
                            ? '处理中...' : '立即订阅');
                        Button.width('100%');
                        Button.height(44);
                        Button.backgroundColor(COLORS.PRIMARY);
                        Button.fontColor(COLORS.TEXT_WHITE);
                        Button.borderRadius(RADIUS.XXL);
                        Button.fontSize(FONT_SIZE.BODY);
                        Button.margin({ top: 12 });
                        Button.enabled(!this.isPurchasing);
                        Button.onClick(() => { this.handlePurchase(plan.tier); });
                    }, Button);
                    Button.pop();
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
    private getProductId(tier: SubscriptionTier): string {
        const map: Map<string, string> = new Map([
            [SubscriptionTier.TRIAL_7DAY, 'com.familyfood.trial_7day'],
            [SubscriptionTier.PERSONAL_YEAR, 'com.familyfood.personal_year'],
            [SubscriptionTier.FAMILY_EARLY, 'com.familyfood.family_early'],
            [SubscriptionTier.FAMILY_STANDARD, 'com.familyfood.family_standard'],
            [SubscriptionTier.FAMILY_PREMIUM, 'com.familyfood.family_premium']
        ]);
        return map.get(tier) || '';
    }
    private async handlePurchase(tier: SubscriptionTier) {
        const productId = this.getProductId(tier);
        if (productId.length === 0)
            return;
        this.isPurchasing = true;
        this.selectedProductId = productId;
        const result: PurchaseResult = await this.iapService.purchase(productId);
        if (result.success) {
            this.appState.setTier(result.tier);
            this.currentTier = result.tier;
            promptAction.showToast({ message: '订阅成功！感谢支持 🎉' });
            setTimeout(() => { router.back(); }, 1500);
        }
        else {
            promptAction.showToast({ message: result.message });
        }
        this.isPurchasing = false;
        this.selectedProductId = '';
    }
    private async handleRestore() {
        promptAction.showToast({ message: '正在恢复购买记录...' });
        const tier = await this.iapService.verifyAndRestorePurchases();
        if (tier !== SubscriptionTier.FREE) {
            this.appState.setTier(tier);
            this.currentTier = tier;
            promptAction.showToast({ message: '已恢复订阅：' + tier });
        }
        else {
            promptAction.showToast({ message: '未找到有效订阅记录' });
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SubscriptionPage";
    }
}
class SubscriptionPlan {
    tier: SubscriptionTier = SubscriptionTier.FREE;
    price: string = '';
    priceValue: number = 0;
    isYearly: boolean = false;
    features: string[] = [];
    limitations: string[] = [];
}
registerNamedRoute(() => new SubscriptionPage(undefined, {}), "", { bundleName: "com.familyfood.helper", moduleName: "entry", pagePath: "pages/SubscriptionPage", pageFullPath: "entry/src/main/ets/pages/SubscriptionPage", integratedHsp: "false", moduleType: "followWithHap" });

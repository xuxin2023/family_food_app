import hilog from "@ohos:hilog";
import preferences from "@ohos:data.preferences";
import type common from "@ohos:app.ability.common";
import { SubscriptionTier, PricingService } from "@bundle:com.familyfood.helper/entry/ets/model/PricingModel";
const TAG = 'IapService';
const DOMAIN_ZERO = 0;
export enum IapProductId {
    TRIAL_7DAY = "com.familyfood.trial_7day",
    PERSONAL_YEAR = "com.familyfood.personal_year",
    FAMILY_EARLY = "com.familyfood.family_early",
    FAMILY_STANDARD = "com.familyfood.family_standard",
    FAMILY_PREMIUM = "com.familyfood.family_premium"
}
const PRODUCT_ID_TO_TIER: Map<string, SubscriptionTier> = new Map([
    [IapProductId.TRIAL_7DAY, SubscriptionTier.TRIAL_7DAY],
    [IapProductId.PERSONAL_YEAR, SubscriptionTier.PERSONAL_YEAR],
    [IapProductId.FAMILY_EARLY, SubscriptionTier.FAMILY_EARLY],
    [IapProductId.FAMILY_STANDARD, SubscriptionTier.FAMILY_STANDARD],
    [IapProductId.FAMILY_PREMIUM, SubscriptionTier.FAMILY_PREMIUM]
]);
const TIER_TO_PRODUCT_ID: Map<string, IapProductId> = new Map([
    [SubscriptionTier.TRIAL_7DAY, IapProductId.TRIAL_7DAY],
    [SubscriptionTier.PERSONAL_YEAR, IapProductId.PERSONAL_YEAR],
    [SubscriptionTier.FAMILY_EARLY, IapProductId.FAMILY_EARLY],
    [SubscriptionTier.FAMILY_STANDARD, IapProductId.FAMILY_STANDARD],
    [SubscriptionTier.FAMILY_PREMIUM, IapProductId.FAMILY_PREMIUM]
]);
export interface IapProduct {
    productId: string;
    title: string;
    description: string;
    price: string;
    priceValue: number;
    isSubscription: boolean;
    tier: SubscriptionTier;
}
export interface PurchaseResult {
    success: boolean;
    tier: SubscriptionTier;
    orderId: string;
    purchaseToken: string;
    message: string;
}
export class IapService {
    private context: common.Context | null = null;
    private isInitialized: boolean = false;
    async init(context: common.Context): Promise<void> {
        this.context = context;
        this.isInitialized = true;
        hilog.info(DOMAIN_ZERO, TAG, 'IAP service initialized');
    }
    async getAvailableProducts(): Promise<IapProduct[]> {
        const products: IapProduct[] = [];
        const plans = PricingService.getAllPlans();
        for (let i = 1; i < plans.length; i++) {
            const plan = plans[i];
            const productId = TIER_TO_PRODUCT_ID.get(plan.tier);
            if (productId) {
                products.push({
                    productId: productId,
                    title: plan.tier,
                    description: plan.features.join('、'),
                    price: plan.price,
                    priceValue: plan.priceValue,
                    isSubscription: plan.isYearly,
                    tier: plan.tier
                });
            }
        }
        return products;
    }
    async purchase(productId: string): Promise<PurchaseResult> {
        if (!this.context) {
            return this.failResult('服务未初始化');
        }
        hilog.info(DOMAIN_ZERO, TAG, 'Purchase request: %{public}s', productId);
        try {
            // P0版本：使用模拟购买，不依赖IAP Kit
            // IAP Kit集成将在后续版本中实现
            const tier = PRODUCT_ID_TO_TIER.get(productId) || SubscriptionTier.FREE;
            await this.savePurchaseRecord(productId, 'mock_order_' + Date.now(), 'mock_token_' + Date.now(), tier);
            hilog.info(DOMAIN_ZERO, TAG, 'Purchase success (mock): %{public}s -> %{public}s', productId, tier);
            return {
                success: true,
                tier: tier,
                orderId: 'mock_order_' + Date.now(),
                purchaseToken: 'mock_token_' + Date.now(),
                message: '购买成功'
            };
        }
        catch (error) {
            hilog.error(DOMAIN_ZERO, TAG, 'Purchase failed: %{public}s', JSON.stringify(error));
            const errMsg = this.parseIapError(error);
            return this.failResult(errMsg);
        }
    }
    async verifyAndRestorePurchases(): Promise<SubscriptionTier> {
        if (!this.context) {
            return SubscriptionTier.FREE;
        }
        try {
            // P0版本：从本地存储恢复购买记录
            const savedTier = await this.getSavedPurchaseTier();
            hilog.info(DOMAIN_ZERO, TAG, 'Restored purchases (mock), tier: %{public}s', savedTier);
            return savedTier;
        }
        catch (error) {
            hilog.warn(DOMAIN_ZERO, TAG, 'Restore purchases failed: %{public}s', JSON.stringify(error));
            return SubscriptionTier.FREE;
        }
    }
    async savePurchaseRecord(productId: string, orderId: string, purchaseToken: string, tier: SubscriptionTier): Promise<void> {
        if (!this.context)
            return;
        try {
            const prefs = await preferences.getPreferences(this.context, 'iap_records');
            prefs.putSync('active_product_id', productId);
            prefs.putSync('active_order_id', orderId);
            prefs.putSync('active_purchase_token', purchaseToken);
            prefs.putSync('active_tier', tier);
            prefs.putSync('purchase_time', Date.now().toString());
            await prefs.flush();
            hilog.info(DOMAIN_ZERO, TAG, 'Purchase record saved');
        }
        catch (error) {
            hilog.warn(DOMAIN_ZERO, TAG, 'Save purchase record failed: %{public}s', JSON.stringify(error));
        }
    }
    async getSavedPurchaseTier(): Promise<SubscriptionTier> {
        if (!this.context)
            return SubscriptionTier.FREE;
        try {
            const prefs = await preferences.getPreferences(this.context, 'iap_records');
            const tierStr = prefs.getSync('active_tier', SubscriptionTier.FREE) as string;
            const tierEntries: string[] = [
                SubscriptionTier.FREE, SubscriptionTier.TRIAL_7DAY,
                SubscriptionTier.PERSONAL_YEAR, SubscriptionTier.FAMILY_EARLY,
                SubscriptionTier.FAMILY_STANDARD, SubscriptionTier.FAMILY_PREMIUM
            ];
            for (const entry of tierEntries) {
                if (entry === tierStr)
                    return entry as SubscriptionTier;
            }
            return SubscriptionTier.FREE;
        }
        catch (error) {
            return SubscriptionTier.FREE;
        }
    }
    private failResult(message: string): PurchaseResult {
        return {
            success: false,
            tier: SubscriptionTier.FREE,
            orderId: '',
            purchaseToken: '',
            message: message
        };
    }
    private parseIapError(error: Object): string {
        const errStr = JSON.stringify(error);
        if (errStr.includes('cancel'))
            return '购买已取消';
        if (errStr.includes('network'))
            return '网络异常，请检查网络后重试';
        if (errStr.includes('already'))
            return '您已订阅该服务';
        return '购买失败，请稍后重试';
    }
    private isHigherTier(tier: SubscriptionTier, current: SubscriptionTier): boolean {
        const order: SubscriptionTier[] = [
            SubscriptionTier.FREE,
            SubscriptionTier.TRIAL_7DAY,
            SubscriptionTier.PERSONAL_YEAR,
            SubscriptionTier.FAMILY_EARLY,
            SubscriptionTier.FAMILY_STANDARD,
            SubscriptionTier.FAMILY_PREMIUM
        ];
        return order.indexOf(tier) > order.indexOf(current);
    }
}

import { hilog } from '@kit.PerformanceAnalysisKit';
import { PushSubscription } from 'hsp_core';

const TAG = 'PushMessageHandler';
const DOMAIN = 0;

export enum PushMessageType {
  FOOD_SAFETY_ALERT = 'food_safety_alert',
  ADDITIVE_RISK = 'additive_risk',
  NUTRITION_TIP = 'nutrition_tip',
  PRODUCT_UPDATE = 'product_update'
}

export interface PushMessagePayload {
  type: PushMessageType;
  title: string;
  body: string;
  data?: Record<string, string>;
  urgency?: 'low' | 'medium' | 'high' | 'critical';
  timestamp?: number;
}

export interface FoodSafetyAlertData {
  alertId: string;
  alertType: 'recall' | 'contamination' | 'expired_batch' | 'regulatory_warning';
  productName: string;
  brand: string;
  barcode?: string;
  reason: string;
  actionRequired: string;
  sourceUrl?: string;
  region: string;
  issuedAt: number;
}

export interface AdditiveRiskData {
  additiveName: string;
  riskLevel: 'low' | 'medium' | 'high';
  affectedProducts: string[];
  description: string;
  referenceUrl?: string;
}

export interface NutritionTipData {
  tipId: string;
  category: string;
  summary: string;
  detail: string;
  relatedFoods?: string[];
}

export interface ProductUpdateData {
  productId: string;
  productName: string;
  barcode: string;
  updateType: 'nutrition_change' | 'ingredient_change' | 'new_rating' | 'safety_flag';
  before?: string;
  after?: string;
}

export class PushMessageHandler {
  private static instance: PushMessageHandler | null = null;
  private subscription: PushSubscription = new PushSubscription();

  static getInstance(): PushMessageHandler {
    if (!PushMessageHandler.instance) {
      PushMessageHandler.instance = new PushMessageHandler();
    }
    return PushMessageHandler.instance;
  }

  setSubscription(subscription: PushSubscription): void {
    this.subscription = subscription;
  }

  handleMessage(payload: PushMessagePayload): void {
    if (!this.isSubscribed(payload.type)) {
      hilog.info(DOMAIN, TAG, 'User unsubscribed for type: %{public}s, skip', payload.type);
      return;
    }

    if (this.isInQuietHours()) {
      hilog.info(DOMAIN, TAG, 'In quiet hours, suppress notification: %{public}s', payload.type);
      return;
    }

    switch (payload.type) {
      case PushMessageType.FOOD_SAFETY_ALERT:
        this.handleFoodSafetyAlert(payload);
        break;
      case PushMessageType.ADDITIVE_RISK:
        this.handleAdditiveRisk(payload);
        break;
      case PushMessageType.NUTRITION_TIP:
        this.handleNutritionTip(payload);
        break;
      case PushMessageType.PRODUCT_UPDATE:
        this.handleProductUpdate(payload);
        break;
      default:
        hilog.warn(DOMAIN, TAG, 'Unknown push message type: %{public}s', payload.type);
    }
  }

  private isSubscribed(type: PushMessageType): boolean {
    switch (type) {
      case PushMessageType.FOOD_SAFETY_ALERT:
        return this.subscription.foodSafetyAlert;
      case PushMessageType.ADDITIVE_RISK:
        return this.subscription.additiveRisk;
      case PushMessageType.NUTRITION_TIP:
        return this.subscription.nutritionTip;
      case PushMessageType.PRODUCT_UPDATE:
        return this.subscription.productUpdate;
      default:
        return false;
    }
  }

  private isInQuietHours(): boolean {
    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const [startH, startM] = this.subscription.quietHoursStart.split(':').map(Number);
    const [endH, endM] = this.subscription.quietHoursEnd.split(':').map(Number);
    const startMinutes = startH * 60 + startM;
    const endMinutes = endH * 60 + endM;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }

  private handleFoodSafetyAlert(payload: PushMessagePayload): void {
    const alertData: FoodSafetyAlertData = payload.data as unknown as FoodSafetyAlertData;
    hilog.info(DOMAIN, TAG, 'Food safety alert: %{public}s - %{public}s',
      alertData.alertType, alertData.productName);
    AppStorage.setOrCreate('latestFoodSafetyAlert', alertData);
    AppStorage.setOrCreate('hasUnreadSafetyAlert', true);
  }

  private handleAdditiveRisk(payload: PushMessagePayload): void {
    const riskData: AdditiveRiskData = payload.data as unknown as AdditiveRiskData;
    hilog.info(DOMAIN, TAG, 'Additive risk: %{public}s (level: %{public}s)',
      riskData.additiveName, riskData.riskLevel);
    AppStorage.setOrCreate('latestAdditiveRisk', riskData);
  }

  private handleNutritionTip(payload: PushMessagePayload): void {
    const tipData: NutritionTipData = payload.data as unknown as NutritionTipData;
    hilog.info(DOMAIN, TAG, 'Nutrition tip: %{public}s', tipData.summary);
    AppStorage.setOrCreate('latestNutritionTip', tipData);
  }

  private handleProductUpdate(payload: PushMessagePayload): void {
    const updateData: ProductUpdateData = payload.data as unknown as ProductUpdateData;
    hilog.info(DOMAIN, TAG, 'Product update: %{public}s (%{public}s)',
      updateData.productName, updateData.updateType);
    AppStorage.setOrCreate('latestProductUpdate', updateData);
  }
}

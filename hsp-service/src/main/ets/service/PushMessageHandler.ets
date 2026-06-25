import { hilog } from '@kit.PerformanceAnalysisKit';
// import { PushSubscription } from 'hsp_core';

// Stub class — PushSubscription not yet implemented in hsp_core
export class PushSubscription {
  endpoint: string = '';
  keys: Record<string, string> = {};
  foodSafetyAlert: boolean = false;
  additiveRisk: boolean = false;
  nutritionTip: boolean = false;
  productUpdate: boolean = false;
  quietHoursStart: string = '';
  quietHoursEnd: string = '';
}

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

function isFoodSafetyAlertData(raw: Record<string, string> | undefined): boolean {
  if (raw === undefined) return false;
  return typeof raw['alertId'] === 'string'
    && typeof raw['productName'] === 'string'
    && typeof raw['reason'] === 'string';
}

function isAdditiveRiskData(raw: Record<string, string> | undefined): boolean {
  if (raw === undefined) return false;
  return typeof raw['additiveName'] === 'string'
    && typeof raw['riskLevel'] === 'string';
}

function isNutritionTipData(raw: Record<string, string> | undefined): boolean {
  if (raw === undefined) return false;
  return typeof raw['tipId'] === 'string'
    && typeof raw['summary'] === 'string';
}

function isProductUpdateData(raw: Record<string, string> | undefined): boolean {
  if (raw === undefined) return false;
  return typeof raw['productId'] === 'string'
    && typeof raw['productName'] === 'string'
    && typeof raw['updateType'] === 'string';
}

function parsePayloadData<T>(raw: Record<string, string> | undefined): T {
  return raw as Object as T;
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
    const startParts: string[] = this.subscription.quietHoursStart.split(':');
    const startH: number = parseInt(startParts[0]);
    const startM: number = parseInt(startParts[1]);
    const endParts: string[] = this.subscription.quietHoursEnd.split(':');
    const endH: number = parseInt(endParts[0]);
    const endM: number = parseInt(endParts[1]);
    const startMinutes: number = startH * 60 + startM;
    const endMinutes: number = endH * 60 + endM;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    return currentMinutes >= startMinutes || currentMinutes < endMinutes;
  }

  private handleFoodSafetyAlert(payload: PushMessagePayload): void {
    if (!isFoodSafetyAlertData(payload.data)) {
      hilog.warn(DOMAIN, TAG, 'Invalid food safety alert payload');
      return;
    }
    const alertData: FoodSafetyAlertData = parsePayloadData<FoodSafetyAlertData>(payload.data);
    hilog.info(DOMAIN, TAG, 'Food safety alert: %{public}s - %{public}s',
      alertData.alertType, alertData.productName);
    AppStorage.setOrCreate('latestFoodSafetyAlert', alertData);
    AppStorage.setOrCreate('hasUnreadSafetyAlert', true);
  }

  private handleAdditiveRisk(payload: PushMessagePayload): void {
    if (!isAdditiveRiskData(payload.data)) {
      hilog.warn(DOMAIN, TAG, 'Invalid additive risk payload');
      return;
    }
    const riskData: AdditiveRiskData = parsePayloadData<AdditiveRiskData>(payload.data);
    hilog.info(DOMAIN, TAG, 'Additive risk: %{public}s (level: %{public}s)',
      riskData.additiveName, riskData.riskLevel);
    AppStorage.setOrCreate('latestAdditiveRisk', riskData);
  }

  private handleNutritionTip(payload: PushMessagePayload): void {
    if (!isNutritionTipData(payload.data)) {
      hilog.warn(DOMAIN, TAG, 'Invalid nutrition tip payload');
      return;
    }
    const tipData: NutritionTipData = parsePayloadData<NutritionTipData>(payload.data);
    hilog.info(DOMAIN, TAG, 'Nutrition tip: %{public}s', tipData.summary);
    AppStorage.setOrCreate('latestNutritionTip', tipData);
  }

  private handleProductUpdate(payload: PushMessagePayload): void {
    if (!isProductUpdateData(payload.data)) {
      hilog.warn(DOMAIN, TAG, 'Invalid product update payload');
      return;
    }
    const updateData: ProductUpdateData = parsePayloadData<ProductUpdateData>(payload.data);
    hilog.info(DOMAIN, TAG, 'Product update: %{public}s (%{public}s)',
      updateData.productName, updateData.updateType);
    AppStorage.setOrCreate('latestProductUpdate', updateData);
  }
}

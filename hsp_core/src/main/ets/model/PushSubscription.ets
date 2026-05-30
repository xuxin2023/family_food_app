export class PushSubscription {
  userId: string = '';
  pushToken: string = '';
  foodSafetyAlert: boolean = true;
  additiveRisk: boolean = true;
  nutritionTip: boolean = false;
  productUpdate: boolean = true;
  quietHoursStart: string = '22:00';
  quietHoursEnd: string = '08:00';
}

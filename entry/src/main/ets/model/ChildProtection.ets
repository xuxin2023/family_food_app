// 儿童保护建议数据模型

// ChildProtection JSON 输出类
export class ChildProtectionJson {
  memberId: Object = '';
  mealProtection: Object = '';
  bedtimeProtection: Object = '';
  tasteProtection: Object = '';
  counteractReminder: Object = false;
}

export class ChildProtection {
  memberId: string = '';
  mealProtection: string = '';       // 正餐保护建议
  bedtimeProtection: string = '';    // 睡前保护建议
  tasteProtection: string = '';      // 口味保护建议
  counteractReminder: boolean = false; // 抵消提醒

  // 是否有任何保护建议
  hasAnyAdvice(): boolean {
    return this.mealProtection.length > 0 ||
           this.bedtimeProtection.length > 0 ||
           this.tasteProtection.length > 0;
  }

  toJson(): ChildProtectionJson {
    const json = new ChildProtectionJson();
    json.memberId = this.memberId;
    json.mealProtection = this.mealProtection;
    json.bedtimeProtection = this.bedtimeProtection;
    json.tasteProtection = this.tasteProtection;
    json.counteractReminder = this.counteractReminder;
    return json;
  }
}

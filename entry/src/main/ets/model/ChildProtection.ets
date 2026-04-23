// 儿童保护建议数据模型

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

  toJson(): Record<string, Object> {
    return {
      memberId: this.memberId,
      mealProtection: this.mealProtection,
      bedtimeProtection: this.bedtimeProtection,
      tasteProtection: this.tasteProtection,
      counteractReminder: this.counteractReminder
    };
  }
}

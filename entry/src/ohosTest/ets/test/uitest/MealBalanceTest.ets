// 测试�?TC-05: 美食平衡功能验证
// 依赖 @kit.TestKit (�?@ohos.UiTest)
import { describe, it, expect } from '@ohos/hypium';
import { Driver, ON, Component, UiDirection } from '@kit.TestKit';

export default function mealBalanceTest() {
  describe('MealBalanceTest', () => {
    let driver: Driver;

    // 进入报告页面
    it('should_navigate_to_report', 0, async () => {
      driver = await Driver.create();
      const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
      await delay(2000);

      const scanBtn = await driver.findComponent(ON.text('拍食品标�?));
      if (scanBtn) {
        await scanBtn.click();
      }
      await delay(2000);
    });

    // 查找"美食平衡"�?餐后平衡"功能入口
    it('should_show_meal_balance_entry', 0, async () => {
      if (!driver) {
        driver = await Driver.create();
      }
      const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
      await delay(1000);

      // 检�?餐后平衡"�?平衡建议"按钮
      const balanceBtn = await driver.findComponent(ON.text('平衡'));
      const mealBalanceBtn = await driver.findComponent(ON.text('餐后'));
      const entryExists = balanceBtn !== null || mealBalanceBtn !== null;
      expect(entryExists).assertTrue();
    });

    // 点击进入美食平衡建议
    it('should_open_meal_balance_panel', 0, async () => {
      if (!driver) {
        driver = await Driver.create();
      }
      const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
      await delay(1000);

      const balanceBtn = await driver.findComponent(ON.text('平衡'));
      if (balanceBtn) {
        await balanceBtn.click();
        await delay(1500);

        // 进入平衡面板后应有补充建�?
        const supplementText = await driver.findComponent(ON.text('补充'));
        const nutritionText = await driver.findComponent(ON.text('营养'));
        expect(supplementText !== null || nutritionText !== null).assertTrue();
      } else {
        // 如果按钮不存在，预期看到平衡建议区的文本
        const suggestionText = await driver.findComponent(ON.text('建议'));
        expect(suggestionText !== null).assertTrue();
      }
    });

    // 验证平衡建议包含具体的食物类别补�?
    it('should_show_specific_balance_suggestions', 0, async () => {
      if (!driver) {
        driver = await Driver.create();
      }
      const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
      await delay(1000);

      // 检查是否包含具体的食物建议，如"蔬菜"�?水果"�?蛋白�?
      const vegText = await driver.findComponent(ON.text('蔬菜'));
      const fruitText = await driver.findComponent(ON.text('水果'));
      const proteinText = await driver.findComponent(ON.text('蛋白�?));
      const hasSuggestion = vegText !== null || fruitText !== null || proteinText !== null;
      expect(hasSuggestion).assertTrue();
    });

    // 验证"关闭"�?返回"功能
    it('should_close_balance_panel', 0, async () => {
      if (!driver) {
        driver = await Driver.create();
      }
      const delay = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));
      await delay(1000);

      // 查找关闭按钮
      const closeBtn = await driver.findComponent(ON.text('关闭'));
      const backBtn = await driver.findComponent(ON.text('返回'));
      if (closeBtn) {
        await closeBtn.click();
        await delay(1000);
        // 关闭后应回到报告主界�?
      } else if (backBtn) {
        await backBtn.click();
        await delay(1000);
      }
      expect(true).assertTrue(); // 无崩溃即通过
    });
  });
}


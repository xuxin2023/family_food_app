// BasketCheckEngine.test.ets
// BasketCheckEngine 单元测试 — 购物篮食品组合检查

import { describe, it, expect } from '@ohos/hypium';
import { BasketCheckEngine } from '../../main/ets/engine/BasketCheckEngine';
import { FoodLabel } from '../../main/ets/model/FoodLabel';
import { FamilyProfile } from '../../main/ets/model/FamilyProfile';

export default function basketCheckEngineTest() {
  describe('BasketCheckEngine', () => {
    const engine = new BasketCheckEngine();
    const member = new FamilyProfile();
    member.memberId = 'test-m1';
    member.nickname = '测试成员';
    member.dailySodiumBudget = 2000;
    member.dailySugarBudget = 50;

    it('emptyBasket_returnsNoWarnings', 0, () => {
      const result = engine.check([], [member]);
      expect(result.warnings.length === 0).assertTrue();
      expect(result.suggestions.length === 0).assertTrue();
    });

    it('singleItem_noWarning', 0, () => {
      const item = new FoodLabel();
      item.foodId = 'f1';
      item.foodName = '低盐食品';
      item.nutrition.sodium = 100;
      item.nutrition.sugar = 5;
      const result = engine.check([item], [member]);
      expect(result.warnings.length === 0).assertTrue();
    });
  });
}

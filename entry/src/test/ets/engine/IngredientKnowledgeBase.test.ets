// IngredientKnowledgeBase.test.ets
// 配料知识库单元测试

import { describe, it, expect } from '@ohos/hypium';
import { IngredientKnowledgeBase, IngredientAssessment } from '../../../main/ets/engine/IngredientKnowledgeBase';

export default function ingredientKnowledgeBaseTest() {
  describe('IngredientKnowledgeBase', () => {
    it('should assess common preservative ingredients', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.assessIngredient('苯甲酸钠');
      expect(result.riskLevel).assertEqual('medium');
    });

    it('should assess water as safe', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.assessIngredient('水');
      expect(result.riskLevel).assertEqual('low');
    });

    it('should return unknown for non-standard ingredient', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.assessIngredient('unknown_xyz_123');
      expect(result.riskLevel).assertEqual('unknown');
    });
  });
}

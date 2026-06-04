import { describe, it, expect } from '@ohos/hypium';
import {
  IngredientKnowledgeBase, IngredientAssessment, IngredientRiskLevel,
  IngredientListAssessment
} from 'feature_scan';

export default function ingredientKnowledgeBaseTest() {
  describe('IngredientKnowledgeBase', () => {
    it('should assess high-risk trans fat ingredient', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('氢化植物油');
      expect(result.riskLevel).assertEqual(IngredientRiskLevel.HIGH_RISK);
      expect(result.riskScore >= 80).assertTrue();
    });

    it('should assess banned ingredient bromate as avoid', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('溴酸钾');
      expect(result.riskLevel).assertEqual(IngredientRiskLevel.AVOID);
      expect(result.eNumber).assertEqual('E924');
    });

    it('should assess safe natural ingredient', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('柠檬酸');
      expect(result.riskLevel).assertEqual(IngredientRiskLevel.SAFE);
      expect(result.riskScore <= 20).assertTrue();
    });

    it('should assess unknown ingredient as safe default', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('未知配料xyz');
      expect(result.riskLevel).assertEqual(IngredientRiskLevel.SAFE);
    });

    it('should resolve alias for vitamin C', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('抗坏血酸');
      expect(result.riskScore).assertEqual(5);
    });

    it('should assess allergen peanut as high risk', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('花生');
      expect(result.riskLevel).assertEqual(IngredientRiskLevel.HIGH_RISK);
      expect(result.category).assertEqual('过敏原');
    });

    it('should assess allergen gluten via alias', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('面筋');
      expect(result.riskLevel).assertEqual(IngredientRiskLevel.HIGH_RISK);
    });

    it('should assess flour treatment agent ADA', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('偶氮甲酰胺');
      expect(result.eNumber).assertEqual('E927a');
      expect(result.isAdditive).assertTrue();
    });

    it('should assess disputed E171 titanium dioxide', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('钛白粉');
      expect(result.riskScore >= 40).assertTrue();
    });

    it('should assess moisture retainer phosphate', () => {
      const result: IngredientAssessment = IngredientKnowledgeBase.analyzeIngredient('三聚磷酸钠');
      expect(result.category).assertEqual('水分保持剂');
      expect(result.eNumber).assertEqual('E451');
    });

    it('should analyze ingredient list with mixed risks', () => {
      const result: IngredientListAssessment = IngredientKnowledgeBase.analyzeIngredientList(
        ['氢化植物油', '柠檬酸', '花生', '维生素C']
      );
      expect(result.highRiskIngredients.length > 0).assertTrue();
      expect(result.assessments.length).assertEqual(4);
    });

    it('should return safe for empty ingredient list', () => {
      const result: IngredientListAssessment = IngredientKnowledgeBase.analyzeIngredientList([]);
      expect(result.riskLevel).assertEqual(IngredientRiskLevel.SAFE);
      expect(result.summary).assertEqual('无配料信息');
    });

    it('should get health score inversely proportional to risk', () => {
      const safeScore: number = IngredientKnowledgeBase.getHealthScore('柠檬酸');
      const riskyScore: number = IngredientKnowledgeBase.getHealthScore('氢化植物油');
      expect(safeScore > riskyScore).assertTrue();
    });

    it('should search ingredients by keyword', () => {
      const results: string[] = IngredientKnowledgeBase.searchIngredients('磷酸');
      expect(results.length > 0).assertTrue();
    });
  });
}

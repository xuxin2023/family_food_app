import { describe, it, expect } from '@ohos/hypium';
import {
  AllergenAutoDetector, AllergenCheckResult
} from '../../../../../../feature-scan/src/main/ets/engine/AllergenAutoDetector';

export default function allergenAutoDetectorTest() {
  describe('AllergenAutoDetector', () => {
    const detector = AllergenAutoDetector.getInstance();

    it('should_detect_peanut_allergen', 0, () => {
      const result = detector.checkAllergens(['花生'], ['花生酱', '面粉', '白糖']);
      expect(result.hasAlert).assertTrue();
      expect(result.matchedAllergens.length).assertGreater(0);
    });

    it('should_detect_milk_allergen', 0, () => {
      const result = detector.checkAllergens(['牛奶'], ['乳清蛋白', '面粉']);
      expect(result.hasAlert).assertTrue();
    });

    it('should_detect_multiple_allergens', 0, () => {
      const result = detector.checkAllergens(['花生', '牛奶'], ['花生酱', '奶粉', '面粉']);
      expect(result.hasAlert).assertTrue();
      expect(result.matchedAllergens.length).assertEqual(2);
    });

    it('should_return_empty_for_safe_food', 0, () => {
      const result = detector.checkAllergens(['花生', '牛奶'], ['大米', '面粉', '白糖']);
      expect(result.hasAlert).assertFalse();
      expect(result.matchedAllergens.length).assertEqual(0);
    });

    it('should_return_empty_for_empty_allergens', 0, () => {
      const result = detector.checkAllergens([], ['花生酱', '牛奶']);
      expect(result.hasAlert).assertFalse();
    });

    it('should_return_empty_for_empty_ingredients', 0, () => {
      const result = detector.checkAllergens(['花生'], []);
      expect(result.hasAlert).assertFalse();
    });

    it('should_populate_details_with_position', 0, () => {
      const result = detector.checkAllergens(['花生'], ['面粉', '花生酱', '白糖']);
      expect(result.details.length).assertGreater(0);
      expect(result.details[0].position).assertEqual(1);
      expect(result.details[0].allergen).assertEqual('花生');
    });

    it('containsAnyAllergen_should_detect_known_keyword', 0, () => {
      expect(detector.containsAnyAllergen('花生酱')).assertTrue();
      expect(detector.containsAnyAllergen('奶粉')).assertTrue();
    });

    it('containsAnyAllergen_should_return_false_for_safe', 0, () => {
      expect(detector.containsAnyAllergen('大米')).assertFalse();
      expect(detector.containsAnyAllergen('食盐')).assertFalse();
    });

    it('analyzeCrossReactivity_shrimp_to_crab', 0, () => {
      const warnings = detector.analyzeCrossReactivity(['虾'], ['蟹肉', '龙虾']);
      expect(warnings.length).assertGreater(0);
      const hasCrab = warnings.some(w => w.ingredient.includes('蟹') || w.ingredient.includes('龙虾'));
      expect(hasCrab).assertTrue();
    });

    it('analyzeCrossReactivity_peanut_to_soy', 0, () => {
      const warnings = detector.analyzeCrossReactivity(['花生'], ['大豆蛋白', '面粉']);
      expect(warnings.length).assertGreater(0);
      const hasSoy = warnings.some(w => w.ingredient.includes('大豆'));
      expect(hasSoy).assertTrue();
    });

    it('analyzeCrossReactivity_no_cross_for_safe', 0, () => {
      const warnings = detector.analyzeCrossReactivity(['花生'], ['大米', '食盐']);
      expect(warnings.length).assertEqual(0);
    });

    it('analyzeCrossReactivity_milk_to_goat', 0, () => {
      const warnings = detector.analyzeCrossReactivity(['牛奶'], ['山羊奶酪']);
      expect(warnings.length).assertGreater(0);
    });
  });
}
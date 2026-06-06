import { describe, it, expect } from '@ohos/hypium';
import { RuleRepository, AllergenKeywordMap } from 'hsp_service';

export default function ruleRepositoryTest() {
  describe('RuleRepository', () => {
    const repo: RuleRepository = new RuleRepository()

    it('should return AllergenKeywordMap class instance from loadAllergenKeywords', async () => {
      const result = await repo.loadAllergenKeywords();
      expect(result instanceof AllergenKeywordMap).assertTrue();
      expect(result.allergenToKeywords).notBeNull();
      expect(result.commonAllergens).notBeNull();
    });

    it('should return default map when context not set', async () => {
      const result = await repo.loadAllergenKeywords();
      expect(typeof result.allergenToKeywords).assertEqual('object');
      expect(Array.isArray(result.commonAllergens)).assertTrue();
    });
  });
}

import { describe, it, expect } from '@ohos/hypium';
import { OnDeviceAiEngine, IngredientAnalysis } from '../../../main/ets/engine/OnDeviceAiEngine';

export default function onDeviceAiEngineTest() {
  describe('OnDeviceAiEngine', () => {
    const engine = OnDeviceAiEngine.getInstance();

    it('should return NpuStatus from getStatus', () => {
      const status = engine.getStatus();
      expect(status).notBeNull();
      expect(typeof status.available).assertEqual('boolean');
      expect(typeof status.modelLoaded).assertEqual('boolean');
    });

    it('should parse valid ingredient result as IngredientAnalysis class instance', () => {
      const parseMethod = (engine as { parseIngredientResult: (s: string) => IngredientAnalysis }).parseIngredientResult;
      if (parseMethod) {
        const input = JSON.stringify({
          harmfulAdditives: [{ name: 'test', code: 'E100', risk: '低' }],
          nutritionScore: 70,
          novaGroup: 2,
          allergenRisks: [],
          summary: '测试',
          suggestion: ''
        });
        const result = parseMethod(input);
        expect(result instanceof IngredientAnalysis).assertTrue();
        expect(result.nutritionScore).assertEqual(70);
      }
    });
  });
}

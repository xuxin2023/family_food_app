import { describe, it, expect } from '@ohos/hypium';
import { OcrService, OcrResult } from '../../../main/ets/service/OcrService';

export default function ocrServiceTest() {
  describe('OcrService', () => {
    const service = new OcrService();

    it('should return cached config from getConfig', () => {
      const config1 = (service as Record<string, Object>)['getConfig']
        ? (service as { getConfig: () => Object }).getConfig()
        : null;
      expect(config1).notBeNull();
    });

    it('should extract food label from OCR text', () => {
      const label = service.extractFoodLabel('品名：测试饼干\n配料：小麦粉、白砂糖\n营养成分：钠 500mg');
      expect(label.foodName.length).assertLarger(0);
    });
  });
}

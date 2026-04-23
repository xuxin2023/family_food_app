import { common } from '@kit.AbilityKit';
import { FoodLabel, FoodSource } from '../model/FoodLabel';
import { OcrService } from './OcrService';
import { ScanService } from './ScanService';

export interface FoodInputResult {
  foodLabel: FoodLabel;
  recognizedText: string;
  hint: string;
  confidence: number;
  requiresManualReview: boolean;
}

export class FoodInputService {
  private scanService: ScanService = new ScanService();
  private ocrService: OcrService = new OcrService();

  createManualDraft(): FoodInputResult {
    const draft = new FoodLabel();
    draft.foodId = `food_${Date.now()}`;
    draft.source = FoodSource.USER_UPLOAD;
    draft.identifiedAt = Date.now();
    return {
      foodLabel: draft,
      recognizedText: '',
      hint: '当前为手动录入模式',
      confidence: 1,
      requiresManualReview: true
    };
  }

  createCameraDraft(): FoodInputResult {
    const draft = new FoodLabel();
    draft.foodId = `food_${Date.now()}`;
    draft.foodName = '待补充食品';
    draft.source = FoodSource.OCR_RECOGNIZE;
    draft.identifiedAt = Date.now();
    return {
      foodLabel: draft,
      recognizedText: 'P0 版未接复杂相机实时流，已生成一个可编辑草稿',
      hint: '当前按低置信度处理，请核对后保存',
      confidence: 0.45,
      requiresManualReview: true
    };
  }

  async scanBarcode(context: common.Context): Promise<FoodInputResult | null> {
    const scanResult = await this.scanService.scanAndLookup(context);
    const foodLabel = scanResult.foodLabel;
    const barcode = scanResult.barcode;
    if (foodLabel) {
      return {
        foodLabel,
        recognizedText: `已命中本地食品库：${foodLabel.foodName}`,
        hint: '可直接查看报告，也可以再手动修正',
        confidence: 1,
        requiresManualReview: false
      };
    }

    if (barcode.length > 0) {
      const draft = new FoodLabel();
      draft.foodId = `food_${Date.now()}`;
      draft.foodName = '条码商品（待补充）';
      draft.barcode = barcode;
      draft.source = FoodSource.BARCODE_SCAN;
      draft.identifiedAt = Date.now();
      return {
        foodLabel: draft,
        recognizedText: `仅识别到条码：${barcode}`,
        hint: '请补全营养与生产信息后再查看报告',
        confidence: 0,
        requiresManualReview: true
      };
    }

    return null;
  }

  async recognizeImage(imageUri: string): Promise<FoodInputResult> {
    const ocrResult = await this.ocrService.recognizeText(imageUri);
    if (ocrResult.text.trim().length === 0) {
      return this.createCameraDraft();
    }

    const foodLabel = this.ocrService.extractFoodLabel(ocrResult.text);
    const confidence = ocrResult.confidence > 0 ? ocrResult.confidence : 0.5;
    return {
      foodLabel,
      recognizedText: ocrResult.text,
      hint: confidence >= 0.8 ? 'OCR 识别完成，可先核对再保存' : 'OCR 置信度偏低，建议手动核对关键信息',
      confidence,
      requiresManualReview: confidence < 0.8
    };
  }
}

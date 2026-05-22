import { common } from '@kit.AbilityKit';
import { FoodLabel, FoodSource } from 'hsp_core';
import { OcrService } from './OcrService';
import { ScanService } from './ScanService';

export class FoodInputResult {
  foodLabel: FoodLabel = new FoodLabel();
  recognizedText: string = '';
  hint: string = '';
  confidence: number = 0;
  requiresManualReview: boolean = false;
}

export class FoodInputService {
  private scanService: ScanService = new ScanService();
  private ocrService: OcrService = new OcrService();

  createManualDraft(): FoodInputResult {
    const draft = new FoodLabel();
    draft.foodId = `food_${Date.now()}`;
    draft.source = FoodSource.USER_UPLOAD;
    draft.identifiedAt = Date.now();
    const result = new FoodInputResult();
    result.foodLabel = draft;
    result.recognizedText = '';
    result.hint = '当前为手动录入模式';
    result.confidence = 1;
    result.requiresManualReview = true;
    return result;
  }

  createCameraDraft(): FoodInputResult {
    const draft = new FoodLabel();
    draft.foodId = `food_${Date.now()}`;
    draft.foodName = '待补充食品';
    draft.source = FoodSource.OCR_RECOGNIZE;
    draft.identifiedAt = Date.now();
    const result = new FoodInputResult();
    result.foodLabel = draft;
    result.recognizedText = 'P0 版未接复杂相机实时流，已生成一个可编辑草稿';
    result.hint = '当前按低置信度处理，请核对后保存';
    result.confidence = 0.45;
    result.requiresManualReview = true;
    return result;
  }

  async scanBarcode(context: common.Context): Promise<FoodInputResult | null> {
    const scanResult = await this.scanService.scanAndLookup(context);
    const foodLabel = scanResult.foodLabel;
    const barcode = scanResult.barcode;
    if (foodLabel) {
      const r1 = new FoodInputResult();
      r1.foodLabel = foodLabel;
      r1.recognizedText = `已命中本地食品库：${foodLabel.foodName}`;
      r1.hint = '可直接查看报告，也可以再手动修正';
      r1.confidence = 1;
      r1.requiresManualReview = false;
      return r1;
    }

    if (barcode.length > 0) {
      const draft = new FoodLabel();
      draft.foodId = `food_${Date.now()}`;
      draft.foodName = '条码商品（待补充）';
      draft.barcode = barcode;
      draft.source = FoodSource.BARCODE_SCAN;
      draft.identifiedAt = Date.now();
      const r2 = new FoodInputResult();
      r2.foodLabel = draft;
      r2.recognizedText = `仅识别到条码：${barcode}`;
      r2.hint = '请补全营养与生产信息后再查看报告';
      r2.confidence = 0;
      r2.requiresManualReview = true;
      return r2;
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
    const result = new FoodInputResult();
    result.foodLabel = foodLabel;
    result.recognizedText = ocrResult.text;
    result.hint = confidence >= 0.8 ? 'OCR 识别完成，可先核对再保存' : 'OCR 置信度偏低，建议手动核对关键信息';
    result.confidence = confidence;
    result.requiresManualReview = confidence < 0.8;
    return result;
  }
}
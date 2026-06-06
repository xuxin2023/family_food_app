// OCR服务 - 集成华为Core Vision Kit
// API参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/textrecognition-V5

import { FoodLabel, FoodSource, NutritionPer100g, StringRes, HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'OcrService';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

// OCR边界框
export class OcrBounds {
  left: number = 0;
  top: number = 0;
  right: number = 0;
  bottom: number = 0;
}

// OCR识别块
export class OcrBlock {
  text: string = '';
  confidence: number = 0;
  bounds: OcrBounds = new OcrBounds();
}

// OCR识别结果
export class OcrResult {
  text: string = '';
  confidence: number = 0;
  blocks: OcrBlock[] = [];
}

// OEM信息
export class OemInfo {
  principal: string = '';
  trustee: string = '';
}

export class OcrService {
  /**
   * 初始化OCR引擎（兼容旧调用点，当前无需创建识别实例）
   */
  async init(): Promise<void> {
    hilog.info(DOMAIN_ZERO, TAG, 'OCR service ready with function-based Core Vision Kit API');
  }

  /**
   * 释放OCR资源（兼容旧调用点，当前无需释放识别实例）
   */
  async release(): Promise<void> {
    hilog.info(DOMAIN_ZERO, TAG, 'OCR service release skipped for function-based Core Vision Kit API');
  }

  /**
   * 从图片URI识别文字
   * @param imageUri 图片URI（由相机或相册返回）
   * @returns OCR识别结果
   */
  async recognizeText(imageUri: string): Promise<OcrResult> {
    let pixelMap: image.PixelMap | null = null;
    try {
      const imageSource = image.createImageSource(imageUri);
      pixelMap = await imageSource.createPixelMap();
      const result = await this.recognizeFromPixelMap(pixelMap);
      hilog.info(DOMAIN_ZERO, TAG, 'OCR recognized %{public}d blocks', result.blocks.length);
      return result;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'OCR recognize failed: %{public}s', JSON.stringify(error));
      const emptyResult: OcrResult = new OcrResult()
      emptyResult.text = '';
      emptyResult.confidence = 0;
      emptyResult.blocks = [];
      return emptyResult;
    } finally {
      if (pixelMap) {
        try {
          pixelMap.release();
        } catch (releaseError) {
          hilog.warn(DOMAIN_ZERO, TAG, 'OCR pixelMap release failed: %{public}s', JSON.stringify(releaseError));
        }
      }
    }
  }

  /**
   * 从PixelMap识别文字（相机实时帧场景）
   * @param pixelMap 相机帧PixelMap
   * @returns OCR识别结果
   */
  private static cachedConfig: textRecognition.TextRecognitionConfiguration | null = null;

  private static getConfig(): textRecognition.TextRecognitionConfiguration {
    if (!OcrService.cachedConfig) {
      OcrService.cachedConfig = { isDirectionDetectionSupported: false } as textRecognition.TextRecognitionConfiguration;
    }
    return OcrService.cachedConfig;
  }

  async recognizeFromPixelMap(pixelMap: image.PixelMap): Promise<OcrResult> {
    try {
      const visionInfo: textRecognition.VisionInfo = { pixelMap: pixelMap } as textRecognition.VisionInfo;
      const textResult = await textRecognition.recognizeText(visionInfo, OcrService.getConfig());
      return this.parseOcrResult(textResult);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'OCR recognize from PixelMap failed: %{public}s', JSON.stringify(error));
      const emptyResult: OcrResult = new OcrResult()
      emptyResult.text = '';
      emptyResult.confidence = 0;
      emptyResult.blocks = [];
      return emptyResult;
    }
  }

  /**
   * 从OCR文本中提取食品标签结构化数据
   * @param ocrText OCR识别的原始文本
   * @returns 结构化的FoodLabel
   */
  extractFoodLabel(ocrText: string): FoodLabel {
    const label: FoodLabel = new FoodLabel()
    label.foodId = `food_${Date.now()}`;
    label.source = FoodSource.USER_UPLOAD;
    label.identifiedAt = Date.now();

    // 提取食品名称（通常在包装最显眼位置）
    label.foodName = this.extractFoodName(ocrText);

    // 提取营养成分表
    label.nutrition = this.extractNutrition(ocrText);

    // 提取配料表
    label.ingredients = this.extractIngredients(ocrText);

    // 提取生产商
    label.manufacturer = this.extractManufacturer(ocrText);

    // 提取SC编号
    label.scNumber = this.extractScNumber(ocrText);

    // 提取委托方/受托方
    const oemInfo = this.extractOemInfo(ocrText);
    label.principal = oemInfo.principal;
    label.trustee = oemInfo.trustee;

    // 提取条码（如果OCR结果中包含）
    const barcode = this.extractBarcode(ocrText);
    if (barcode.length > 0) {
      label.barcode = barcode;
    }

    return label;
  }

  /**
   * 完整流程：拍照 → OCR → 提取FoodLabel
   * @param imageUri 图片URI
   * @returns 结构化的FoodLabel
   */
  async recognizeAndExtract(imageUri: string): Promise<FoodLabel> {
    const ocrResult = await this.recognizeText(imageUri);
    if (ocrResult.text.length === 0) {
      // OCR失败，返回空标签
      const label: FoodLabel = new FoodLabel()
      label.foodId = `food_${Date.now()}`;
      label.foodName = StringRes.OCR_FAILED_FOOD;
      label.source = FoodSource.USER_UPLOAD;
      label.identifiedAt = Date.now();
      return label;
    }
    return this.extractFoodLabel(ocrResult.text);
  }

  // ========== 内部方法 ==========

  /**
   * 解析Core Vision Kit返回的OCR结果
   */
  private parseOcrResult(textResult: textRecognition.TextRecognitionResult): OcrResult {
    const blocks: OcrBlock[] = [];
    let fullText = textResult.value ? textResult.value.trim() : '';

    for (const block of textResult.blocks) {
      const lines: string[] = [];
      for (const line of block.lines) {
        if (line.words.length > 0) {
          const words = line.words.map((word) => word.value).join(' ').trim();
          if (words.length > 0) {
            lines.push(words);
            continue;
          }
        }

        const lineValue = line.value.trim();
        if (lineValue.length > 0) {
          lines.push(lineValue);
        }
      }

      const blockValue = block.value.trim();
      const blockText = blockValue.length > 0 ? blockValue : lines.join('\n').trim();
      if (blockText.length === 0) {
        continue;
      }

      const ocrBlock: OcrBlock = new OcrBlock()
      ocrBlock.text = blockText;
      ocrBlock.confidence = 0;
      ocrBlock.bounds = this.buildBounds(this.resolveCornerPoints(block))
      blocks.push(ocrBlock);
    }

    if (fullText.length === 0 && blocks.length > 0) {
      fullText = blocks.map((block) => block.text).join('\n').trim();
    }

    const result: OcrResult = new OcrResult()
    result.text = fullText;
    result.confidence = 0;
    result.blocks = blocks;
    return result;
  }

  private resolveCornerPoints(block: textRecognition.TextBlock): Array<textRecognition.PixelPoint> {
    for (const line of block.lines) {
      if (line.cornerPoints.length > 0) {
        return line.cornerPoints;
      }
    }

    // 尝试从block本身获取cornerPoints（使用反射方式）
    // 由于 TextBlock 可能没有直接的 cornerPoints 属性，这里返回空数组
    return [];
  }

  private buildBounds(cornerPoints: Array<textRecognition.PixelPoint>): OcrBounds {
    const bounds: OcrBounds = new OcrBounds(
    if (cornerPoints.length === 0) {
      return bounds;
    }

    bounds.left = cornerPoints[0].x;
    bounds.top = cornerPoints[0].y;
    bounds.right = cornerPoints[0].x;
    bounds.bottom = cornerPoints[0].y;

    for (const point of cornerPoints) {
      bounds.left = Math.min(bounds.left, point.x);
      bounds.top = Math.min(bounds.top, point.y);
      bounds.right = Math.max(bounds.right, point.x);
      bounds.bottom = Math.max(bounds.bottom, point.y);
    }

    return bounds;
  }

  // 提取食品名称
  private extractFoodName(text: string): string {
    // 策略1：查找"品名"关键字
    const nameMatch = text.match(/(?:品名|产品名称|食品名称)[：:]\s*(.*?)(?:\n|$)/);
    if (nameMatch && nameMatch[1].trim().length > 0) {
      return nameMatch[1].trim().substring(0, 30);
    }
    // 策略2：取第一行非空文本（通常是食品名）
    const lines = text.split('\n').filter(l => l.trim().length > 0);
    if (lines.length > 0) {
      return lines[0].trim().substring(0, 30);
    }
    return StringRes.UNKNOWN_FOOD;
  }

  // 提取营养成分
  private extractNutrition(text: string): NutritionPer100g {
    const nutrition: NutritionPer100g = new NutritionPer100g(

    // 钠（支持"钠"和"钠/Na"两种写法）
    const sodiumMatch = text.match(/(?:钠|Na)[^\d]*(\d+\.?\d*)\s*mg/);
    if (sodiumMatch) nutrition.sodium = parseFloat(sodiumMatch[1]);

    // 糖（支持"糖"和"总糖"）
    const sugarMatch = text.match(/(?:总糖|糖(?:含量)?)[^\d]*(\d+\.?\d*)\s*g/);
    if (sugarMatch) nutrition.sugar = parseFloat(sugarMatch[1]);

    // 能量/热量
    const calorieMatch = text.match(/(?:能量|热量|Energy)[^\d]*(\d+\.?\d*)\s*(?:kcal|千卡|kJ|千焦)/);
    if (calorieMatch) nutrition.calories = parseFloat(calorieMatch[1]);

    // 脂肪
    const fatMatch = text.match(/(?:脂肪|总脂肪)[^\d]*(\d+\.?\d*)\s*g/);
    if (fatMatch) nutrition.fat = parseFloat(fatMatch[1]);

    // 饱和脂肪
    const satFatMatch = text.match(/(?:饱和脂肪|饱和脂肪酸)[^\d]*(\d+\.?\d*)\s*g/);
    if (satFatMatch) nutrition.saturatedFat = parseFloat(satFatMatch[1]);

    // 碳水化合物
    const carbMatch = text.match(/(?:碳水化合物|碳水)[^\d]*(\d+\.?\d*)\s*g/);
    if (carbMatch) nutrition.carbohydrate = parseFloat(carbMatch[1]);

    // 蛋白质
    const proteinMatch = text.match(/(?:蛋白质|蛋白)[^\d]*(\d+\.?\d*)\s*g/);
    if (proteinMatch) nutrition.protein = parseFloat(proteinMatch[1]);

    return nutrition;
  }

  // 提取配料表
  private extractIngredients(text: string): string[] {
    // 支持多行配料表
    const ingredientsMatch = text.match(/(?:配料|原料)[表]?[：:]\s*([\s\S]*?)(?=\n\n|营养成份|营养成分|生产商|$)/);
    if (ingredientsMatch) {
      const raw = ingredientsMatch[1].replace(/\n/g, ' ');
      return raw.split(/[、,，;；]/).map(s => s.trim()).filter(s => s.length > 0);
    }
    return [];
  }

  // 提取生产商
  private extractManufacturer(text: string): string {
    const match = text.match(/(?:生产商|生产企业|制造商|生产者)[：:]\s*(.*?)(?:\n|$)/);
    return match ? match[1].trim() : '';
  }

  // 提取SC编号
  private extractScNumber(text: string): string {
    const match = text.match(/SC\d{14}/);
    return match ? match[0] : '';
  }

  // 提取委托方/受托方
  private extractOemInfo(text: string): OemInfo {
    const result: OemInfo = new OemInfo(
    const principalMatch = text.match(/(?:委托方|委托生产企业|委托单位)[：:]\s*(.*?)(?:\n|$)/);
    const trusteeMatch = text.match(/(?:受托方|受托生产企业|受托单位|实际生产企业)[：:]\s*(.*?)(?:\n|$)/);
    result.principal = principalMatch ? principalMatch[1].trim() : '';
    result.trustee = trusteeMatch ? trusteeMatch[1].trim() : '';
    return result;
  }

  // 提取条码（OCR可能扫到条码数字）
  private extractBarcode(text: string): string {
    // EAN-13条码
    const match = text.match(/\b(\d{13})\b/);
    return match ? match[1] : '';
  }
}
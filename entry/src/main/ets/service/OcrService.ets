// OCR服务 - 集成华为Core Vision Kit
// API参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/textrecognition-V5

import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.BasicServicesKit';
import { FoodLabel, FoodSource, NutritionPer100g } from '../model/FoodLabel';

const TAG = 'OcrService';
const DOMAIN_ZERO = 0;

// OCR识别结果
export interface OcrResult {
  text: string;
  confidence: number;
  blocks: OcrBlock[];
}

export interface OcrBlock {
  text: string;
  confidence: number;
  bounds: { left: number; top: number; right: number; bottom: number };
}

export class OcrService {
  private textRecognizer: textRecognition.TextRecognition | null = null;

  /**
   * 初始化OCR引擎（端侧优先，无需网络）
   * 应在应用启动时调用一次
   */
  async init(): Promise<void> {
    try {
      const textConfiguration: textRecognition.TextRecognitionConfiguration = {
        isOnline: false  // 端侧优先，离线可用
      };
      this.textRecognizer = await textRecognition.TextRecognition.create(textConfiguration);
      hilog.info(DOMAIN_ZERO, TAG, 'OCR engine initialized');
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'OCR init failed: %{public}s', JSON.stringify(error));
      this.textRecognizer = null;
    }
  }

  /**
   * 释放OCR引擎资源
   */
  async release(): Promise<void> {
    if (this.textRecognizer) {
      try {
        await this.textRecognizer.release();
        this.textRecognizer = null;
        hilog.info(DOMAIN_ZERO, TAG, 'OCR engine released');
      } catch (error) {
        hilog.error(DOMAIN_ZERO, TAG, 'OCR release failed: %{public}s', JSON.stringify(error));
      }
    }
  }

  /**
   * 从图片URI识别文字
   * @param imageUri 图片URI（由相机或相册返回）
   * @returns OCR识别结果
   */
  async recognizeText(imageUri: string): Promise<OcrResult> {
    if (!this.textRecognizer) {
      await this.init();
    }
    if (!this.textRecognizer) {
      hilog.error(DOMAIN_ZERO, TAG, 'OCR engine not available');
      return { text: '', confidence: 0, blocks: [] };
    }

    try {
      // 1. 从URI创建ImageSource
      const imageSource = image.createImageSource(imageUri);

      // 2. 解码为PixelMap
      const pixelMap = await imageSource.createPixelMap();

      // 3. 调用Core Vision Kit识别
      const textResult = await this.textRecognizer.recognize(pixelMap);

      // 4. 解析结果
      const result = this.parseOcrResult(textResult);

      // 5. 释放PixelMap
      pixelMap.release();

      hilog.info(DOMAIN_ZERO, TAG, 'OCR recognized %{public}d blocks', result.blocks.length);
      return result;
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'OCR recognize failed: %{public}s', JSON.stringify(error));
      return { text: '', confidence: 0, blocks: [] };
    }
  }

  /**
   * 从PixelMap识别文字（相机实时帧场景）
   * @param pixelMap 相机帧PixelMap
   * @returns OCR识别结果
   */
  async recognizeFromPixelMap(pixelMap: image.PixelMap): Promise<OcrResult> {
    if (!this.textRecognizer) {
      await this.init();
    }
    if (!this.textRecognizer) {
      return { text: '', confidence: 0, blocks: [] };
    }

    try {
      const textResult = await this.textRecognizer.recognize(pixelMap);
      return this.parseOcrResult(textResult);
    } catch (error) {
      hilog.error(DOMAIN_ZERO, TAG, 'OCR recognize from PixelMap failed: %{public}s', JSON.stringify(error));
      return { text: '', confidence: 0, blocks: [] };
    }
  }

  /**
   * 从OCR文本中提取食品标签结构化数据
   * @param ocrText OCR识别的原始文本
   * @returns 结构化的FoodLabel
   */
  extractFoodLabel(ocrText: string): FoodLabel {
    const label = new FoodLabel();
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
      const label = new FoodLabel();
      label.foodId = `food_${Date.now()}`;
      label.foodName = '识别失败，请手动输入';
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
    let fullText = '';
    let totalConfidence = 0;
    let blockCount = 0;

    // 遍历文本块
    if (textResult && textResult.textBlocks) {
      for (const block of textResult.textBlocks) {
        let blockText = '';
        // 遍历文本行
        if (block.textLines) {
          for (const line of block.textLines) {
            // 遍历文字单元
            if (line.words) {
              for (const word of line.words) {
                blockText += word.value + ' ';
              }
            }
            blockText += '\n';
          }
        }

        blockText = blockText.trim();
        if (blockText.length > 0) {
          blocks.push({
            text: blockText,
            confidence: block.confidence || 0,
            bounds: block.cornerPoints ? {
              left: Math.min(block.cornerPoints[0].x, block.cornerPoints[3].x),
              top: Math.min(block.cornerPoints[0].y, block.cornerPoints[1].y),
              right: Math.max(block.cornerPoints[1].x, block.cornerPoints[2].x),
              bottom: Math.max(block.cornerPoints[2].y, block.cornerPoints[3].y)
            } : { left: 0, top: 0, right: 0, bottom: 0 }
          });
          fullText += blockText + '\n';
          totalConfidence += (block.confidence || 0);
          blockCount++;
        }
      }
    }

    return {
      text: fullText.trim(),
      confidence: blockCount > 0 ? totalConfidence / blockCount : 0,
      blocks
    };
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
    return '未知食品';
  }

  // 提取营养成分
  private extractNutrition(text: string): NutritionPer100g {
    const nutrition: NutritionPer100g = {
      sodium: 0, sugar: 0, calories: 0, fat: 0,
      saturatedFat: 0, carbohydrate: 0, protein: 0
    };

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
  private extractOemInfo(text: string): { principal: string; trustee: string } {
    const principalMatch = text.match(/(?:委托方|委托生产企业|委托单位)[：:]\s*(.*?)(?:\n|$)/);
    const trusteeMatch = text.match(/(?:受托方|受托生产企业|受托单位|实际生产企业)[：:]\s*(.*?)(?:\n|$)/);
    return {
      principal: principalMatch ? principalMatch[1].trim() : '',
      trustee: trusteeMatch ? trusteeMatch[1].trim() : ''
    };
  }

  // 提取条码（OCR可能扫到条码数字）
  private extractBarcode(text: string): string {
    // EAN-13条码
    const match = text.match(/\b(\d{13})\b/);
    return match ? match[1] : '';
  }
}

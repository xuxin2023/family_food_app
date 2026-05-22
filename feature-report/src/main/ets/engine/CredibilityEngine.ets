import {
  FoodLabel, FoodSource, NutritionPer100g, CredibilityResult, DataGrade, RadarDimension, PublicQueryEntry
} from 'hsp_core';
// 信息透明度引擎 - V5深化：五维雷达模型 + 数据来源/完整度/新鲜度/验证状态
// A-E五级数据等级


const CORE_NUTRIENT_FIELDS = 7;
const BASE_CREDIBILITY_SCORE = 55;

export class CredibilityEngine {
  calculate(foodLabel: FoodLabel, crossVerified: boolean = false): CredibilityResult {
    const result = new CredibilityResult();
    let score = BASE_CREDIBILITY_SCORE;

    // === 雷达维度1：身份清晰度 ===
    const identityDim = new RadarDimension();
    identityDim.name = '身份清晰度';
    identityDim.status = '未识别';
    identityDim.grade = DataGrade.D;
    identityDim.detail = '';

    if (foodLabel.hasManufacturer()) {
      result.manufacturerClear = true;
      score += 20;
      identityDim.status = '清晰';
      identityDim.detail = `品牌方/生产商：${foodLabel.manufacturer}`;
      result.tips.push(`已识别实际生产企业：${foodLabel.manufacturer}`);
    } else {
      result.manufacturerMissing = true;
      score -= 20;
      identityDim.status = '未识别';
      identityDim.detail = '未识别到生产商信息';
      result.tips.push('未识别到生产商信息，包装身份信息不完整');
    }

    if (foodLabel.isOem()) {
      if (foodLabel.trustee.length > 0) {
        result.oemRelationClear = true;
        score += 15;
        identityDim.status = '清晰';
        identityDim.detail += `；委托方：${foodLabel.principal}，实际生产方：${foodLabel.trustee}`;
        result.tips.push(`本品为委托生产，委托方：${foodLabel.principal}，实际生产方：${foodLabel.trustee}`);
        result.tips.push('建议关注实际生产企业，而不只看品牌名');
      } else {
        result.oemTrusteeMissing = true;
        score -= 20;
        identityDim.status = '部分清晰';
        identityDim.detail += '；委托生产但受托方未识别';
        result.tips.push('本品为委托生产，但未识别到实际生产方，建议重点核验');
      }
    }

    result.radarDimensions.push(identityDim);

    // === 雷达维度2：许可信息 ===
    const licenseDim = new RadarDimension();
    licenseDim.name = '许可信息';
    licenseDim.status = '未识别';
    licenseDim.grade = DataGrade.D;
    licenseDim.detail = '';

    if (foodLabel.hasScNumber()) {
      result.scNumberClear = true;
      score += 20;
      licenseDim.status = '已识别';
      licenseDim.detail = `SC编号：${foodLabel.scNumber}`;
      result.tips.push(`SC编号：${foodLabel.scNumber}，可复制到官方平台核验`);
    } else {
      licenseDim.status = '未识别';
      licenseDim.detail = '未识别到SC编号';
      if (!result.manufacturerMissing) {
        result.tips.push('未识别到SC编号');
      }
    }

    result.radarDimensions.push(licenseDim);

    // === 雷达维度3：追溯入口 ===
    const traceDim = new RadarDimension();
    traceDim.name = '追溯入口';
    traceDim.status = '无';
    traceDim.grade = DataGrade.D;
    traceDim.detail = '';

    if (foodLabel.hasTraceCode()) {
      result.hasTraceCode = true;
      score += 10;
      traceDim.status = '有';
      traceDim.detail = `追溯码：${foodLabel.traceCode}`;
      result.tips.push(`追溯码：${foodLabel.traceCode}，可进一步查看批次追溯`);
    } else {
      traceDim.status = '未识别';
      traceDim.detail = '暂未识别到批次级追溯信息';
      result.tips.push('暂未识别到批次级追溯信息');
    }

    result.radarDimensions.push(traceDim);

    // === 雷达维度4：公开查询 ===
    const queryDim = new RadarDimension();
    queryDim.name = '公开查询';
    queryDim.status = '可查询';
    queryDim.grade = DataGrade.A;
    queryDim.detail = '提供官方查询入口';
    result.radarDimensions.push(queryDim);

    result.publicQueryEntries = this.generatePublicQueryEntries(foodLabel);

    // === 雷达维度5：表达边界 ===
    const riskDim = new RadarDimension();
    riskDim.name = '表达边界';
    riskDim.status = '克制';
    riskDim.grade = DataGrade.D;
    riskDim.detail = '只说公开信息和透明度，不做安全定罪';
    result.radarDimensions.push(riskDim);

    // ===== V5 深化：数据来源可信度 =====
    const sourceScore = this.evaluateSourceCredibility(foodLabel.source);
    score += sourceScore.bonus;
    result.tips.push(sourceScore.tip);

    // ===== V5 深化：数据完整度 =====
    const completeness = this.evaluateCompleteness(foodLabel.nutrition);
    score += completeness.bonus;
    result.tips.push(completeness.tip);

    // ===== V5 深化：数据新鲜度 =====
    const freshness = this.evaluateFreshness(foodLabel.identifiedAt);
    score += freshness.bonus;
    if (freshness.tip.length > 0) {
      result.tips.push(freshness.tip);
    }

    // ===== V5 深化：验证状态 =====
    if (crossVerified) {
      score += 10;
      result.tips.push('已通过NutriScore交叉验证，可信度提升');
    }

    result.score = Math.max(0, Math.min(100, score));
    result.overallGrade = this.determineOverallGrade(result, foodLabel.source, crossVerified);

    return result;
  }

  private evaluateSourceCredibility(source: FoodSource): SourceCredibilityResult {
    const r = new SourceCredibilityResult();
    switch (source) {
      case FoodSource.BARCODE_HIT:
        r.bonus = 15;
        r.tip = '数据来源：OpenFoodFacts官方库（高可信度）';
        break;
      case FoodSource.OFFLINE:
        r.bonus = 10;
        r.tip = '数据来源：离线库（中高可信度）';
        break;
      case FoodSource.OCR_RECOGNIZE:
        r.bonus = 3;
        r.tip = '数据来源：OCR识别（中等可信度，建议核验）';
        break;
      case FoodSource.LOCAL_CACHE:
        r.bonus = 8;
        r.tip = '数据来源：本地缓存';
        break;
      default:
        r.bonus = 0;
        r.tip = '数据来源：用户上传（基础可信度）';
        break;
    }
    return r;
  }

  private evaluateCompleteness(nutrition: NutritionPer100g): CompletenessResult {
    let filled = 0;
    if (nutrition.sodium > 0) filled++;
    if (nutrition.sugar > 0) filled++;
    if (nutrition.calories > 0) filled++;
    if (nutrition.fat > 0) filled++;
    if (nutrition.protein > 0) filled++;
    if (nutrition.fiber > 0) filled++;
    if (nutrition.carbohydrate > 0) filled++;

    const r = new CompletenessResult();
    r.filledFields = filled;
    r.coverage = filled / CORE_NUTRIENT_FIELDS;
    r.bonus = Math.round(r.coverage * 10);
    r.tip = `营养完整度：${filled}/${CORE_NUTRIENT_FIELDS}个核心字段已填写（${Math.round(r.coverage * 100)}%）`;
    return r;
  }

  private evaluateFreshness(identifiedAt: number): FreshnessResult {
    const r = new FreshnessResult();
    r.bonus = 0;
    r.tip = '';
    if (identifiedAt === 0) {
      return r;
    }
    const now = Date.now();
    const ageDays = (now - identifiedAt) / (1000 * 60 * 60 * 24);
    if (ageDays <= 1) {
      r.bonus = 5;
    } else if (ageDays <= 7) {
      r.bonus = 3;
    } else if (ageDays <= 30) {
      r.bonus = 1;
    } else {
      r.bonus = -2;
      r.tip = `数据已${Math.round(ageDays)}天未更新，建议刷新验证`;
    }
    return r;
  }

  private determineOverallGrade(result: CredibilityResult, source: FoodSource, crossVerified: boolean): DataGrade {
    if (source === FoodSource.BARCODE_HIT && crossVerified) {
      return DataGrade.A;
    }
    if (source === FoodSource.BARCODE_HIT) {
      return DataGrade.B;
    }
    if (source === FoodSource.OFFLINE && result.manufacturerClear && result.scNumberClear) {
      return DataGrade.B;
    }
    if (source === FoodSource.OFFLINE) {
      return DataGrade.C;
    }
    return DataGrade.D;
  }

  private generatePublicQueryEntries(foodLabel: FoodLabel): PublicQueryEntry[] {
    const entries: PublicQueryEntry[] = [];

    if (foodLabel.hasScNumber()) {
      const scEntry = new PublicQueryEntry();
      scEntry.name = '食品生产许可查询';
      scEntry.keyword = foodLabel.scNumber;
      scEntry.url = 'https://zwfw.samr.gov.cn/needSearch';
      scEntry.description = '复制SC编号到国家市场监管总局政务服务平台查询';
      entries.push(scEntry);
    }

    const cjEntry = new PublicQueryEntry();
    cjEntry.name = '食品安全抽检查询';
    cjEntry.keyword = foodLabel.foodName;
    cjEntry.url = 'https://spcjsac.gsxt.gov.cn/';
    cjEntry.description = '在国家市场监管总局抽检公布结果查询系统查询';
    entries.push(cjEntry);

    if (foodLabel.hasManufacturer()) {
      const mfrEntry = new PublicQueryEntry();
      mfrEntry.name = '生产企业信息查询';
      mfrEntry.keyword = foodLabel.manufacturer;
      mfrEntry.url = '';
      mfrEntry.description = `搜索"${foodLabel.manufacturer}"了解生产企业背景`;
      entries.push(mfrEntry);
    }

    return entries;
  }
}

class SourceCredibilityResult {
  bonus: number = 0;
  tip: string = '';
}

class CompletenessResult {
  filledFields: number = 0;
  coverage: number = 0;
  bonus: number = 0;
  tip: string = '';
}

class FreshnessResult {
  bonus: number = 0;
  tip: string = '';
}

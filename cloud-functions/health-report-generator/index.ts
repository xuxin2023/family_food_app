import { CloudDB } from '@hw-agcloud/cloud-database';

interface ReportRequest {
  memberId: string;
  dateRange: { start: string; end: string };
}

interface DailyDietRecord {
  date: string;
  foodName: string;
  calories: number;
  sodium: number;
  sugar: number;
  fat: number;
  protein: number;
  mealType: string;
  scanCount: number;
}

interface DailyAggregate {
  date: string;
  totalCalories: number;
  totalSodium: number;
  totalSugar: number;
  totalFat: number;
  totalProtein: number;
  mealCount: number;
  scanCount: number;
  foods: string[];
}

interface NutritionAssessment {
  overallScore: number;
  calorieStatus: string;
  sodiumStatus: string;
  sugarStatus: string;
  fatStatus: string;
  proteinStatus: string;
  suggestions: string[];
}

interface HealthReportResult {
  url: string;
  summary: string;
  assessment: NutritionAssessment;
  dailyRecords: DailyAggregate[];
  generatedAt: number;
}

const DAILY_CALORIE_TARGET = 2000;
const DAILY_SODIUM_LIMIT = 2000;
const DAILY_SUGAR_LIMIT = 50;
const DAILY_FAT_LIMIT = 65;
const DAILY_PROTEIN_TARGET = 60;

function aggregateByDay(records: DailyDietRecord[]): DailyAggregate[] {
  const dayMap = new Map<string, DailyAggregate>();

  for (const r of records) {
    let day = dayMap.get(r.date);
    if (!day) {
      day = {
        date: r.date,
        totalCalories: 0, totalSodium: 0, totalSugar: 0,
        totalFat: 0, totalProtein: 0, mealCount: 0,
        scanCount: 0, foods: []
      };
      dayMap.set(r.date, day);
    }
    day.totalCalories += r.calories;
    day.totalSodium += r.sodium;
    day.totalSugar += r.sugar;
    day.totalFat += r.fat;
    day.totalProtein += r.protein;
    day.mealCount += 1;
    day.scanCount += r.scanCount;
    if (day.foods.length < 10) {
      day.foods.push(r.foodName);
    }
  }

  return Array.from(dayMap.values()).sort((a, b) => a.date.localeCompare(b.date));
}

function assessNutrition(days: DailyAggregate[]): NutritionAssessment {
  if (days.length === 0) {
    return {
      overallScore: 0, calorieStatus: '无数据', sodiumStatus: '无数据',
      sugarStatus: '无数据', fatStatus: '无数据', proteinStatus: '无数据',
      suggestions: ['暂无饮食记录，请开始记录您的饮食数据']
    };
  }

  const avgCalories = days.reduce((s, d) => s + d.totalCalories, 0) / days.length;
  const avgSodium = days.reduce((s, d) => s + d.totalSodium, 0) / days.length;
  const avgSugar = days.reduce((s, d) => s + d.totalSugar, 0) / days.length;
  const avgFat = days.reduce((s, d) => s + d.totalFat, 0) / days.length;
  const avgProtein = days.reduce((s, d) => s + d.totalProtein, 0) / days.length;

  let score = 100;
  const suggestions: string[] = [];

  const calorieRatio = avgCalories / DAILY_CALORIE_TARGET;
  let calorieStatus: string;
  if (calorieRatio >= 0.85 && calorieRatio <= 1.15) {
    calorieStatus = '适中';
  } else if (calorieRatio < 0.85) {
    calorieStatus = '偏低';
    score -= 10;
    suggestions.push(`日均热量${Math.round(avgCalories)}kcal，低于推荐${DAILY_CALORIE_TARGET}kcal，建议适当增加`);
  } else {
    calorieStatus = '偏高';
    score -= Math.min(20, Math.round((calorieRatio - 1.15) * 50));
    suggestions.push(`日均热量${Math.round(avgCalories)}kcal，超过推荐${DAILY_CALORIE_TARGET}kcal，建议控制`);
  }

  const sodiumRatio = avgSodium / DAILY_SODIUM_LIMIT;
  let sodiumStatus: string;
  if (sodiumRatio <= 1.0) {
    sodiumStatus = '达标';
  } else if (sodiumRatio <= 1.3) {
    sodiumStatus = '略高';
    score -= 5;
    suggestions.push(`日均钠摄入${Math.round(avgSodium)}mg，略超限值${DAILY_SODIUM_LIMIT}mg，注意控盐`);
  } else {
    sodiumStatus = '超标';
    score -= 15;
    suggestions.push(`日均钠摄入${Math.round(avgSodium)}mg，严重超标，强烈建议减盐`);
  }

  const sugarRatio = avgSugar / DAILY_SUGAR_LIMIT;
  let sugarStatus: string;
  if (sugarRatio <= 1.0) {
    sugarStatus = '达标';
  } else {
    sugarStatus = '超标';
    score -= Math.min(15, Math.round((sugarRatio - 1.0) * 20));
    suggestions.push(`日均糖摄入${avgSugar.toFixed(1)}g，超过限值${DAILY_SUGAR_LIMIT}g，建议选择低糖食品`);
  }

  const fatRatio = avgFat / DAILY_FAT_LIMIT;
  let fatStatus: string;
  if (fatRatio <= 1.0) {
    fatStatus = '达标';
  } else {
    fatStatus = '超标';
    score -= Math.min(10, Math.round((fatRatio - 1.0) * 15));
    suggestions.push(`日均脂肪摄入${avgFat.toFixed(1)}g，超过限值${DAILY_FAT_LIMIT}g，建议控脂`);
  }

  const proteinRatio = avgProtein / DAILY_PROTEIN_TARGET;
  let proteinStatus: string;
  if (proteinRatio >= 0.8) {
    proteinStatus = '达标';
  } else {
    proteinStatus = '不足';
    score -= 8;
    suggestions.push(`日均蛋白质摄入${avgProtein.toFixed(1)}g，低于推荐${DAILY_PROTEIN_TARGET}g，建议增加优质蛋白`);
  }

  if (suggestions.length === 0) {
    suggestions.push('各项营养指标均达标，请继续保持均衡饮食！');
  }

  return {
    overallScore: Math.max(0, Math.min(100, score)),
    calorieStatus, sodiumStatus, sugarStatus, fatStatus, proteinStatus,
    suggestions
  };
}

export const handler = async (event: { body: string }): Promise<HealthReportResult> => {
  const request: ReportRequest = JSON.parse(event.body);
  const { memberId, dateRange } = request;

  let dietRecords: DailyDietRecord[] = [];

  try {
    const cloudDb = CloudDB.getInstance();
    const zoneId = 'default';
    const query = cloudDb.zone(zoneId)
      .collection('diet_records')
      .where({ memberId, date: { $gte: dateRange.start, $lte: dateRange.end } })
      .orderBy('date', 'asc');

    const results = await query.get();
    dietRecords = results.map((r: Record<string, unknown>) => ({
      date: String(r.date || ''),
      foodName: String(r.foodName || ''),
      calories: Number(r.calories || 0),
      sodium: Number(r.sodium || 0),
      sugar: Number(r.sugar || 0),
      fat: Number(r.fat || 0),
      protein: Number(r.protein || 0),
      mealType: String(r.mealType || ''),
      scanCount: Number(r.scanCount || 0)
    }));
  } catch (dbError) {
    console.warn('CloudDB query failed, using empty records:', dbError);
  }

  const dailyRecords = aggregateByDay(dietRecords);
  const assessment = assessNutrition(dailyRecords);

  const summaryLines: string[] = [];
  summaryLines.push(`健康报告：${memberId}，周期 ${dateRange.start} ~ ${dateRange.end}`);
  summaryLines.push(`综合评分：${assessment.overallScore}/100`);
  summaryLines.push(`热量：${assessment.calorieStatus}，钠：${assessment.sodiumStatus}，糖：${assessment.sugarStatus}，脂肪：${assessment.fatStatus}，蛋白质：${assessment.proteinStatus}`);
  if (assessment.suggestions.length > 0) {
    summaryLines.push('建议：' + assessment.suggestions.join('；'));
  }

  const reportUrl = `https://familyfood-api.cn-north-4.myhuaweicloud.com/reports/${memberId}_${Date.now()}.pdf`;

  return {
    url: reportUrl,
    summary: summaryLines.join('\n'),
    assessment,
    dailyRecords,
    generatedAt: Date.now()
  };
};

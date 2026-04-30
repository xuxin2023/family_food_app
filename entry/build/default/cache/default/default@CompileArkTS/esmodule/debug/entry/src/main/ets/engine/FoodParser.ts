import type { FoodNutrition } from '../model/FoodAdapterTypes';
import type { FoodLabel } from '../model/FoodLabel';
export class FoodParser {
    /**
     * 从SQLite查询结果行转换为标准化的FoodNutrition对象
     * @param row - SQLite查询结果行（键值对）
     * @returns 标准化的FoodNutrition对象
     */
    static parseFromDbRow(row: Record<string, Object>): FoodNutrition {
        // 安全获取字符串字段：null/undefined时返回空字符串
        const safeString = (val: Object | undefined | null): string => {
            return (val !== null && val !== undefined) ? String(val) : '';
        };
        // 安全获取数字字段：null/undefined时返回0
        const safeNumber = (val: Object | undefined | null): number => {
            if (val === null || val === undefined) {
                return 0;
            }
            const num = Number(val);
            return isNaN(num) ? 0 : num;
        };
        // 安全获取布尔字段：数字0/1或布尔值
        const safeBool = (val: Object | undefined | null): boolean => {
            if (val === null || val === undefined) {
                return false;
            }
            if (typeof val === 'boolean') {
                return val;
            }
            const num = Number(val);
            return num === 1;
        };
        // 字段映射：数据库列名 → FoodNutrition属性
        const nutrition: FoodNutrition = {
            productName: safeString(row['product_name']),
            brand: safeString(row['brand']),
            netWeight_g: safeNumber(row['net_weight_g']),
            energy_kj: safeNumber(row['energy_kj']),
            protein_g: safeNumber(row['protein_g']),
            fat_g: safeNumber(row['fat_g']),
            saturatedFat_g: safeNumber(row['saturated_fat_g']),
            transFat_g: safeNumber(row['trans_fat_g']),
            carbs_g: safeNumber(row['carbs_g']),
            sugar_g: safeNumber(row['sugar_g']),
            sodium_mg: safeNumber(row['sodium_mg']),
            allergens: FoodParser.parseList(safeString(row['allergens'])),
            isSugarFree: safeBool(row['is_sugar_free']),
            isSucroseFree: safeBool(row['is_sucrose_free']),
            sweeteners: FoodParser.parseList(safeString(row['sweeteners'])),
            manufacturer: safeString(row['manufacturer']),
            entrustInfo: safeString(row['entrust_info']),
            scNumber: safeString(row['sc_number']),
            dataCompleteness: safeString(row['data_completeness'])
        };
        return nutrition;
    }
    /**
     * 将逗号分隔的字符串解析为字符串数组
     * 自动去除前后空格，过滤空项
     * @param str - 逗号分隔的原始字符串
     * @returns 解析后的字符串数组
     */
    private static parseList(str: string | null | undefined): string[] {
        // 边界处理：null、undefined或空字符串时返回空数组
        if (str === null || str === undefined || str.trim().length === 0) {
            return [];
        }
        // 按逗号分割，去除每个元素的前后空格，过滤掉空字符串
        return str.split(',')
            .map(item => item.trim())
            .filter(item => item.length > 0);
    }
    /**
     * 千焦（kJ）转千卡（kcal）
     * 转换公式：1 kcal = 4.184 kJ
     * @param kj - 能量值（千焦）
     * @returns 转换后的能量值（千卡），四舍五入取整
     */
    static kjToKcal(kj: number): number {
        // 边界处理：负数或0时直接返回0
        if (kj <= 0) {
            return 0;
        }
        // 除以4.184，四舍五入取整
        return Math.round(kj / 4.184);
    }
    /**
     * 将FoodLabel对象转换为FoodNutrition对象
     * 用于统一评分服务的输入
     * @param label - FoodLabel对象
     * @returns 标准化的FoodNutrition对象
     */
    static convertFromFoodLabel(label: FoodLabel): FoodNutrition {
        // 构建委托生产信息
        let entrustInfo = '';
        if (label.principal.length > 0 && label.trustee.length > 0) {
            entrustInfo = `委托方：${label.principal}；受委托方：${label.trustee}`;
        }
        else if (label.principal.length > 0) {
            entrustInfo = `委托方：${label.principal}`;
        }
        else if (label.trustee.length > 0) {
            entrustInfo = `受委托方：${label.trustee}`;
        }
        return {
            productName: label.foodName,
            brand: '',
            netWeight_g: 0,
            energy_kj: Math.round(label.nutrition.calories * 4.184),
            protein_g: label.nutrition.protein,
            fat_g: label.nutrition.fat,
            saturatedFat_g: label.nutrition.saturatedFat,
            transFat_g: 0,
            carbs_g: label.nutrition.carbohydrate,
            sugar_g: label.nutrition.sugar,
            sodium_mg: label.nutrition.sodium,
            allergens: label.allergenHints,
            isSugarFree: label.nutrition.sugar <= 0.5,
            isSucroseFree: false,
            sweeteners: [],
            manufacturer: label.manufacturer,
            entrustInfo: entrustInfo,
            scNumber: label.scNumber,
            dataCompleteness: 'partial'
        };
    }
}

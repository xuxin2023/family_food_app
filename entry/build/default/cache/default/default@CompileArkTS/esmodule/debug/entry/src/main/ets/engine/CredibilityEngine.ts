import type { FoodLabel } from '../model/FoodLabel';
import { CredibilityResult, DataGrade, PublicQueryEntry } from "@bundle:com.familyfood.helper/entry/ets/model/CredibilityResult";
import type { RadarDimension } from "@bundle:com.familyfood.helper/entry/ets/model/CredibilityResult";
export class CredibilityEngine {
    // 计算食品信息透明度（雷达模型）
    calculate(foodLabel: FoodLabel): CredibilityResult {
        const result = new CredibilityResult();
        let score = 55; // 基础分
        // === 雷达维度1：身份清晰度 ===
        const identityDim: RadarDimension = {
            name: '身份清晰度',
            status: '未识别',
            grade: DataGrade.D,
            detail: ''
        };
        if (foodLabel.hasManufacturer()) {
            result.manufacturerClear = true;
            score += 20;
            identityDim.status = '清晰';
            identityDim.detail = `品牌方/生产商：${foodLabel.manufacturer}`;
            result.tips.push(`已识别实际生产企业：${foodLabel.manufacturer}`);
        }
        else {
            result.manufacturerMissing = true;
            score -= 20;
            identityDim.status = '未识别';
            identityDim.detail = '未识别到生产商信息';
            result.tips.push('未识别到生产商信息，包装身份信息不完整');
        }
        // 委托/受托关系
        if (foodLabel.isOem()) {
            if (foodLabel.trustee.length > 0) {
                result.oemRelationClear = true;
                score += 15;
                identityDim.status = '清晰';
                identityDim.detail += `；委托方：${foodLabel.principal}，实际生产方：${foodLabel.trustee}`;
                result.tips.push(`本品为委托生产，委托方：${foodLabel.principal}，实际生产方：${foodLabel.trustee}`);
                result.tips.push('建议关注实际生产企业，而不只看品牌名');
            }
            else {
                result.oemTrusteeMissing = true;
                score -= 20;
                identityDim.status = '部分清晰';
                identityDim.detail += '；委托生产但受托方未识别';
                result.tips.push('本品为委托生产，但未识别到实际生产方，建议重点核验');
            }
        }
        result.radarDimensions.push(identityDim);
        // === 雷达维度2：许可信息 ===
        const licenseDim: RadarDimension = {
            name: '许可信息',
            status: '未识别',
            grade: DataGrade.D,
            detail: ''
        };
        if (foodLabel.hasScNumber()) {
            result.scNumberClear = true;
            score += 20;
            licenseDim.status = '已识别';
            licenseDim.detail = `SC编号：${foodLabel.scNumber}`;
            result.tips.push(`SC编号：${foodLabel.scNumber}，可复制到官方平台核验`);
        }
        else {
            licenseDim.status = '未识别';
            licenseDim.detail = '未识别到SC编号';
            if (!result.manufacturerMissing) {
                result.tips.push('未识别到SC编号');
            }
        }
        result.radarDimensions.push(licenseDim);
        // === 雷达维度3：追溯入口 ===
        const traceDim: RadarDimension = {
            name: '追溯入口',
            status: '无',
            grade: DataGrade.D,
            detail: ''
        };
        if (foodLabel.hasTraceCode()) {
            result.hasTraceCode = true;
            score += 10;
            traceDim.status = '有';
            traceDim.detail = `追溯码：${foodLabel.traceCode}`;
            result.tips.push(`追溯码：${foodLabel.traceCode}，可进一步查看批次追溯`);
        }
        else {
            traceDim.status = '未识别';
            traceDim.detail = '暂未识别到批次级追溯信息';
            result.tips.push('暂未识别到批次级追溯信息');
        }
        result.radarDimensions.push(traceDim);
        // === 雷达维度4：公开查询 ===
        const queryDim: RadarDimension = {
            name: '公开查询',
            status: '可查询',
            grade: DataGrade.A,
            detail: '提供官方查询入口'
        };
        result.radarDimensions.push(queryDim);
        // 生成公开查询入口
        result.publicQueryEntries = this.generatePublicQueryEntries(foodLabel);
        // === 雷达维度5：表达边界 ===
        const riskDim: RadarDimension = {
            name: '表达边界',
            status: '克制',
            grade: DataGrade.D,
            detail: '只说公开信息和透明度，不做安全定罪'
        };
        result.radarDimensions.push(riskDim);
        // 限制分数范围
        result.score = Math.max(0, Math.min(100, score));
        // 确定整体数据等级
        result.overallGrade = this.determineOverallGrade(result);
        return result;
    }
    // 确定整体数据等级
    private determineOverallGrade(result: CredibilityResult): DataGrade {
        // 如果有官方数据接入（未来扩展），则为A
        // 如果品牌核验过（未来扩展），则为B
        // 当前默认为D（用户上传）
        if (result.manufacturerClear && result.scNumberClear && result.oemRelationClear) {
            return DataGrade.D; // 信息完整但来源是用户上传
        }
        return DataGrade.D;
    }
    // 生成公开查询入口
    private generatePublicQueryEntries(foodLabel: FoodLabel): PublicQueryEntry[] {
        const entries: PublicQueryEntry[] = [];
        // SC编号查询
        if (foodLabel.hasScNumber()) {
            const scEntry = new PublicQueryEntry();
            scEntry.name = '食品生产许可查询';
            scEntry.keyword = foodLabel.scNumber;
            scEntry.url = 'https://zwfw.samr.gov.cn/needSearch';
            scEntry.description = '复制SC编号到国家市场监管总局政务服务平台查询';
            entries.push(scEntry);
        }
        // 抽检查询
        const cjEntry = new PublicQueryEntry();
        cjEntry.name = '食品安全抽检查询';
        cjEntry.keyword = foodLabel.foodName;
        cjEntry.url = 'https://spcjsac.gsxt.gov.cn/';
        cjEntry.description = '在国家市场监管总局抽检公布结果查询系统查询';
        entries.push(cjEntry);
        // 生产商查询
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

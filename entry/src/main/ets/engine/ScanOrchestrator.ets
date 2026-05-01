// ScanOrchestrator.ets
// 扫描编排器 - 管理多步骤扫描流程：获取图片 → 预处理 → 识别 → 适配计算 → 生成报告

import { FoodLabel, NutritionPer100g, FoodSource } from '../model/FoodLabel';
import { FamilyProfile } from '../model/FamilyProfile';
import { Recommendation, RecommendLevel, LevelColor } from '../model/Recommendation';
import { DataService, FullReportResult } from '../service/DataService';

const TAG = 'ScanOrchestrator';

/**
 * 扫描阶段枚举
 */
export enum ScanPhase {
  IDLE = 'idle',
  CAPTURING = 'capturing',
  PREPROCESSING = 'preprocessing',
  RECOGNIZING = 'recognizing',
  CALCULATING = 'calculating',
  COMPLETED = 'completed',
  ERROR = 'error'
}

/**
 * 扫描进度回调
 */
export interface ScanProgressCallback {
  onPhaseChange(phase: ScanPhase, message: string): void;
  onComplete(result: FullReportResult): void;
  onError(error: string): void;
}

let orchestratorInstance: ScanOrchestrator | null = null;

export class ScanOrchestrator {
  private currentPhase: ScanPhase = ScanPhase.IDLE;
  private dataService: DataService = DataService.getInstance();

  static getInstance(): ScanOrchestrator {
    if (orchestratorInstance === null) {
      orchestratorInstance = new ScanOrchestrator();
    }
    return orchestratorInstance;
  }

  /**
   * 执行完整扫描流程
   * @param imageUri 图片URI
   * @param barcode 条码（可选）
   * @param members 家庭成员列表
   * @param callback 进度回调
   */
  async executeScan(
    imageUri: string,
    barcode: string,
    members: FamilyProfile[],
    callback: ScanProgressCallback
  ): Promise<void> {
    try {
      // 阶段1: 捕获图片
      this.setPhase(ScanPhase.CAPTURING, '正在获取图片...', callback);

      // 检查图片有效性
      if (!imageUri || imageUri.length === 0) {
        // 如果仅有条码，直接跳转到查询
        if (barcode && barcode.length > 0) {
          return this.executeBarcodeLookup(barcode, members, callback);
        }
        callback.onError('未提供图片或条码');
        return;
      }

      // 阶段2: 预处理
      this.setPhase(ScanPhase.PREPROCESSING, '正在预处理图片...', callback);
      // 模拟预处理延时
      await this.delay(300);

      // 阶段3: 识别
      this.setPhase(ScanPhase.RECOGNIZING, '正在识别食品标签...', callback);
      const result = await this.dataService.scanAndLookup(barcode, imageUri, members);

      if (result === null) {
        callback.onError('识别失败，请重试或手动输入');
        return;
      }

      // 阶段4: 适配计算
      this.setPhase(ScanPhase.CALCULATING, '正在计算适配建议...', callback);
      await this.delay(200);

      // 阶段5: 完成
      this.setPhase(ScanPhase.COMPLETED, '已完成', callback);
      callback.onComplete(result);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : '扫描过程发生错误';
      callback.onError(errMsg);
    }
  }

  /**
   * 仅通过条码查询
   */
  private async executeBarcodeLookup(
    barcode: string,
    members: FamilyProfile[],
    callback: ScanProgressCallback
  ): Promise<void> {
    try {
      this.setPhase(ScanPhase.RECOGNIZING, '正在查询商品信息...', callback);
      const result = await this.dataService.scanAndLookup(barcode, undefined, members);

      if (result === null) {
        callback.onError('未找到该商品信息');
        return;
      }

      this.setPhase(ScanPhase.CALCULATING, '正在计算适配建议...', callback);
      await this.delay(200);

      this.setPhase(ScanPhase.COMPLETED, '已完成', callback);
      callback.onComplete(result);
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : '查询过程发生错误';
      callback.onError(errMsg);
    }
  }

  /**
   * 获取当前阶段
   */
  getCurrentPhase(): ScanPhase {
    return this.currentPhase;
  }

  /**
   * 重置编排器状态
   */
  reset(): void {
    this.currentPhase = ScanPhase.IDLE;
  }

  private setPhase(
    phase: ScanPhase,
    message: string,
    callback: ScanProgressCallback
  ): void {
    this.currentPhase = phase;
    callback.onPhaseChange(phase, message);
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

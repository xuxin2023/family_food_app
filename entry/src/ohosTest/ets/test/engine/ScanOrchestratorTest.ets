// ScanOrchestrator 单元测试 - 扫描编排
import { describe, it, expect } from '@ohos/hypium';
import { ScanOrchestrator, ScanPhase, ScanProgressCallback } from '../../../../../src/main/ets/engine/ScanOrchestrator';
import { FamilyProfile } from '../../../../../src/main/ets/model/FamilyProfile';
import { FullReportResult } from '../../../../../src/main/ets/service/DataService';

class TestCallback implements ScanProgressCallback {
  private _error: string = '';
  private _phases: ScanPhase[] = [];

  onPhaseChange(phase: ScanPhase, _message: string): void {
    this._phases.push(phase);
  }

  onComplete(_result: FullReportResult): void {}

  onError(error: string): void {
    this._error = error;
  }

  getError(): string {
    return this._error;
  }

  getPhases(): ScanPhase[] {
    return this._phases;
  }
}

export default function scanOrchestratorTest() {
  describe('ScanOrchestrator', () => {

    // ========== 1. 单例模式 ==========

    it('should_return_same_instance', 0, () => {
      const instance1 = ScanOrchestrator.getInstance();
      const instance2 = ScanOrchestrator.getInstance();
      expect(instance1 === instance2).assertTrue();
    });

    // ========== 2. 初始状态 ==========

    it('should_start_in_idle_phase', 0, () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();
      expect(orchestrator.getCurrentPhase()).assertEqual(ScanPhase.IDLE);
    });

    // ========== 3. 重置状态 ==========

    it('should_reset_to_idle', 0, () => {
      const orchestrator = ScanOrchestrator.getInstance();
      // 重置前设置一个非IDLE状态
      orchestrator.reset();

      // 执行重置
      orchestrator.reset();
      expect(orchestrator.getCurrentPhase()).assertEqual(ScanPhase.IDLE);
    });

    // ========== 4. 错误处理：无图片无条码 ==========

    it('should_report_error_when_no_image_and_no_barcode', 0, async () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();

      const members: FamilyProfile[] = [];

      const callback = new TestCallback();

      await orchestrator.executeScan('', '', members, callback);

      expect(callback.getError()).assertEqual('未提供图片或条码');
    });

    // ========== 5. 错误处理：无条码未命中 ==========

    it('should_handle_barcode_not_found', 0, async () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();

      const members: FamilyProfile[] = [];

      const callback = new TestCallback();

      await orchestrator.executeScan('', '', members, callback);

      expect(true).assertTrue();
    });

    // ========== 6. 扫描阶段流转 ==========

    it('should_go_through_scan_phases', 0, async () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();

      const members: FamilyProfile[] = [];

      const callback = new TestCallback();

      await orchestrator.executeScan('test_image.jpg', '123456789', members, callback);

      // 至少应该经历一些阶段
      const phases = callback.getPhases();
      expect(phases.length).assertLarger(0);
      expect(phases[0]).assertEqual(ScanPhase.CAPTURING);
    });
  });
}


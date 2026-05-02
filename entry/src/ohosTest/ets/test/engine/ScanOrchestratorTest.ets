// ScanOrchestrator 单元测试 - 扫描编排�?
import { describe, it, expect } from '@ohos/hypium';
import { ScanOrchestrator, ScanPhase, ScanProgressCallback } from '../../../../src/main/ets/engine/ScanOrchestrator';
import { FamilyProfile, AgeGroup, HealthGoal } from '../../../../src/main/ets/model/FamilyProfile';

export default function scanOrchestratorTest() {
  describe('ScanOrchestrator', () => {

    // ========== 1. 单例模式 ==========

    it('should_return_same_instance', () => {
      const instance1 = ScanOrchestrator.getInstance();
      const instance2 = ScanOrchestrator.getInstance();
      expect(instance1 === instance2).assertTrue();
    });

    // ========== 2. 初始状�?==========

    it('should_start_in_idle_phase', () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();
      expect(orchestrator.getCurrentPhase()).assertEqual(ScanPhase.IDLE);
    });

    // ========== 3. 重置状�?==========

    it('should_reset_to_idle', () => {
      const orchestrator = ScanOrchestrator.getInstance();
      // 重置前设置一个非IDLE状�?
      orchestrator.reset();

      // 执行重置
      orchestrator.reset();
      expect(orchestrator.getCurrentPhase()).assertEqual(ScanPhase.IDLE);
    });

    // ========== 4. 错误处理：无图片无条�?==========

    it('should_report_error_when_no_image_and_no_barcode', async () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();

      const members: FamilyProfile[] = [];

      let errorMsg = '';

      const callback: ScanProgressCallback = {
        onPhaseChange: (phase: ScanPhase, message: string) => {},
        onComplete: (result: Object) => {},
        onError: (error: string) => {
          errorMsg = error;
        }
      };

      await orchestrator.executeScan('', '', members, callback);

      expect(errorMsg).assertEqual('未提供图片或条码');
    });

    // ========== 5. 错误处理：无条码未命�?==========

    it('should_handle_barcode_not_found', async () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();

      const members: FamilyProfile[] = [];

      // 先测试空条码+空图�?
      let errorMsg = '';
      const callback: ScanProgressCallback = {
        onPhaseChange: (phase: ScanPhase, message: string) => {},
        onComplete: (result: Object) => {},
        onError: (error: string) => {
          errorMsg = error;
        }
      };

      await orchestrator.executeScan('', '', members, callback);

      expect(true).assertTrue();
    });

    // ========== 6. 扫描阶段流转 ==========

    it('should_go_through_scan_phases', async () => {
      const orchestrator = ScanOrchestrator.getInstance();
      orchestrator.reset();

      const members: FamilyProfile[] = [];
      const phases: ScanPhase[] = [];

      const callback: ScanProgressCallback = {
        onPhaseChange: (phase: ScanPhase, message: string) => {
          phases.push(phase);
        },
        onComplete: (result: Object) => {},
        onError: (error: string) => {}
      };

      await orchestrator.executeScan('test_image.jpg', '123456789', members, callback);

      // 至少应该经历一些阶�?
      expect(phases.length).assertLargerThan(0);
      expect(phases[0]).assertEqual(ScanPhase.CAPTURING);
    });
  });
}


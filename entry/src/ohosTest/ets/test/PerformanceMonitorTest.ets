import { describe, it, expect } from '@ohos/hypium';
import { PerformanceMonitor, PerfMetric, PerfPercentiles, PerfAlert } from '../../../../../../hsp_core/src/main/ets/utils/PerformanceMonitor';

export default function performanceMonitorTest() {
  describe('PerformanceMonitorTest', () => {
    it('should_measure_span_duration', 0, () => {
      const monitor = PerformanceMonitor.getInstance();
      monitor.init();
      monitor.startSpan('test_op');
      const duration = monitor.endSpan('test_op');
      expect(duration).assertGreater(-1);
    });

    it('should_return_negative_for_unknown_span_end', 0, () => {
      const monitor = PerformanceMonitor.getInstance();
      const duration = monitor.endSpan('nonexistent_span');
      expect(duration).assertEqual(-1);
    });

    it('should_track_operation_directly', 0, () => {
      const monitor = PerformanceMonitor.getInstance();
      const startTime = Date.now() - 100;
      const duration = monitor.trackOperation('direct_op', startTime);
      expect(duration).assertGreater(0);
    });
  });
}

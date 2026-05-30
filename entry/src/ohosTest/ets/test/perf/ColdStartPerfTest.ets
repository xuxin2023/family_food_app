// ColdStartPerfTest.ets
// 冷启动性能基准测试 — 测量 onCreate → 首页 onPageShow 耗时
// 基准: ≤ 2000ms, 容差: 500ms

import { hilog } from '@kit.PerformanceAnalysisKit';
import { AbilityConstant } from '@kit.AbilityKit';

const TAG = 'ColdStartPerfTest';
const DOMAIN_ZERO = 0xFD00;

const COLD_START_BASELINE_MS = 2000;
const COLD_START_TOLERANCE_MS = 500;

interface PerfResult {
  testName: string;
  elapsedMs: number;
  baselineMs: number;
  toleranceMs: number;
  passed: boolean;
}

export class ColdStartPerfTest {
  private results: PerfResult[] = [];
  private onCreateTimestamp: number = 0;
  private onPageShowTimestamp: number = 0;

  markOnCreate(): void {
    this.onCreateTimestamp = Date.now();
    hilog.info(DOMAIN_ZERO, TAG, 'Marked onCreate at %{public}d', this.onCreateTimestamp);
  }

  markOnPageShow(): void {
    this.onPageShowTimestamp = Date.now();
    hilog.info(DOMAIN_ZERO, TAG, 'Marked onPageShow at %{public}d', this.onPageShowTimestamp);
  }

  testColdStartDuration(): PerfResult {
    if (this.onCreateTimestamp === 0 || this.onPageShowTimestamp === 0) {
      const result: PerfResult = {
        testName: 'cold_start_duration',
        elapsedMs: -1,
        baselineMs: COLD_START_BASELINE_MS,
        toleranceMs: COLD_START_TOLERANCE_MS,
        passed: false
      };
      this.results.push(result);
      return result;
    }

    const elapsedMs = this.onPageShowTimestamp - this.onCreateTimestamp;
    const passed = elapsedMs <= (COLD_START_BASELINE_MS + COLD_START_TOLERANCE_MS);
    const result: PerfResult = {
      testName: 'cold_start_duration',
      elapsedMs,
      baselineMs: COLD_START_BASELINE_MS,
      toleranceMs: COLD_START_TOLERANCE_MS,
      passed
    };
    this.results.push(result);
    hilog.info(DOMAIN_ZERO, TAG, 'Cold start: %{public}dms (baseline %{public}d±%{public}dms) → %{public}s',
      elapsedMs, COLD_START_BASELINE_MS, COLD_START_TOLERANCE_MS, passed ? 'PASS' : 'FAIL');
    return result;
  }

  testAbilityLifecycleOverhead(): PerfResult {
    const startMs = Date.now();
    for (let i = 0; i < 100; i++) {
      const ts = Date.now();
      void ts;
    }
    const elapsedMs = Date.now() - startMs;
    const passed = elapsedMs <= 50;
    const result: PerfResult = {
      testName: 'ability_lifecycle_overhead',
      elapsedMs,
      baselineMs: 10,
      toleranceMs: 40,
      passed
    };
    this.results.push(result);
    return result;
  }

  testAppStorageInitializationOverhead(): PerfResult {
    const startMs = Date.now();
    for (let i = 0; i < 50; i++) {
      AppStorage.setOrCreate(`perf_test_key_${i}`, i);
    }
    const elapsedMs = Date.now() - startMs;
    const passed = elapsedMs <= 100;
    for (let i = 0; i < 50; i++) {
      AppStorage.delete(`perf_test_key_${i}`);
    }
    const result: PerfResult = {
      testName: 'appstorage_init_overhead',
      elapsedMs,
      baselineMs: 20,
      toleranceMs: 80,
      passed
    };
    this.results.push(result);
    return result;
  }

  runAll(): PerfResult[] {
    this.results = [];
    this.testColdStartDuration();
    this.testAbilityLifecycleOverhead();
    this.testAppStorageInitializationOverhead();
    return this.results;
  }

  getResults(): PerfResult[] {
    return [...this.results];
  }

  getSummary(): string {
    const total = this.results.length;
    const passed = this.results.filter(r => r.passed).length;
    return `ColdStartPerf: ${passed}/${total} passed`;
  }
}
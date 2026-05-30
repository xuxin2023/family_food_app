// PerfTestRunner.ets
// 性能基准测试统一入口 — 聚合冷启动、引擎计算、页面切换三项测试

import { hilog } from '@kit.PerformanceAnalysisKit';
import { ColdStartPerfTest } from './ColdStartPerfTest';
import { EngineCalcPerfTest } from './EngineCalcPerfTest';
import { PageTransitionPerfTest } from './PageTransitionPerfTest';

const TAG = 'PerfTestRunner';
const DOMAIN_ZERO = 0xFD00;

export interface PerfTestSummary {
  coldStart: string;
  engineCalc: string;
  pageTransition: string;
  allPassed: boolean;
}

export class PerfTestRunner {
  private coldStartTest: ColdStartPerfTest = new ColdStartPerfTest();
  private engineCalcTest: EngineCalcPerfTest = new EngineCalcPerfTest();
  private pageTransitionTest: PageTransitionPerfTest = new PageTransitionPerfTest();

  getColdStartTest(): ColdStartPerfTest {
    return this.coldStartTest;
  }

  getEngineCalcTest(): EngineCalcPerfTest {
    return this.engineCalcTest;
  }

  getPageTransitionTest(): PageTransitionPerfTest {
    return this.pageTransitionTest;
  }

  runAll(): PerfTestSummary {
    hilog.info(DOMAIN_ZERO, TAG, '===== Performance Test Suite Start =====');

    this.coldStartTest.runAll();
    this.engineCalcTest.runAll();
    this.pageTransitionTest.runAll();

    const coldStartSummary = this.coldStartTest.getSummary();
    const engineCalcSummary = this.engineCalcTest.getSummary();
    const pageTransitionSummary = this.pageTransitionTest.getSummary();

    const allPassed = coldStartSummary.includes('passed') &&
      !coldStartSummary.includes('0/') &&
      engineCalcSummary.includes('passed') &&
      !engineCalcSummary.includes('0/') &&
      pageTransitionSummary.includes('passed') &&
      !pageTransitionSummary.includes('0/');

    hilog.info(DOMAIN_ZERO, TAG, '  %s', coldStartSummary);
    hilog.info(DOMAIN_ZERO, TAG, '  %s', engineCalcSummary);
    hilog.info(DOMAIN_ZERO, TAG, '  %s', pageTransitionSummary);
    hilog.info(DOMAIN_ZERO, TAG, '===== Performance Test Suite End: %s =====',
      allPassed ? 'ALL PASSED' : 'SOME FAILED');

    return {
      coldStart: coldStartSummary,
      engineCalc: engineCalcSummary,
      pageTransition: pageTransitionSummary,
      allPassed
    };
  }
}
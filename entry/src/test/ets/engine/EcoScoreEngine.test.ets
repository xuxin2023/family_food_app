// EcoScoreEngine.test.ets
// EcoScore 生态评分引擎单元测试

import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { EcoScoreEngine, EcoScoreResult, EcoScoreGrade } from 'hsp_rating';

export default function ecoScoreTest(): TestSuite {
  const suite = new TestSuite('EcoScoreEngine');

  suite.addTest(new TestCase('unknownGrade_whenNoData', () => {
    const result = EcoScoreEngine.estimateFromLabels([], '', '');
    expect(result.grade).assertEqual(EcoScoreGrade.UNKNOWN);
  }));

  suite.addTest(new TestCase('gradeA_whenOrganicLabel', () => {
    const result = EcoScoreEngine.estimateFromLabels(['organic', 'france'], '', '');
    expect(result.score).assertTrue(result.score >= 70);
  }));

  suite.addTest(new TestCase('lowScore_whenHighImpactLabels', () => {
    const result = EcoScoreEngine.estimateFromLabels(['meat', 'imported'], '', '');
    expect(result.score).assertTrue(result.score < 40);
  }));

  suite.addTest(new TestCase('confidenceBelow1_forEstimate', () => {
    const result = EcoScoreEngine.estimateFromLabels(['france'], '', '');
    expect(result.confidence).assertTrue(result.confidence < 1.0);
    expect(result.confidence).assertTrue(result.confidence > 0);
  }));

  suite.addTest(new TestCase('originAffectsScore', () => {
    const local = EcoScoreEngine.estimateFromLabels([], '', 'france');
    const remote = EcoScoreEngine.estimateFromLabels([], '', 'argentina');
    expect(local.score).assertTrue(local.score > remote.score);
  }));

  return suite;
}

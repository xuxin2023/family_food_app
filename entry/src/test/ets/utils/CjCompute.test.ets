// CjCompute.test.ets
// V5 仓颉计算引擎 ArkTS fallback 路径单元测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { CjCompute } from 'hsp_core_cj';

export default function cjComputeTest(): TestSuite {
  const suite: TestSuite = new TestSuite(

  suite.addTest(new TestCase('cosineSimilarity_identical vectors', () => {
    const a = [1, 2, 3];
    const b = [1, 2, 3];
    const sim = CjCompute.cosineSimilarity(a, b);
    expect(Number(sim.toFixed(6))).assertEqual(1.0);
  }));

  suite.addTest(new TestCase('cosineSimilarity_orthogonal', () => {
    const a = [1, 0, 0, 0];
    const b = [0, 0, 0, 1];
    const sim = CjCompute.cosineSimilarity(a, b);
    expect(Number(sim.toFixed(6))).assertEqual(0.0);
  }));

  suite.addTest(new TestCase('cosineSimilarity_different lengths', () => {
    const a = [1, 1];
    const b = [1, 1, 1, 1];
    const sim = CjCompute.cosineSimilarity(a, b);
    expect(sim).assertTrue(sim > 0.5);
  }));

  suite.addTest(new TestCase('cosineSimilarity_zero vector', () => {
    const a = [0, 0, 0];
    const b = [1, 2, 3];
    const sim = CjCompute.cosineSimilarity(a, b);
    expect(Number(sim.toFixed(6))).assertEqual(0.0);
  }));

  suite.addTest(new TestCase('vectorNormalize_unit vector unchanged', () => {
    const v = [1, 0, 0];
    const n = CjCompute.vectorNormalize(v);
    expect(Number(n[0].toFixed(6))).assertEqual(1.0);
    expect(Number(n[1].toFixed(6))).assertEqual(0.0);
  }));

  suite.addTest(new TestCase('vectorNormalize_scales to unit length', () => {
    const v = [3, 4];
    const n = CjCompute.vectorNormalize(v);
    const mag = Math.sqrt(n[0] * n[0] + n[1] * n[1]);
    expect(Number(mag.toFixed(6))).assertEqual(1.0);
  }));

  suite.addTest(new TestCase('vectorNormalize_zero returns copy', () => {
    const v = [0, 0, 0];
    const n = CjCompute.vectorNormalize(v);
    expect(n.length).assertEqual(3);
    expect(Number(n[0].toFixed(6))).assertEqual(0.0);
  }));

  suite.addTest(new TestCase('nutriScoreCalc_A grade', () => {
    const r = CjCompute.nutriScoreCalc(50, 2, 50, 1, 0.5, 15, 5, 60);
    expect(r.grade).assertEqual('A');
    expect(r.score).assertTrue(r.score >= 80);
  }));

  suite.addTest(new TestCase('nutriScoreCalc_E grade', () => {
    const r = CjCompute.nutriScoreCalc(300, 20, 800, 8, 5, 2, 0, 0);
    expect(r.grade).assertEqual('E');
    expect(r.score).assertTrue(r.score < 20);
  }));

  suite.addTest(new TestCase('nutriScoreCalc_boundaries', () => {
    const r = CjCompute.nutriScoreCalc(500, 30, 1000, 10, 10, 0, 0, 0);
    expect(r.score).assertTrue(r.score >= 0);
    expect(r.score).assertTrue(r.score <= 100);
  }));

  suite.addTest(new TestCase('bmiCalculate_normal', () => {
    const bmi = CjCompute.bmiCalculate(70, 175);
    expect(Number(bmi.toFixed(1))).assertEqual(22.9);
  }));

  suite.addTest(new TestCase('bmiCalculate_zero height', () => {
    const bmi = CjCompute.bmiCalculate(70, 0);
    expect(Number(bmi.toFixed(6))).assertEqual(0.0);
  }));

  suite.addTest(new TestCase('weightedScore_equal weights', () => {
    const f = [80, 60, 70];
    const w = [1, 1, 1];
    const s = CjCompute.weightedScore(f, w);
    expect(Number(s.toFixed(1))).assertEqual(70.0);
  }));

  suite.addTest(new TestCase('weightedScore_empty returns zero', () => {
    const s = CjCompute.weightedScore([], []);
    expect(Number(s.toFixed(6))).assertEqual(0.0);
  }));

  suite.addTest(new TestCase('weightedScore_zero weights', () => {
    const s = CjCompute.weightedScore([100, 200], [0, 0]);
    expect(Number(s.toFixed(6))).assertEqual(0.0);
  }));

  suite.addTest(new TestCase('isNativeLoaded_fallback path', () => {
    expect(CjCompute.isNativeLoaded()).assertFalse();
  }));

  return suite;
}
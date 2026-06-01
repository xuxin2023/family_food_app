import { describe, it, expect } from '@ohos/hypium';
import {
  AdditiveSafetyEngine, AdditiveRiskLevel, AdditiveAssessment, FoodAdditiveReport
} from 'feature_scan';
import { FoodLabel } from 'hsp_core';

export default function additiveSafetyEngineTest() {
  describe('AdditiveSafetyEngine', () => {
    const engine = AdditiveSafetyEngine.getInstance();

    it('assessFood_should_return_safe_for_no_additives', 0, () => {
      const label = new FoodLabel();
      label.foodName = '纯牛奶';
      label.ingredients = ['生牛乳'];
      const report = engine.assessFood(label);
      expect(report.overallRisk).assertEqual(AdditiveRiskLevel.SAFE);
      expect(report.avoidCount).assertEqual(0);
      expect(report.cautionCount).assertEqual(0);
    });

    it('assessFood_should_detect_avoid_additives', 0, () => {
      const label = new FoodLabel();
      label.foodName = '加工肉';
      label.ingredients = ['E320', 'E321', 'E250'];
      const report = engine.assessFood(label);
      expect(report.avoidCount).assertGreater(0);
      expect(report.overallRisk).assertEqual(AdditiveRiskLevel.AVOID);
    });

    it('assessFood_should_detect_caution_additives', 0, () => {
      const label = new FoodLabel();
      label.foodName = '饮料';
      label.ingredients = ['E211', 'E102'];
      const report = engine.assessFood(label);
      expect(report.cautionCount).assertGreater(0);
    });

    it('assessFood_should_parse_e_numbers_from_ingredient_text', 0, () => {
      const label = new FoodLabel();
      label.foodName = '零食';
      label.ingredients = ['小麦粉', 'E320(抗氧化剂)', 'E621(增味剂)'];
      const report = engine.assessFood(label);
      expect(report.assessments.length).assertGreater(0);
    });

    it('assessFood_should_generate_summary', 0, () => {
      const label = new FoodLabel();
      label.foodName = '测试';
      label.ingredients = ['E300', 'E322'];
      const report = engine.assessFood(label);
      expect(report.summary.length).assertGreater(0);
      expect(report.foodName).assertEqual('测试');
    });

    it('getAdditiveInfo_should_return_known_additive', 0, () => {
      const info = engine.getAdditiveInfo('E200');
      expect(info).assertNotBeNull();
      if (info) {
        expect(info.name).assertEqual('山梨酸');
        expect(info.riskLevel).assertEqual(AdditiveRiskLevel.SAFE);
      }
    });

    it('getAdditiveInfo_should_return_null_for_unknown', 0, () => {
      const info = engine.getAdditiveInfo('E999');
      expect(info).assertBeNull();
    });

    it('getAdditiveInfo_BHA_should_be_avoid', 0, () => {
      const info = engine.getAdditiveInfo('E320');
      expect(info).assertNotBeNull();
      if (info) {
        expect(info.riskLevel).assertEqual(AdditiveRiskLevel.AVOID);
      }
    });

    it('mapEToCns_should_return_null_without_cn_db', 0, () => {
      const cns = engine.mapEToCns('E200');
      expect(cns).assertBeNull();
    });

    it('mapCnsToE_should_return_null_without_cn_db', 0, () => {
      const eNum = engine.mapCnsToE('17.001');
      expect(eNum).assertBeNull();
    });

    it('searchByRiskLevel_should_return_avoid_additives', 0, () => {
      const results = engine.searchByRiskLevel(AdditiveRiskLevel.AVOID);
      expect(results.length).assertGreater(0);
      const hasE250 = results.some(r => r.eNumber === 'E250');
      expect(hasE250).assertTrue();
    });

    it('searchByRiskLevel_should_return_safe_additives', 0, () => {
      const results = engine.searchByRiskLevel(AdditiveRiskLevel.SAFE);
      expect(results.length).assertGreater(0);
    });

    it('assessFood_should_handle_unknown_e_number', 0, () => {
      const label = new FoodLabel();
      label.foodName = '未知添加剂食品';
      label.ingredients = ['E999'];
      const report = engine.assessFood(label);
      expect(report.assessments.length).assertEqual(1);
      expect(report.assessments[0].riskLevel).assertEqual(AdditiveRiskLevel.UNKNOWN);
    });
  });
}
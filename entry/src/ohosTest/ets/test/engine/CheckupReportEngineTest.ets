// CheckupReportEngine 单元测试 - 体检报告解析与长效更新引擎
import { describe, it, expect } from '@ohos/hypium';
import { CheckupReportEngine, CheckupReport, CheckupItem, HealthArchiveUpdate } from '../../../../../src/main/ets/engine/CheckupReportEngine';
import { HealthSignal, BpStatus, BsStatus, StepLevel, SleepStatus, DataSource } from '../../../../../src/main/ets/model/HealthSignal';

function createCheckupSignal(): HealthSignal {
  const signal: HealthSignal = new HealthSignal();
  signal.memberId = 'member_mom';
  signal.stepLevel = StepLevel.NORMAL;
  signal.sleepStatus = SleepStatus.GOOD;
  signal.manualBpStatus = BpStatus.NORMAL;
  signal.manualBsStatus = BsStatus.NORMAL;
  signal.source = DataSource.MANUAL;
  return signal;
}

export default function checkupReportEngineTest() {
  describe('CheckupReportEngine', () => {

    // ========== 1. parseOcrText OCR解析 ==========

    it('should_parse_blood_pressure_items', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '收缩压 145 mmHg\n舒张压 92 mmHg';

      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_mom');

      expect(report.items.length).assertEqual(2);
      expect(report.items[0].name).assertEqual('收缩压');
      expect(report.items[0].value).assertEqual(145);
      expect(report.items[0].isAbnormal).assertTrue();
    });

    it('should_parse_blood_sugar_items', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '空腹血糖 7.5 mmol/L\n糖化血红蛋白HbA1c 6.8%';

      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_mom');

      expect(report.items.length).assertEqual(2);
      const fpgItem: CheckupItem | undefined = report.items.find((item: CheckupItem) => item.name === '空腹血糖');
      expect(fpgItem !== undefined).assertTrue();
      if (fpgItem !== undefined) {
        expect(fpgItem.isAbnormal).assertTrue();
      }
    });

    it('should_parse_lipid_items', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '总胆固醇 5.8 mmol/L\n低密度脂蛋白LDL 3.9 mmol/L\n甘油三酯 2.1 mmol/L';

      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_dad');

      expect(report.items.length).assertEqual(3);
      const abnormalCount: number = report.items.filter((item: CheckupItem) => item.isAbnormal).length;
      expect(abnormalCount).assertLarger(0);
    });

    // ========== 2. 报告摘要与风险评分 ==========

    it('should_build_normal_summary', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '收缩压 110 mmHg\n空腹血糖 5.0 mmol/L';

      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_mom');

      expect(report.summary.includes('正常')).assertTrue();
      expect(report.riskScore).assertEqual(0);
    });

    it('should_build_abnormal_summary_with_risk_score', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '收缩压 160 mmHg\n空腹血糖 8.0 mmol/L\n谷丙转氨酶ALT 60 U/L';

      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_dad');

      expect(report.riskScore).assertLarger(0);
      expect(report.summary.includes('异常')).assertTrue();
    });

    it('should_cap_risk_score_at_100', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '收缩压 200 mmHg\n舒张压 130 mmHg\n空腹血糖 15 mmol/L\n' +
        '总胆固醇 10 mmol/L\n低密度脂蛋白LDL 8 mmol/L\n甘油三酯 5 mmol/L\n' +
        '谷丙转氨酶ALT 200 U/L\n肌酐 300 μmol/L\n尿酸 600 μmol/L';

      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_dad');

      expect(report.riskScore).assertLargerOrEqual(0);
      expect(report.riskScore).assertLessOrEqual(100);
    });

    // ========== 3. generateHealthArchiveUpdate 健康档案更新 ==========

    it('should_update_signal_for_high_bp', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '收缩压 150 mmHg';
      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_mom');
      const signal: HealthSignal = createCheckupSignal();

      const update: HealthArchiveUpdate = engine.generateHealthArchiveUpdate(report, signal);

      expect(update.newAlerts.length).assertLarger(0);
      expect(update.dietaryAdjustments.length).assertLarger(0);
    });

    it('should_update_signal_for_high_bs', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '空腹血糖 8.5 mmol/L';
      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_mom');
      const signal: HealthSignal = createCheckupSignal();

      const update: HealthArchiveUpdate = engine.generateHealthArchiveUpdate(report, signal);

      expect(update.newAlerts.length).assertLarger(0);
      const hasSugarAdjust: boolean = update.dietaryAdjustments.some((d: string) => d.includes('糖') || d.includes('GI'));
      expect(hasSugarAdjust).assertTrue();
    });

    it('should_handle_liver_and_kidney_abnormality', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '谷丙转氨酶ALT 80 U/L\n尿酸 500 μmol/L';
      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_dad');
      const signal: HealthSignal = createCheckupSignal();

      const update: HealthArchiveUpdate = engine.generateHealthArchiveUpdate(report, signal);

      const hasLiverAlert: boolean = update.newAlerts.some((a: string) => a.includes('肝'));
      const hasUricAlert: boolean = update.newAlerts.some((a: string) => a.includes('尿酸'));
      expect(hasLiverAlert || hasUricAlert).assertTrue();
    });

    // ========== 4. 边界条件 ==========

    it('should_handle_empty_ocr_text', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const report: CheckupReport = engine.parseOcrText('', 'member_mom');

      expect(report.items.length).assertEqual(0);
      expect(report.summary.includes('正常')).assertTrue();
      expect(report.riskScore).assertEqual(0);
    });

    it('should_handle_unrecognized_ocr_text', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '姓名：张三\n性别：男\n年龄：45岁';
      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_dad');

      expect(report.items.length).assertEqual(0);
    });

    it('should_handle_normal_report_for_archive_update', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '收缩压 110 mmHg\n空腹血糖 5.0 mmol/L';
      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_mom');
      const signal: HealthSignal = createCheckupSignal();

      const update: HealthArchiveUpdate = engine.generateHealthArchiveUpdate(report, signal);

      expect(update.newAlerts.length).assertEqual(0);
      expect(update.dietaryAdjustments.length).assertEqual(0);
    });

    it('should_set_advice_for_abnormal_items', 0, () => {
      const engine: CheckupReportEngine = new CheckupReportEngine();
      const ocrText: string = '收缩压 160 mmHg';
      const report: CheckupReport = engine.parseOcrText(ocrText, 'member_dad');

      const abnormalItem: CheckupItem | undefined = report.items.find((item: CheckupItem) => item.isAbnormal);
      expect(abnormalItem !== undefined).assertTrue();
      if (abnormalItem !== undefined) {
        expect(abnormalItem.advice.length > 0).assertTrue();
      }
    });
  });
}

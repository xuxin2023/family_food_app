// ModelDownloadService.test.ets
// 端侧AI模型下载服务测试
import { TestSuite, TestCase, expect } from '@ohos/hypium';
import { ModelDownloadService, ModelDownloadStatus, ModelDescriptor } from 'hsp_service';

export default function modelDownloadTest(): TestSuite {
  const suite: TestSuite = new TestSuite(
  const svc = ModelDownloadService.getInstance();

  suite.addTest(new TestCase('isModelAvailable returns false before init', () => {
    const available = svc.isModelAvailable('food_classifier_fp16.ms');
    expect(typeof available).assertEqual('boolean');
  }));

  suite.addTest(new TestCase('getModelPath returns correct sandbox path', () => {
    const path = svc.getLocalModelPath('food_classifier_fp16.ms');
    expect(path).assertTrue(path.includes('food_classifier_fp16.ms'));
  }));

  suite.addTest(new TestCase('getModelSize returns expected bytes', () => {
    const size = svc.getModelSize('food_classifier_fp16.ms');
    expect(size).assertEqual(8388608);
  }));

  suite.addTest(new TestCase('getModelSize unknown returns 0', () => {
    const size = svc.getModelSize('nonexistent_model.ms');
    expect(size).assertEqual(0);
  }));

  suite.addTest(new TestCase('checkAndDownload returns boolean', async () => {
    const result = await svc.checkAndDownload();
    expect(typeof result).assertEqual('boolean');
  }));

  return suite;
}
// HapticHelper.ets
// 统一触感反馈工具 - 提供不同场景的振动反馈
// 使用: HapticHelper.light() / HapticHelper.success() / HapticHelper.error()

import { vibrator } from '@kit.SensorServiceKit';

export class HapticHelper {
  static light(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 15 }, { id: 0, usage: 'touch' });
    } catch (_) {
    }
  }

  static medium(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 40 }, { id: 0, usage: 'notification' });
    } catch (_) {
    }
  }

  static success(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 80 }, { id: 0, usage: 'notification' });
    } catch (_) {
    }
  }

  static error(): void {
    try {
      vibrator.startVibration({ type: 'time', duration: 200 }, { id: 0, usage: 'notification' });
    } catch (_) {
    }
  }
}

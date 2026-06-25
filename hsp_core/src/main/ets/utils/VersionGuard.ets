// hsp-core: API Level 版本守卫
// 运行时检测设备 API Level，避免调用不兼容的 API


import { deviceInfo } from '@kit.BasicServicesKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'VersionGuard';

/** HarmonyOS API 版本级别 */
export enum ApiLevel {
  API_9 = 9,
  API_10 = 10,
  API_11 = 11,
  API_12 = 12,
  API_13 = 13,
  API_14 = 14,
}

/** 功能门控配置 */
interface FeatureGate {
  name: string;
  minApiLevel: ApiLevel;
  description: string;
}

/** 系统预定义的功能门控 */
const FEATURE_GATES: FeatureGate[] = [
  { name: 'MindSporeLite', minApiLevel: ApiLevel.API_11, description: 'MindSpore Lite 端侧推理' },
  { name: 'AiFoundationKit', minApiLevel: ApiLevel.API_12, description: 'HiAI Foundation Kit' },
  { name: 'NpuAcceleration', minApiLevel: ApiLevel.API_12, description: 'NPU 硬件加速' },
  { name: 'DistributedSync', minApiLevel: ApiLevel.API_10, description: '分布式数据同步' },
  { name: 'AtomicServiceCard', minApiLevel: ApiLevel.API_12, description: '元服务卡片' },
  { name: 'UdmfDataShare', minApiLevel: ApiLevel.API_12, description: 'UDMF 统一数据管理' },
  { name: 'LiveWindow', minApiLevel: ApiLevel.API_12, description: '实况窗' },
  { name: 'AppContinuation', minApiLevel: ApiLevel.API_11, description: '应用流转' },
  { name: 'HealthKit', minApiLevel: ApiLevel.API_10, description: '华为Health Kit' },
  { name: 'CloudDb', minApiLevel: ApiLevel.API_11, description: '华为云数据库' },
];

let _currentApiLevel: number = -1;
let _featureCache: Map<string, boolean> = new Map();

export class VersionGuard {
  /**
   * 初始化版本守卫（建议在应用启动时调用一次）
   */
  static init(): void {
    try {
      const sdkApiVersion: number = deviceInfo.sdkApiVersion;
      _currentApiLevel = sdkApiVersion;
      hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'Device API Level: %{public}d', _currentApiLevel);
    } catch (e) {
      hilog.warn(HILOG_DOMAIN_DEFAULT, TAG, 'Failed to detect API level: %{public}s', JSON.stringify(e));
      _currentApiLevel = ApiLevel.API_10;
    }
  }

  /**
   * 获取当前设备 API Level
   */
  static getCurrentApiLevel(): number {
    if (_currentApiLevel < 0) {
      VersionGuard.init();
    }
    return _currentApiLevel;
  }

  /**
   * 检查指定功能在当前设备是否可用
   */
  static isFeatureAvailable(featureName: string): boolean {
    const cached = _featureCache.get(featureName);
    if (cached !== undefined) return cached;

    const gate = FEATURE_GATES.find(g => g.name === featureName);
    if (!gate) {
      _featureCache.set(featureName, true);
      return true;
    }

    const apiLevel = VersionGuard.getCurrentApiLevel();
    const available = apiLevel >= gate.minApiLevel;
    _featureCache.set(featureName, available);

    if (!available) {
      hilog.info(HILOG_DOMAIN_DEFAULT, TAG,
        'Feature "%{public}s" not available: requires API %{public}d, device has %{public}d',
        featureName, gate.minApiLevel, apiLevel);
    }

    return available;
  }

  /**
   * 安全调用——仅在满足 API Level 时执行代码
   */
  static safeCall(
    featureName: string,
    callback: () => void,
    fallback?: () => void
  ): void {
    if (VersionGuard.isFeatureAvailable(featureName)) {
      callback();
    } else if (fallback) {
      fallback();
    }
  }

  /**
   * 获取系统完整能力的摘要
   */
  static getCapabilitySummary(): Record<string, boolean> {
    const summary: Record<string, boolean> = {};
    for (const gate of FEATURE_GATES) {
      summary[gate.name] = VersionGuard.isFeatureAvailable(gate.name);
    }
    return summary;
  }

  /**
   * 获取所有已注册的功能门控列表
   */
  static getFeatureGates(): FeatureGate[] {
    return [...FEATURE_GATES];
  }

  /** 清除功能缓存（版本热更新后调用） */
  static resetCache(): void {
    _featureCache.clear();
    _currentApiLevel = -1;
  }
}

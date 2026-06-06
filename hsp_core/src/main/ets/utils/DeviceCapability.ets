import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const TAG = 'DeviceCapability';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

export enum NpuLevel { NONE = 'none', BASIC = 'basic', ADVANCED = 'advanced' }

export class DeviceCapability {
  private static instance: DeviceCapability | null = null;
  private cached: boolean = false;
  private npu: NpuLevel = NpuLevel.NONE;
  private ramMB: number = 0;
  private cpuCores: number = 0;

  static getInstance(): DeviceCapability {
    if (!DeviceCapability.instance) { DeviceCapability.instance = new DeviceCapability(); }
    return DeviceCapability.instance;
  }

  async init(): Promise<void> {
    if (this.cached) return;
    try { this.npu = this.detectNpu(); } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); this.npu = NpuLevel.NONE; }
    try { this.ramMB = this.detectRam(); } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); this.ramMB = 4096; }
    try { this.cpuCores = this.detectCpuCores(); } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e)); this.cpuCores = 4; }
    this.cached = true;
    hilog.info(DOMAIN_ZERO, TAG, 'Device: NPU=%{public}s RAM=%{public}dMB CPU=%{public}dC', this.npu, this.ramMB, this.cpuCores);
  }

  hasNpu(): boolean { return this.npu !== NpuLevel.NONE; }
  getNpuLevel(): NpuLevel { return this.npu; }
  getRamMB(): number { return this.ramMB; }
  getCpuCores(): number { return this.cpuCores; }

  isHighEnd(): boolean { return this.ramMB >= 8192 && this.cpuCores >= 8; }
  canRunOnDeviceLlm(): boolean { return this.isHighEnd() && this.hasNpu(); }
  shouldUseNpuInference(): boolean { return this.npu === NpuLevel.ADVANCED; }

  private detectNpu(): NpuLevel {
    const globalObj = {} as Record<string, Object>;
    if (globalObj['hiAI'] !== undefined) return NpuLevel.ADVANCED;
    if (globalObj['MindSpore'] !== undefined) return NpuLevel.BASIC;
    return NpuLevel.NONE;
  }

  private detectRam(): number {
    const globalObj = {} as Record<string, Object>;
    const perf = globalObj['performance'] as Record<string, Object> | undefined;
    if (perf && perf['deviceMemory']) {
      const gb = perf['deviceMemory'] as number;
      return gb * 1024;
    }
    return 4096;
  }

  private detectCpuCores(): number {
    const globalObj = {} as Record<string, Object>;
    const nav = globalObj['navigator'] as Record<string, Object> | undefined;
    if (nav && nav['hardwareConcurrency']) {
      return nav['hardwareConcurrency'] as number;
    }
    return 4;
  }
}
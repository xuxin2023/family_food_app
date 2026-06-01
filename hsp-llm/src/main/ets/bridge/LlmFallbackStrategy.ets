// hsp-llm: LLM 降级策略
// 统一的降级决策：区分错误类型 → 选择最佳回退方案

import { HILOG_DOMAIN_DEFAULT } from 'hsp_core';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'LlmFallbackStrategy';

export enum FallbackReason {
  MODEL_UNAVAILABLE = 'model_unavailable',
  INFERENCE_ERROR = 'inference_error',
  NPU_BUSY = 'npu_busy',
  MEMORY_LOW = 'memory_low',
  TIMEOUT = 'timeout',
  NETWORK_ERROR = 'network_error',
  UNKNOWN = 'unknown'
}

/** 回退消息模板 */
const FALLBACK_MESSAGES: Record<FallbackReason, string> = {
  [FallbackReason.MODEL_UNAVAILABLE]: 'AI功能暂不可用，已切换为本地规则分析。您仍可查看配料表和营养成分信息。',
  [FallbackReason.INFERENCE_ERROR]: 'AI分析遇到问题，已使用备选方案。结果基于食品标签数据，仍具参考价值。',
  [FallbackReason.NPU_BUSY]: 'AI加速芯片繁忙，已切换CPU推理模式。分析速度可能略有下降。',
  [FallbackReason.MEMORY_LOW]: '当前内存不足，已启用轻量分析模式。部分高级功能暂不可用。',
  [FallbackReason.TIMEOUT]: 'AI分析超时，已切换为快速分析。完整分析请稍后再试。',
  [FallbackReason.NETWORK_ERROR]: '网络连接异常，已切换离线模式。所用数据基于本地知识库。',
  [FallbackReason.UNKNOWN]: 'AI功能暂不可用，请稍后重试。',
};

/** 回退严重度 */
export enum FallbackSeverity {
  TRANSPARENT = 'transparent',  // 对用户透明，无需提示
  INFO = 'info',                // 提示信息，功能降级但仍可用
  WARNING = 'warning',          // 警告，核心功能受影响
  BLOCKING = 'blocking'         // 阻断，功能完全不可用
}

/** 回退严重度映射 */
const SEVERITY_MAP: Record<FallbackReason, FallbackSeverity> = {
  [FallbackReason.MODEL_UNAVAILABLE]: FallbackSeverity.INFO,
  [FallbackReason.INFERENCE_ERROR]: FallbackSeverity.WARNING,
  [FallbackReason.NPU_BUSY]: FallbackSeverity.TRANSPARENT,
  [FallbackReason.MEMORY_LOW]: FallbackSeverity.WARNING,
  [FallbackReason.TIMEOUT]: FallbackSeverity.INFO,
  [FallbackReason.NETWORK_ERROR]: FallbackSeverity.INFO,
  [FallbackReason.UNKNOWN]: FallbackSeverity.WARNING,
};

export class LlmFallbackStrategy {
  /**
   * 判断是否需要降级处理
   * @param reason 降级原因
   * @returns true 表示需要降级
   */
  shouldFallback(reason: FallbackReason): boolean {
    // 所有非正常情况都需要降级处理
    return reason !== FallbackReason.MODEL_UNAVAILABLE ||
      this.getSeverity(reason) !== FallbackSeverity.TRANSPARENT;
  }

  /**
   * 获取降级用户提示消息
   * @param reason 降级原因
   * @returns 用户可见的提示文本
   */
  getFallbackMessage(reason: FallbackReason): string {
    const msg = FALLBACK_MESSAGES[reason] ?? FALLBACK_MESSAGES[FallbackReason.UNKNOWN];
    hilog.info(HILOG_DOMAIN_DEFAULT, TAG, 'Fallback activated: %{public}s → %{public}s', reason, msg);
    return msg;
  }

  /**
   * 获取降级严重度
   */
  getSeverity(reason: FallbackReason): FallbackSeverity {
    return SEVERITY_MAP[reason] ?? FallbackSeverity.WARNING;
  }

  /**
   * 从错误对象推断降级原因
   */
  classifyError(error: Error): FallbackReason {
    const msg = error.message?.toLowerCase() ?? '';
    if (msg.includes('timeout') || msg.includes('timed out')) return FallbackReason.TIMEOUT;
    if (msg.includes('memory') || msg.includes('oom')) return FallbackReason.MEMORY_LOW;
    if (msg.includes('network') || msg.includes('connection') || msg.includes('http')) return FallbackReason.NETWORK_ERROR;
    if (msg.includes('busy') || msg.includes('queue')) return FallbackReason.NPU_BUSY;
    if (msg.includes('model') || msg.includes('not found') || msg.includes('load')) return FallbackReason.MODEL_UNAVAILABLE;
    if (msg.includes('inference') || msg.includes('runtime') || msg.includes('execution')) return FallbackReason.INFERENCE_ERROR;
    return FallbackReason.UNKNOWN;
  }

  /**
   * 是否应向用户展示降级提示
   */
  shouldShowToUser(reason: FallbackReason): boolean {
    const severity = this.getSeverity(reason);
    return severity === FallbackSeverity.INFO || severity === FallbackSeverity.WARNING;
  }
}

// hsp_llm/Index.ets
// 端侧大模型调用 — 统一导出入口

export { OnDeviceLlmBridge, LlmInferenceResult, LlmTaskType, LlmInferenceInput } from './src/main/ets/bridge/OnDeviceLlmBridge';
export { LlmFallbackStrategy, FallbackReason, FallbackSeverity } from './src/main/ets/bridge/LlmFallbackStrategy';
export { PromptBuilder, PromptTemplate, PromptContext } from './src/main/ets/PromptBuilder';
export { ModelManager, ModelInfo, ModelStatus } from './src/main/ets/ModelManager';

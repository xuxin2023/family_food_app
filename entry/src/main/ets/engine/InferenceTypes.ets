// InferenceTypes.ets
// 端侧推理结果类型 — 独立文件避免循环引用
// OnDeviceInferenceEngine 和 InferenceFallback 共享

export class InferenceResult {
  label: string = '';
  confidence: number = 0;
  alternatives: InferenceAlternative[] = [];
  latencyMs: number = 0;

  constructor(label: string, confidence: number, alternatives: InferenceAlternative[], latencyMs: number) {
    this.label = label;
    this.confidence = confidence;
    this.alternatives = alternatives;
    this.latencyMs = latencyMs;
  }
}

export class InferenceAlternative {
  label: string = '';
  confidence: number = 0;

  constructor(label: string, confidence: number) {
    this.label = label;
    this.confidence = confidence;
  }
}

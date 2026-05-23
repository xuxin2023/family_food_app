# HarmonyOS 6.1 端侧大模型深度集成方案

> 生成日期：2026-05-15
> 目标：在 AiChatService 中实现"端侧 LLM → 云端 API"降级链

---

## 1. 当前状态

- `OnDeviceInferenceEngine.ets`：已实现 `@kit.MindSporeLiteKit` 图像分类推理（MobileNetV2）
- `AiChatService.ets`：仅使用云端 AgentArts API，无端侧降级
- 模型文件：`resources/rawfile/` 下无 .ms 模型文件

---

## 2. 技术方案

### 2.1 端侧 LLM 推理增强

HarmonyOS 6.1 的 `@kit.MindSporeLiteKit` 支持端侧 LLM 文本生成推理。

```text
// OnDeviceInferenceEngine.ets 新增方法

/**
 * 端侧 LLM 文本生成推理
 * @param prompt 输入 prompt（含 system + user 消息）
 * @param maxTokens 最大生成 token 数
 * @returns 生成的文本，模型未加载则返回 null
 */
async generateText(prompt: string, maxTokens: number = 512): Promise<string | null> {
  if (!this.isModelLoaded || !this.msModel) {
    hilog.warn(DOMAIN_ZERO, TAG, 'LLM model not loaded, returning null');
    return null;
  }

  try {
    const inputs = this.msModel.getInputs();
    // 1. Tokenize prompt → input_ids + attention_mask
    const tokenized = this.tokenize(prompt);
    inputs[0].setData(tokenized.inputIds.buffer as ArrayBuffer);
    inputs[1].setData(tokenized.attentionMask.buffer as ArrayBuffer);

    // 2. 自回归生成
    const generatedTokens: Int32Array = new Int32Array(maxTokens);
    let generatedLength = 0;

    for (let step = 0; step < maxTokens; step++) {
      const outputs = await this.msModel.predict(inputs);
      const logits = new Float32Array(outputs[0].getData());

      // 3. Greedy/Top-K 采样
      const nextToken = this.sampleNextToken(logits);
      if (nextToken === this.eosTokenId) break;

      generatedTokens[generatedLength++] = nextToken;

      // 4. 更新 inputs（滚动窗口）
      this.updateInputsForNextStep(inputs, nextToken);
    }

    // 5. Detokenize
    const result = this.detokenize(generatedTokens, generatedLength);
    return result;
  } catch (err) {
    hilog.error(DOMAIN_ZERO, TAG, 'LLM generation failed: %{public}s', JSON.stringify(err));
    return null;
  }
}

private tokenize(text: string): { inputIds: Int32Array; attentionMask: Int32Array } {
  // 使用预置 tokenizer（sentencepiece/BPE 词表映射）
  // 实现需根据具体模型选择对应的 tokenizer
  // ...
}

private detokenize(tokens: Int32Array, length: number): string {
  // 反向词表映射 → 文本
  // ...
}

private sampleNextToken(logits: Float32Array): number {
  // Top-K + Temperature 采样
  // ...
}
```

### 2.2 AiChatService 降级链改造

```text
// AiChatService.ets 改造核心逻辑

async chat(messages: ChatMessage[]): Promise<string> {
  // 1. 尝试端侧 LLM（隐私优先，无需网络）
  const localResult = await this.tryOnDeviceLlm(messages);
  if (localResult !== null) {
    hilog.info(DOMAIN_ZERO, TAG, 'Using on-device LLM response');
    return localResult;
  }

  // 2. 降级到云端 AgentArts API
  hilog.info(DOMAIN_ZERO, TAG, 'Falling back to cloud AI');
  const cloudResult = await this.callCloudApi(messages);
  return cloudResult;
}

private async tryOnDeviceLlm(messages: ChatMessage[]): Promise<string | null> {
  const engine = OnDeviceInferenceEngine.getInstance();
  if (!engine.isModelReady()) {
    return null;
  }

  // 构建 prompt
  const prompt = this.buildLlmPrompt(messages);
  const result = await engine.generateText(prompt, 256);
  return result;
}
```

### 2.3 模型文件预置

| 模型 | 用途 | 大小(估) | 路径 |
|---|---|---|---|
| `food_classifier.ms` | 食品图像分类 | ~5MB | `resources/rawfile/food_classifier.ms` |
| `ingredient_recognizer.ms` | 成分文字识别 | ~3MB | `resources/rawfile/ingredient_recognizer.ms` |
| `allergen_detector.ms` | 过敏原检测 | ~2MB | `resources/rawfile/allergen_detector.ms` |
| `nutrition_qwen_0.5b.ms` | 端侧营养问答LLM | ~500MB | `resources/rawfile/nutrition_qwen_0.5b.ms` |

> **注意**：端侧 LLM 模型较大（0.5B参数约500MB），建议：
> - 仅在 Wi-Fi 下按需下载（非预置在 APK 中）
> - 使用模型量化（INT4/INT8）减小体积
> - 考虑使用 HarmonyOS 的 `@kit.MindSporeLiteKit` 模型下载管理器

---

## 3. 执行步骤

| 步骤 | 动作 | 前置条件 |
|---|---|---|
| 1 | 在 OnDeviceInferenceEngine 中新增 generateText() 方法 | 模型文件就绪 |
| 2 | 在 AiChatService 中实现 tryOnDeviceLlm() 降级方法 | 步骤1完成 |
| 3 | 集成 tokenizer（预置词表 + sentencepiece/BPE 编解码） | 选择具体模型 |
| 4 | 模型量化与性能测试（推理延迟、内存占用、功耗） | 真机调试 |
| 5 | 用户设置项：端侧模型开关 + 模型下载管理 | 步骤4通过 |

---

## 4. 优势

- **隐私保护**：用户对话数据不离开设备（端侧推理无需上传）
- **离线可用**：无网络时仍可提供基础营养问答
- **响应速度**：端侧推理延迟 < 2s（0.5B模型），优于云端 API 往返
- **成本节约**：减少云端 API 调用量，降低运营成本

---

## 5. 风险与限制

- **模型体积**：端侧 LLM 较大，需按需下载
- **推理质量**：0.5B参数模型能力有限，复杂问题仍需云端
- **兼容性**：部分低端设备不支持 NPU，CPU 推理延迟较高
- **内存压力**：LLM 推理占用 ~1GB RAM，需与系统协调

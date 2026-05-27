# 端侧 AI 模型文件说明

本目录用于存放 MindSpore Lite (.ms) 推理模型文件，供 `OnDeviceInferenceEngine` 端侧推理使用。

## 所需模型文件

| 模型文件 | 用途 | 对应枚举 | 建议精度 | 参考大小 |
|---------|------|---------|---------|---------|
| `food_classifier.ms` | 食品分类 (MobileNetV2/EfficientNet 微调) | `InferenceModelType.FOOD_CLASSIFIER` | INT8 量化 | ~5MB |
| `ingredient_recognizer.ms` | 成分标识文字识别后处理 | `InferenceModelType.INGREDIENT_RECOGNIZER` | INT8 量化 | ~3MB |
| `allergen_detector.ms` | 过敏原实时检测 | `InferenceModelType.ALLERGEN_DETECTOR` | INT8 量化 | ~2MB |
| `food_analyst_v2.ms` | 食品成分分析综合模型 (OnDeviceAiEngine) | — | INT8 量化 | ~120MB |

## 获取模型文件

### 方式一：自训练 + 转换
1. 使用 PyTorch/TensorFlow 训练目标模型
2. 导出为 ONNX 格式
3. 使用 MindSpore Lite 模型转换工具将 ONNX 转为 .ms 格式：
   ```bash
   ./converter_lite --fmk=ONNX --modelFile=model.onnx --outputFile=model.ms --optimize=GA --fp16=on
   ```
4. 将生成的 .ms 文件放入本目录

### 方式二：预训练模型下载
- 从项目内部模型仓库或华为 ModelHub 下载已转换的 .ms 文件
- 联系 AI 团队获取最新量化模型

## 降级策略

当模型文件缺失时，引擎自动降级，**不影响应用功能**：
1. **NPU 加载失败** → 自动回退 CPU 后端
2. **CPU 加载也失败** → `OnDeviceInferenceEngine.isModelReady()` 返回 false
3. **模型不可用时** → `classifyFood()` 返回 null，上层走云端 AI
4. **predict()** → 始终走 `InferenceFallback` 规则引擎（基于营养阈值推理）
5. **完整降级链路**: NPU → CPU → InferenceFallback → 云端 AI

## 验证模型加载

```typescript
const engine = OnDeviceInferenceEngine.getInstance();
const loaded = await engine.init(context, InferenceModelType.FOOD_CLASSIFIER);
console.log('Model ready:', engine.isModelReady());
```

## 注意事项
- .ms 文件体积较大，**不要提交到 Git**（已在 .gitignore 中排除 *.ms）
- 本目录仅含 `.gitkeep` 占位文件，实际模型需手动部署
- 模型更新后需调用 `RuleRepository.clearCache()` 清除缓存

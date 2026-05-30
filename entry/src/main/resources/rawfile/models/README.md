# 端侧 AI 模型文件说明

本目录用于存放 MindSpore Lite (.ms) 推理模型文件，供 `OnDeviceInferenceEngine` 端侧推理使用。

## 模型文件命名规范

| 规范项 | 规则 | 示例 |
|--------|------|------|
| 文件格式 | `<功能域>_<任务>.ms` | `ingredient_ocr.ms` |
| 版本管理 | 同目录 `model_config.json` 声明 version | `"version": "1.0.0"` |
| 量化后缀 | 不在文件名体现，由 config 声明 | `"quantization": "int8"` |
| 禁止提交 | `*.ms` 已加入 .gitignore | — |

## 所需模型文件

| 模型文件 | 用途 | 对应枚举 | 建议精度 | 参考大小 |
|---------|------|---------|---------|---------|
| `food_classifier.ms` | 食品分类 (MobileNetV2/EfficientNet 微调) | `InferenceModelType.FOOD_CLASSIFIER` | INT8 量化 | ~5MB |
| `ingredient_ocr.ms` | 配料表 OCR 文字识别 | `InferenceModelType.INGREDIENT_RECOGNIZER` | INT8 量化 | ~2MB |
| `ingredient_semantic.ms` | 配料语义解析 | — | FP16 | ~4MB |
| `allergen_detector.ms` | 过敏原实时检测 | `InferenceModelType.ALLERGEN_DETECTOR` | INT8 量化 | ~2MB |
| `food_analyst_v2.ms` | 食品成分分析综合模型 (OnDeviceAiEngine) | — | INT8 量化 | ~120MB |

## 模型转换脚本 (Python MindSpore → .ms)

完整转换流程见 `scripts/convert_model.py`，核心步骤：

1. **训练导出** → PyTorch/TensorFlow → ONNX
2. **MindSpore 转换** → `converter_lite --fmk=ONNX --modelFile=model.onnx --outputFile=model.ms`
3. **量化压缩** → `--configFile=quant_config.json`（INT8/FP16）
4. **校验部署** → 输出 .ms 到本目录

```bash
# INT8 量化转换
./converter_lite --fmk=ONNX --modelFile=model.onnx --outputFile=model.ms \
  --optimize=GA --configFile=config/int8_quant_config.json

# FP16 转换（语义模型）
./converter_lite --fmk=ONNX --modelFile=model.onnx --outputFile=model.ms \
  --optimize=GA --fp16=on
```

## 模型量化配置

| 量化类型 | 适用模型 | 精度损失 | 体积压缩比 | 推理加速 |
|---------|---------|---------|-----------|---------|
| INT8 | OCR / 分类 / 检测 | <1% (post-training) | ~4x | ~2-3x |
| FP16 | 语义解析 / 嵌入 | <0.1% | ~2x | ~1.5x |

INT8 量化配置示例 (`int8_quant_config.json`)：
```json
{
  "common_quant_param": {
    "quant_type": "WEIGHT_QUANT",
    "bit_num": 8,
    "min_quant_weight_size": 500,
    "min_quant_weight_channel": 5
  }
}
```

## 部署目录结构

```
rawfile/models/
├── README.md                  # 本文档
├── model_config.json          # 模型元信息与降级链路配置
├── .gitkeep                   # Git 占位
├── food_classifier.ms         # [不提交] 食品分类模型
├── ingredient_ocr.ms          # [不提交] 配料OCR模型
├── ingredient_semantic.ms     # [不提交] 配料语义模型
├── allergen_detector.ms       # [不提交] 过敏原检测模型
└── food_analyst_v2.ms         # [不提交] 综合分析模型
```

## 降级链路说明

当模型文件缺失或推理失败时，引擎自动降级，**不影响应用功能**：

```
NPU → CPU → Cloud AI → Rule Engine (InferenceFallback)
```

| 阶段 | 触发条件 | 行为 |
|------|---------|------|
| NPU | 设备无 NPU 或模型不兼容 | 回退 CPU 后端 |
| CPU | 模型文件缺失或加载失败 | `isModelReady()` 返回 false |
| Cloud | 网络可用 + 用户未关闭云端 | `classifyFood()` 返回 null，上层走云端 AI |
| Rule Engine | 网络不可用 | `predict()` 走 `InferenceFallback` 规则引擎（营养阈值推理） |

## 获取模型文件

### 方式一：自训练 + 转换
1. 使用 PyTorch/TensorFlow 训练目标模型
2. 导出为 ONNX 格式
3. 运行 `python scripts/convert_model.py --model <name> --quant <int8|fp16>`
4. 将生成的 .ms 文件放入本目录

### 方式二：预训练模型下载
- 运行 `scripts/deploy-models.sh` 从华为云 OBS 拉取
- 从华为 ModelHub 下载已转换的 .ms 文件
- 联系 AI 团队获取最新量化模型

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
- `model_config.json` 需与实际模型文件同步更新

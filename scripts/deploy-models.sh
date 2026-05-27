#!/bin/bash
# MindSpore Lite 模型文件部署脚本
# 用途: 从华为云OBS或本地路径下载 .ms 模型到 rawfile/models/ 目录
# 前置: 需要配置 OBS_BASE_URL 或 LOCAL_MODEL_DIR 环境变量

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_DIR="${SCRIPT_DIR}/entry/src/main/resources/rawfile/models"

OBS_BASE_URL="${OBS_MODEL_BASE_URL:-https://familyfood-ai-models.obs.cn-north-4.myhuaweicloud.com}"
LOCAL_MODEL_DIR="${LOCAL_MODEL_DIR:-}"

MODELS=(
  "food_classifier.ms"
  "ingredient_recognizer.ms"
  "allergen_detector.ms"
  "food_analyst_v2.ms"
)

echo "=== MindSpore Lite Model Deployment ==="
echo "Target directory: ${MODEL_DIR}"
echo ""

mkdir -p "${MODEL_DIR}"

deployed=0
skipped=0
failed=0

for model in "${MODELS[@]}"; do
  target_path="${MODEL_DIR}/${model}"

  if [ -f "${target_path}" ]; then
    size=$(stat -f%z "${target_path}" 2>/dev/null || stat -c%s "${target_path}" 2>/dev/null || echo "unknown")
    echo "[SKIP] ${model} already exists (${size} bytes)"
    skipped=$((skipped + 1))
    continue
  fi

  if [ -n "${LOCAL_MODEL_DIR}" ] && [ -f "${LOCAL_MODEL_DIR}/${model}" ]; then
    echo "[COPY] ${model} from local: ${LOCAL_MODEL_DIR}/${model}"
    cp "${LOCAL_MODEL_DIR}/${model}" "${target_path}"
    deployed=$((deployed + 1))
    continue
  fi

  url="${OBS_BASE_URL}/${model}"
  echo "[FETCH] ${model} from ${url}"

  if command -v curl &>/dev/null; then
    if curl -fsSL --connect-timeout 30 --max-time 300 -o "${target_path}" "${url}"; then
      echo "  -> OK"
      deployed=$((deployed + 1))
    else
      echo "  -> FAILED (curl error)"
      rm -f "${target_path}"
      failed=$((failed + 1))
    fi
  elif command -v wget &>/dev/null; then
    if wget -q --timeout=30 -O "${target_path}" "${url}"; then
      echo "  -> OK"
      deployed=$((deployed + 1))
    else
      echo "  -> FAILED (wget error)"
      rm -f "${target_path}"
      failed=$((failed + 1))
    fi
  else
    echo "  -> FAILED (no curl or wget available)"
    failed=$((failed + 1))
  fi
done

echo ""
echo "=== Deployment Summary ==="
echo "Deployed: ${deployed}"
echo "Skipped:  ${skipped}"
echo "Failed:   ${failed}"
echo ""

if [ ${failed} -gt 0 ]; then
  echo "WARNING: Some models failed to download."
  echo "The app will still function using the fallback chain: NPU -> CPU -> InferenceFallback -> Cloud AI"
  exit 1
fi

echo "All models ready. OnDeviceInferenceEngine will attempt NPU/CPU load on next app start."
exit 0

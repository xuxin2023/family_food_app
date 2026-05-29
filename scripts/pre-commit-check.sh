#!/bin/bash
# pre-commit-check.sh
# 提交前检查：ArkTS 代码风格、禁止提交敏感文件、TODO/FIXME 数量检查

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

echo "=== Pre-commit Check ==="
echo ""

# ===== 1. 禁止提交 .env / credentials 文件 =====
echo "--- Checking for sensitive files ---"
SENSITIVE_PATTERNS=(".env" ".env.local" ".env.production" "credentials.json" "secrets.json" "*.pem" "*.p12" "*.jks" "*.keystore")

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || true)

for file in $STAGED_FILES; do
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    case "$file" in
      *$pattern*)
        echo -e "${RED}ERROR: Sensitive file detected: $file${NC}"
        ERRORS=$((ERRORS + 1))
        ;;
    esac
  done
done

if [ "$ERRORS" -eq 0 ]; then
  echo -e "${GREEN}No sensitive files detected${NC}"
fi
echo ""

# ===== 2. ArkTS 代码风格检查 =====
echo "--- ArkTS Code Style Check ---"

STYLE_ISSUES=0

for file in $STAGED_FILES; do
  case "$file" in
    *.ets|*.ts)
      if [ -f "$file" ]; then
        # 2a. 禁止 console.log（应使用 hilog）
        if grep -q 'console\.log' "$file" 2>/dev/null; then
          COUNT=$(grep -c 'console\.log' "$file" 2>/dev/null)
          echo -e "${YELLOW}WARNING: $file uses console.log ($COUNT occurrences, use hilog)${NC}"
          WARNINGS=$((WARNINGS + 1))
          STYLE_ISSUES=$((STYLE_ISSUES + 1))
        fi

        # 2b. 禁止 any 类型
        if grep -qE ':\s*any\b' "$file" 2>/dev/null; then
          COUNT=$(grep -cE ':\s*any\b' "$file" 2>/dev/null)
          echo -e "${YELLOW}WARNING: $file uses 'any' type ($COUNT occurrences)${NC}"
          WARNINGS=$((WARNINGS + 1))
          STYLE_ISSUES=$((STYLE_ISSUES + 1))
        fi

        # 2c. 检查行尾空格
        if grep -qE '\s+$' "$file" 2>/dev/null; then
          echo -e "${YELLOW}WARNING: $file has trailing whitespace${NC}"
          WARNINGS=$((WARNINGS + 1))
        fi

        # 2d. 检查文件末尾换行
        if [ -f "$file" ] && [ "$(tail -c 1 "$file" | wc -l)" -eq 0 ]; then
          echo -e "${YELLOW}WARNING: $file missing newline at EOF${NC}"
          WARNINGS=$((WARNINGS + 1))
        fi
      fi
      ;;
  esac
done

if [ "$STYLE_ISSUES" -eq 0 ]; then
  echo -e "${GREEN}Code style check passed${NC}"
fi
echo ""

# ===== 3. TODO/FIXME 数量检查 =====
echo "--- TODO/FIXME Count Check ---"

MAX_TODO=50
MAX_FIXME=10

TODO_COUNT=0
FIXME_COUNT=0

if [ -d "entry/src" ]; then
  TODO_COUNT=$(grep -r 'TODO' entry/src/ hsp_core/src/ hsp_service/src/ --include='*.ets' --include='*.ts' 2>/dev/null | wc -l || echo 0)
  FIXME_COUNT=$(grep -r 'FIXME' entry/src/ hsp_core/src/ hsp_service/src/ --include='*.ets' --include='*.ts' 2>/dev/null | wc -l || echo 0)
fi

echo "TODO count: $TODO_COUNT (max: $MAX_TODO)"
echo "FIXME count: $FIXME_COUNT (max: $MAX_FIXME)"

if [ "$TODO_COUNT" -gt "$MAX_TODO" ]; then
  echo -e "${YELLOW}WARNING: Too many TODOs ($TODO_COUNT > $MAX_TODO)${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

if [ "$FIXME_COUNT" -gt "$MAX_FIXME" ]; then
  echo -e "${RED}ERROR: Too many FIXMEs ($FIXME_COUNT > $MAX_FIXME)${NC}"
  ERRORS=$((ERRORS + 1))
fi
echo ""

# ===== Summary =====
echo "=== Summary ==="
if [ "$ERRORS" -gt 0 ]; then
  echo -e "${RED}ERRORS: $ERRORS${NC}"
fi
if [ "$WARNINGS" -gt 0 ]; then
  echo -e "${YELLOW}WARNINGS: $WARNINGS${NC}"
fi

if [ "$ERRORS" -gt 0 ]; then
  echo -e "${RED}Pre-commit check FAILED - fix errors before committing${NC}"
  exit 1
else
  echo -e "${GREEN}Pre-commit check PASSED${NC}"
  exit 0
fi

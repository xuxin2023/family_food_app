# Edit ReportPage.ets - HeroSection compact optimization
import re

with open('E:/APP/family_food_app/entry/src/main/ets/pages/ReportPage.ets', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the HeroSection @Builder
start_marker = '  HeroSection() {'
idx_start = content.find(start_marker)
if idx_start < 0:
    print("ERROR: Could not find HeroSection()")
    exit(1)

# Find the end - the next @Builder or pattern that ends the section
rest = content[idx_start:]
# Find the closing of HeroSection - look for "  // ======" or similar after it
lines = rest.split('\n')
end_idx = 0
for i in range(1, len(lines)):
    # The section ends before the next @Builder
    if lines[i].strip().startswith('@Builder') and i > 5:
        end_idx = idx_start + sum(len(l)+1 for l in lines[:i])
        break
    # Or at likely closing
    if '  }\n\n  // =====' in lines[i-1] if i > 0 and lines[i-1].strip() == '}' else False:
        pass

# Simpler: find the pattern that ends the HeroSection (.backgroundColor(COLORS.WHITE)\n    .margin({ top: 4 }))
end_pattern = '.margin({ top: 4 })'
end_search_start = idx_start + len(lines[0]) + 1
end_pos = content.find(end_pattern, end_search_start)
if end_pos > 0:
    # Find the end of line containing this pattern
    end_of_line = content.find('\n', end_pos)
    end_idx = end_of_line + 1
else:
    print("ERROR: Could not find end pattern")
    exit(1)

print(f'HeroSection: {idx_start} to {end_idx}')

# Define old and new content
old = content[idx_start:end_idx]

new_builder = '''  HeroSection() {
    Column() {
      Row() {
        // 左侧：NutriScore 徽章（紧凑版）
        NutriScoreBadge({
          score: this.nutriScore,
          diameter: 100,
          animating: this.showNutriAnim,
          levelText: this.selectedRec.level as string,
          levelBgColor: getLevelColorValue(this.selectedRec.levelColor)
        })

        // 右侧：适配结论 + 最大可吃量 + 成员胶囊
        Column() {
          // 最大可吃量行（紧凑突出显示）
          if (this.selectedRec.maxAmount > 0) {
            Row() {
              Text('今日参考: ')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_TERTIARY)
              Text(`${this.selectedRec.maxAmount}g`)
                .fontSize(FONT_SIZE.XL)
                .fontWeight(FONT_WEIGHT.BOLD)
                .fontColor(COLORS.TEXT_PRIMARY)
              Text(' / 100g')
                .fontSize(FONT_SIZE.TINY)
                .fontColor(COLORS.TEXT_TERTIARY)
                .margin({ left: 2 })
                .alignSelf(ItemAlign.End)
            }
            .margin({ bottom: 4 })
          }

          // 主要原因行（一句话摘要）
          if (this.selectedRec.reasons.length > 0) {
            Row() {
              Text('📰 ')
                .fontSize(FONT_SIZE.SMALL)
              Text(this.selectedRec.reasons[0])
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .lineHeight(18)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .margin({ bottom: 4 })
          }

          // 家庭成员横向胶囊切换器
          this.MemberCapsuleSwitcher()
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16, top: 12, bottom: 6 })
      .backgroundColor(COLORS.WHITE)
      .borderRadius({
        topLeft: RADIUS.LG,
        topRight: RADIUS.LG
      })

      // 提醒列表（紧凑展示）
      if (this.selectedRec.reminders.length > 0) {
        Column() {
          ForEach(this.selectedRec.reminders, (reminder: string) => {
            Row() {
              Text('• ')
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.ACCENT_BLUE)
              Text(reminder)
                .fontSize(FONT_SIZE.SMALL)
                .fontColor(COLORS.TEXT_SECONDARY)
                .lineHeight(18)
            }
            .margin({ bottom: 2 })
            .width('100%')
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 6 })
      }

      // 营养成分快速摘要
      this.NutritionQuickSummary()
    }
    .width('100%')
    .backgroundColor(COLORS.WHITE)
    .margin({ top: 4 })
  }'''

new_content = content[:idx_start] + new_builder + content[end_idx:]

# Verify
if len(new_content) != len(content) - len(old) + len(new_builder):
    print(f"Length changed: {len(content)} -> {len(new_content)}")
else:
    print("Length unchanged")

with open('E:/APP/family_food_app/entry/src/main/ets/pages/ReportPage.ets', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Done - HeroSection updated")

# Edit ReportPage.ets - MemberCapsuleSwitcher compact
with open('E:/APP/family_food_app/entry/src/main/ets/pages/ReportPage.ets', 'r', encoding='utf-8') as f:
    content = f.read()

# Find MemberCapsuleSwitcher
start_marker = '  MemberCapsuleSwitcher() {'
idx_start = content.find(start_marker)
if idx_start < 0:
    print("ERROR: Could not find MemberCapsuleSwitcher")
    exit(1)

# Find the end - next @Builder or pattern
end_marker = '  // 获取成员头像（优先使用emoji图标）'
idx_end = content.find(end_marker, idx_start)
if idx_end < 0:
    print("ERROR: Could not find end marker")
    exit(1)

old = content[idx_start:idx_end]
print(f"Old length: {len(old)}")
print(f"Old first 100: {repr(old[:100])}")
print(f"Old last 100: {repr(old[-100:])}")

new = '''  MemberCapsuleSwitcher() {
    if (this.familyMembers.length > 0) {
      Scroll() {
        Row({ space: 6 }) {
          ForEach(this.familyMembers, (member: FamilyProfile, index: number) => {
            // 紧凑胶囊 - 100x32px
            Row() {
              // 等级小圆点（简化：仅留圆点表示）
              if (index < this.recommendations.length) {
                Row()
                  .width(6)
                  .height(6)
                  .borderRadius(3)
                  .backgroundColor(getLevelColorValue(this.recommendations[index].levelColor))
                  .margin({ right: 4 })
              }
              // 成员昵称缩写
              Text(member.nickname.length > 3 ?
                member.nickname.substring(0, 2) : member.nickname)
                .fontSize(FONT_SIZE.TINY)
                .fontWeight(this.selectedMemberIndex === index ?
                  FONT_WEIGHT.BOLD : FONT_WEIGHT.REGULAR)
                .fontColor(this.selectedMemberIndex === index ?
                  COLORS.TEXT_PRIMARY : COLORS.TEXT_TERTIARY)
                .maxLines(1)
            }
            .height(28)
            .padding({ left: 10, right: 10 })
            .borderRadius(14)
            .backgroundColor(this.selectedMemberIndex === index ?
              COLORS.BG_PAGE : '#F9F9F9')
            .border({
              width: 1,
              color: this.selectedMemberIndex === index ?
                getLevelColorValue(this.recommendations[index]?.levelColor ?? LevelColor.GREEN) :
                '#E8E8E8'
            })
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.selectedMemberIndex = index
            })
          })
        }
        .padding({ left: 2, right: 2 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .width('100%')
      .height(34)
      .scrollBar(BarState.Off)
      .padding({ top: 0 })
    }
  }

  // 获取成员头像（优先使用emoji图标）'''

content = content[:idx_start] + new + content[idx_end:]

with open('E:/APP/family_food_app/entry/src/main/ets/pages/ReportPage.ets', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done - MemberCapsuleSwitcher compacted")

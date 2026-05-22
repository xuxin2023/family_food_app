import { RecommendLevel, LevelColor, getLevelColorValue, COLORS } from 'hsp_core';
// 四级建议标识组件


@ComponentV2
export struct LevelBadge {
  @Param level: RecommendLevel = RecommendLevel.SUITABLE;
  @Param levelColor: LevelColor = LevelColor.GREEN;
  @Param fontSize: number = 14;

  build() {
    Text(this.level)
      .fontSize(this.fontSize)
      .fontColor(COLORS.WHITE)
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .borderRadius(10)
      .backgroundColor(getLevelColorValue(this.levelColor))
  }
}
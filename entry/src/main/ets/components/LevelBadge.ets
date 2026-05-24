import { RecommendLevel, LevelColor, getLevelColorValue, COLORS } from 'hsp_core';
import { ElderModeManager } from '../service/ElderModeManager';

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
      .responseRegion({ x: 0, y: 0, width: ElderModeManager.getInstance().getTouchTarget(), height: ElderModeManager.getInstance().getTouchTarget() })
      .borderRadius(10)
      .backgroundColor(getLevelColorValue(this.levelColor))
      .accessibilityText(this.level)
      .accessibilityLevel('yes')
  }
}
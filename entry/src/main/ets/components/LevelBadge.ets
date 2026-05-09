// 四级建议标识组件

import { RecommendLevel, LevelColor, getLevelColorValue } from '../model/Recommendation';
import { COLORS } from '../constants/AppTheme';
import { HILOG_DOMAIN } from '../constants/AppConfig';

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
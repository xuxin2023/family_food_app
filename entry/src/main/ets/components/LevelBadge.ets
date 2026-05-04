// 四级建议标识组件

import { RecommendLevel, LevelColor, getLevelColorValue } from '../model/Recommendation';
import { COLORS } from '../constants/AppTheme';

@Component
export struct LevelBadge {
  @Prop level: RecommendLevel = RecommendLevel.SUITABLE;
  @Prop levelColor: LevelColor = LevelColor.GREEN;
  @Prop fontSize: number = 14;

  build() {
    Text(this.level)
      .fontSize(this.fontSize)
      .fontColor(COLORS.WHITE)
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .borderRadius(10)
      .backgroundColor(getLevelColorValue(this.levelColor))
  }
}

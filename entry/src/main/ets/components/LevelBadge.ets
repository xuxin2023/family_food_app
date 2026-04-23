// 四级建议标识组件

import { RecommendLevel, LevelColor, getLevelColorValue } from '../model/Recommendation';

@Component
export struct LevelBadge {
  @Prop level: RecommendLevel = RecommendLevel.SUITABLE;
  @Prop levelColor: LevelColor = LevelColor.GREEN;
  @Prop fontSize: number = 14;

  build() {
    Text(this.level)
      .fontSize(this.fontSize)
      .fontColor('#FFFFFF')
      .padding({ left: 10, right: 10, top: 3, bottom: 3 })
      .borderRadius(10)
      .backgroundColor(getLevelColorValue(this.levelColor))
  }
}

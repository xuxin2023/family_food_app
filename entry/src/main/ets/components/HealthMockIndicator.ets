// HealthMockIndicator.ets
// 健康数据模拟指示器 - 当健康数据来自模拟数据时显示提示横幅
// 符合HarmonyOS 6.1 V2状态管理规范

import { HealthSignal, DataSource } from 'hsp_core';

@ComponentV2
export struct HealthMockIndicator {
  @Param signal: HealthSignal = new HealthSignal();

  build() {
    if (this.signal.isMock || this.signal.source === DataSource.MANUAL) {
      Row() {
        Text('\u26A0\uFE0F')
          .fontSize(14)
          .margin({ right: 6 })

        Column() {
          Text($r('app.string.health_mock_data_estimated'))
            .fontSize(12)
            .fontColor('#FF5722')
            .fontWeight(FontWeight.Medium)
          Text($r('app.string.health_mock_connect_hint'))
            .fontSize(10)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)

        Blank()

        Text($r('app.string.health_mock_connect_device'))
          .fontSize(11)
          .fontColor('#2196F3')
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .borderRadius(8)
      .backgroundColor($r('app.color.bg_warm_orange'))
      .alignItems(VerticalAlign.Center)
    }
  }
}

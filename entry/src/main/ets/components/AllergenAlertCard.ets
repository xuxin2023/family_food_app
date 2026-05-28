import { SuspectedAllergen, AllergenAutoDetector } from 'feature_scan';
import { FamilyProfile, COLORS, RADIUS } from 'hsp_core';

@ComponentV2
export struct AllergenAlertCard {
  @Param suspectedAllergens: SuspectedAllergen[] = [];
  @Param memberName: string = '';

  build() {
    if (this.suspectedAllergens.length > 0) {
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Text('⚠️')
            .fontSize(18)
          Text('疑似过敏原检测')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E53935')
            .layoutWeight(1)
          Text(`${this.suspectedAllergens.length}项`)
            .fontSize(12)
            .fontColor('#999999')
        }
        .width('100%')

        ForEach(this.suspectedAllergens.slice(0, 3), (item: SuspectedAllergen) => {
          Row({ space: 8 }) {
            Text('•')
              .fontSize(14)
              .fontColor('#E53935')
            Text(item.ingredient)
              .fontSize(14)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
            Text(`置信度 ${(item.confidence * 100).toFixed(0)}%`)
              .fontSize(12)
              .fontColor(item.confidence > 0.7 ? '#E53935' : '#FF9800')
            Text(`${item.evidenceCount}次记录`)
              .fontSize(11)
              .fontColor('#999999')
          }
          .width('100%')
          .padding({ left: 16, right: 8, top: 4, bottom: 4 })
        }, (item: SuspectedAllergen) => item.ingredient)

        Text('建议在过敏原配置中添加以上成分，系统将自动预警')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFF3F0')
      .borderRadius(RADIUS.MD)
      .border({ width: 1, color: '#FFCDD2' })
    }
  }
}

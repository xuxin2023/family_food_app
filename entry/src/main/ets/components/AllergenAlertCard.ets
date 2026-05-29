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
          Text($r('app.string.suspected_allergen_title'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.danger'))
            .layoutWeight(1)
          Text(`${this.suspectedAllergens.length}项`)
            .fontSize(12)
            .fontColor($r('app.color.text_hint'))
        }
        .width('100%')

        ForEach(this.suspectedAllergens.slice(0, 3), (item: SuspectedAllergen) => {
          Row({ space: 8 }) {
            Text('•')
              .fontSize(14)
              .fontColor($r('app.color.danger'))
            Text(item.ingredient)
              .fontSize(14)
              .fontColor(COLORS.TEXT_PRIMARY)
              .layoutWeight(1)
            Text(`置信度 ${(item.confidence * 100).toFixed(0)}%`)
              .fontSize(12)
              .fontColor(item.confidence > 0.7 ? $r('app.color.danger') : $r('app.color.warning_amber'))
            Text(`${item.evidenceCount}次记录`)
              .fontSize(11)
              .fontColor($r('app.color.text_hint'))
          }
          .width('100%')
          .padding({ left: 16, right: 8, top: 4, bottom: 4 })
        }, (item: SuspectedAllergen) => item.ingredient)

        Text($r('app.string.suspected_allergen_suggestion'))
          .fontSize(12)
          .fontColor($r('app.color.text_hint'))
          .margin({ top: 4 })
      }
      .width('100%')
      .padding(16)
      .backgroundColor($r('app.color.bg_danger_light'))
      .borderRadius(RADIUS.MD)
      .border({ width: 1, color: $r('app.color.border_danger_light') })
    }
  }
}

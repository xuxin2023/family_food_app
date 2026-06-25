// AllergyAlertBanner.ets
// 过敏原预警横幅组件 — 对标Yuka/Olive过敏原预警UI
// 红色=过敏 / 黄色=不耐受 / 橙色=交叉污染 / 蓝色=提示

import { COLORS, FONT_SIZE, FONT_WEIGHT, SPACING, RADIUS, Severity } from 'hsp_core';

export class AllergyAlertData {
  severity: Severity = Severity.MILD;
  type: 'allergy' | 'intolerance' | 'cross' | 'info' = 'info';
  memberName: string = '';
  allergen: string = '';
  advice: string = '';
  detail: string = '';
  affectedCount: number = 0;
}

@ComponentV2
export struct AllergyAlertBanner {
  @Param data: AllergyAlertData = new AllergyAlertData();
  @Param showDetail: boolean = false;
  @Event onShowDetail?: () => void;

  @Computed
  get bannerColor(): string {
    switch (this.data.type) {
      case 'allergy':
        if (this.data.severity === Severity.LIFE_THREATENING) return '#B71C1C';
        return '#F44336';
      case 'intolerance': return '#FF9800';
      case 'cross': return '#FF9800';
      default: return '#2196F3';
    }
  }

  @Computed
  get bannerIcon(): string {
    switch (this.data.type) {
      case 'allergy': return '⚠️';
      case 'intolerance': return '⚡';
      case 'cross': return '🔄';
      default: return 'ℹ️';
    }
  }

  @Computed
  get typeLabel(): string {
    switch (this.data.type) {
      case 'allergy': return '过敏预警';
      case 'intolerance': return '不耐受提示';
      case 'cross': return '交叉反应风险';
      default: return '安全提示';
    }
  }

  build() {
    Column() {
      Row() {
        Text(this.bannerIcon)
          .fontSize(18)
          .margin({ right: SPACING.SM })

        Column() {
          Text(this.typeLabel)
            .fontSize(FONT_SIZE.TINY)
            .fontColor('#FFFFFF')
            .fontWeight(FONT_WEIGHT.BOLD)
            .opacity(0.9)

          Text(`${this.data.memberName}: ${this.data.allergen}`)
            .fontSize(FONT_SIZE.BODY)
            .fontColor('#FFFFFF')
            .fontWeight(FONT_WEIGHT.MEDIUM)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        if (this.data.affectedCount > 1) {
          Badge({
            value: `${this.data.affectedCount}人`,
            style: { color: '#FFFFFF', badgeColor: 'rgba(255,255,255,0.3)' }
          })
        }
      }
      .width('100%')
      .padding({ left: SPACING.MD, right: SPACING.MD,
        top: SPACING.SM, bottom: SPACING.SM })

      if (this.data.detail.length > 0) {
        Text(this.data.detail)
          .fontSize(FONT_SIZE.TINY)
          .fontColor('#FFFFFF')
          .opacity(0.85)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .padding({ left: SPACING.MD, right: SPACING.MD,
            bottom: SPACING.SM })
      }

      if (this.data.advice.length > 0) {
        Row() {
          Text('💡')
            .fontSize(14)
          Text(this.data.advice)
            .fontSize(FONT_SIZE.SMALL)
            .fontColor('#FFFFFF')
            .opacity(0.9)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ left: SPACING.MD, right: SPACING.MD,
          bottom: SPACING.SM })
      }
    }
    .width('100%')
    .backgroundColor(this.bannerColor)
    .borderRadius(RADIUS.MD)
    .onClick(() => {
      if (this.onShowDetail) {
        this.onShowDetail();
      }
    })
    .accessibilityText(`${this.typeLabel}: ${this.data.memberName} ${this.data.allergen} ${this.data.advice}`)
    .accessibilityLevel('yes')
  }
}
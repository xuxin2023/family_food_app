import { SCORE_COLORS } from 'hsp_core';

@ComponentV2
export struct GradeChip {
  @Param grade: string = 'A'
  @Param size: number = 36
  @Param type: string = 'grade'

  private getColor(): string {
    if (this.type === 'nova') {
      if (this.grade === '1') return SCORE_COLORS.NOVA_1;
      if (this.grade === '2') return SCORE_COLORS.NOVA_2;
      if (this.grade === '3') return SCORE_COLORS.NOVA_3;
      return SCORE_COLORS.NOVA_4;
    }
    if (this.type === 'eco') {
      if (this.grade === 'A') return SCORE_COLORS.ECO_A;
      if (this.grade === 'B') return SCORE_COLORS.ECO_B;
      if (this.grade === 'C') return SCORE_COLORS.ECO_C;
      if (this.grade === 'D') return SCORE_COLORS.ECO_D;
      return SCORE_COLORS.ECO_E;
    }
    if (this.grade === 'A') return SCORE_COLORS.GRADE_A;
    if (this.grade === 'B') return SCORE_COLORS.GRADE_B;
    if (this.grade === 'C') return SCORE_COLORS.GRADE_C;
    if (this.grade === 'D') return SCORE_COLORS.GRADE_D;
    return SCORE_COLORS.GRADE_E;
  }

  private getFontSize(): number {
    if (this.size <= 28) return 12;
    if (this.size <= 36) return 16;
    return 20;
  }

  build() {
    Row() {
      Text(this.grade)
        .fontSize(this.getFontSize())
        .fontWeight(700)
        .fontColor('#FFFFFF')
    }
    .width(this.size)
    .height(this.size)
    .borderRadius(this.size / 2)
    .backgroundColor(this.getColor())
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

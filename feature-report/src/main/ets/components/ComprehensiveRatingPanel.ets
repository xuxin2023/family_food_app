import { NutriScore } from 'hsp_core';
import { NovaGroup } from 'feature_scan';

@ComponentV2
export struct ComprehensiveRatingPanel {
  @Param nutriScore: NutriScore = NutriScore.UNKNOWN;
  @Param novaGroup: NovaGroup = NovaGroup.UNKNOWN;
  @Param ecoScoreGrade: string = 'unknown';
  @Param ecoScoreScore: number = 0;
  @Param showDetail: boolean = false;

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        this.NutriScoreBadge()
        this.NovaGroupBadge()
        this.EcoScoreBadge()
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)

      Row() {
        Text('综合评级')
          .fontSize(12)
          .fontColor('#666666')
        Progress({ value: this.comprehensiveScore, total: 100 })
          .width('60%')
          .height(6)
          .color(this.comprehensiveColor)
          .borderRadius(3)
        Text(`${Math.round(this.comprehensiveScore)}分`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.comprehensiveColor)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16 })

      if (this.showDetail) {
        this.DetailRow('营养评分', `${this.nutriScore}`, this.nutriScoreColor)
        this.DetailRow('加工程度', `${this.novaGroup}`, this.novaGroupColor)
        this.DetailRow('生态评分', this.ecoScoreGrade, this.ecoScoreColor)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  @Builder
  NutriScoreBadge() {
    Column() {
      Text(this.nutriScoreLetter)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.nutriScoreColor)
      Text('Nutri-Score')
        .fontSize(10)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width(80)
    .height(80)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.nutriScoreBgColor)
    .borderRadius(12)
  }

  @Builder
  NovaGroupBadge() {
    Column() {
      Text(this.novaGroupNumber)
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.novaGroupColor)
      Text('Nova Group')
        .fontSize(10)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width(80)
    .height(80)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.novaGroupBgColor)
    .borderRadius(12)
  }

  @Builder
  EcoScoreBadge() {
    Column() {
      Text(this.ecoScoreGrade.length > 0 ? this.ecoScoreGrade.toUpperCase() : '?')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.ecoScoreColor)
      Text('Eco-Score')
        .fontSize(10)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .width(80)
    .height(80)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.ecoScoreBgColor)
    .borderRadius(12)
  }

  @Builder
  DetailRow(label: string, value: string, color: string) {
    Row() {
      Text(label)
        .fontSize(12)
        .fontColor('#666666')
        .layoutWeight(1)
      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(color)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  private get nutriScoreLetter(): string {
    return `${this.nutriScore}`;
  }

  private get nutriScoreColor(): string {
    const s = `${this.nutriScore}`;
    if (s === 'A') return '#1B8A3E';
    if (s === 'B') return '#7AC043';
    if (s === 'C') return '#FFC107';
    if (s === 'D') return '#FF8C00';
    if (s === 'E') return '#E53935';
    return '#9E9E9E';
  }

  private get nutriScoreBgColor(): string {
    return this.nutriScoreColor + '1A';
  }

  private get novaGroupNumber(): string {
    return `${this.novaGroup}`;
  }

  private get novaGroupColor(): string {
    const n = Number(this.novaGroup);
    if (n <= 1) return '#1B8A3E';
    if (n === 2) return '#7AC043';
    if (n === 3) return '#FFC107';
    return '#E53935';
  }

  private get novaGroupBgColor(): string {
    return this.novaGroupColor + '1A';
  }

  private get ecoScoreColor(): string {
    const g = this.ecoScoreGrade.toUpperCase();
    if (g === 'A') return '#1B8A3E';
    if (g === 'B') return '#7AC043';
    if (g === 'C') return '#FFC107';
    if (g === 'D') return '#FF8C00';
    if (g === 'E') return '#E53935';
    return '#9E9E9E';
  }

  private get ecoScoreBgColor(): string {
    return this.ecoScoreColor + '1A';
  }

  private get comprehensiveScore(): number {
    const nutriVal = this.nutriScoreToNumber();
    const novaVal = this.novaGroupToNumber();
    const ecoVal = this.ecoScoreToNumber();
    return nutriVal * 0.4 + novaVal * 0.3 + ecoVal * 0.3;
  }

  private get comprehensiveColor(): string {
    if (this.comprehensiveScore >= 70) return '#1B8A3E';
    if (this.comprehensiveScore >= 50) return '#7AC043';
    if (this.comprehensiveScore >= 30) return '#FFC107';
    return '#E53935';
  }

  private nutriScoreToNumber(): number {
    const s = `${this.nutriScore}`;
    const map: Record<string, number> = { 'A': 100, 'B': 75, 'C': 50, 'D': 25, 'E': 0 };
    return map[s] ?? 50;
  }

  private novaGroupToNumber(): number {
    const n = Number(this.novaGroup);
    return Math.max(0, (4 - n) / 3 * 100);
  }

  private ecoScoreToNumber(): number {
    if (this.ecoScoreScore > 0) return this.ecoScoreScore;
    const map: Record<string, number> = { 'A': 100, 'B': 75, 'C': 50, 'D': 25, 'E': 0 };
    return map[this.ecoScoreGrade.toUpperCase()] ?? 50;
  }
}

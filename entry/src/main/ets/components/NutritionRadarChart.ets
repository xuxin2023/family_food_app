// NutritionRadarChart.ets
// 六维营养雷达图 — 直观展示食品营养分布
// V2: @Monitor 缓存 path 计算，避免每次 build 重复运算

import { COLORS } from 'hsp_core';

export class NutrientDimension {
  name: string = '';
  label: string = '';
  value: number = 0;
  maxValue: number = 100;
  unit: string = '';
}

@ComponentV2
export struct NutritionRadarChart {
  @Param dimensions: NutrientDimension[] = [];
  @Param size: number = 200;

  @Local private cachedHexPaths: string[] = [];
  @Local private cachedDataPath: string = '';
  @Local private cachedLabelPositions: Position[] = [];
  private lastDimsSignature: string = '';
  private lastSize: number = 0;

  private normalize(val: number, max: number): number {
    if (max <= 0) return 0;
    return Math.min(1, Math.max(0, val / max));
  }

  private computeSignature(): string {
    const dimSig = this.dimensions.map(d => `${d.value}:${d.maxValue}`).join('|');
    return `${this.size}:${this.dimensions.length}:${dimSig}`;
  }

  private recomputePaths(): void {
    const sig = this.computeSignature();
    if (sig === this.lastDimsSignature && this.size === this.lastSize) {
      return;
    }
    this.lastDimsSignature = sig;
    this.lastSize = this.size;

    const levels = [0.2, 0.4, 0.6, 0.8, 1.0];
    this.cachedHexPaths = levels.map((level: number) => this.hexagonPath(level));
    this.cachedDataPath = this.dataPath();
    this.cachedLabelPositions = this.dimensions.map((_: NutrientDimension, idx: number) => this.labelPosition(idx));
  }

  build() {
    Stack() {
      if (this.dimensions.length < 3) {
        Text('需要至少3个营养维度')
          .fontSize(12)
          .fontColor(COLORS.TEXT_TERTIARY)
      } else {
        this.recomputePaths()

        ForEach([0, 1, 2, 3, 4], (idx: number) => {
          Shape() {
            Path()
              .commands(this.cachedHexPaths[idx])
          }
          .width(this.size)
          .height(this.size)
          .stroke(COLORS.BORDER_LIGHT_DD)
          .strokeWidth(0.5)
          .fill('none')
        }, (idx: number) => `${idx}`)

        Shape() {
          Path()
            .commands(this.cachedDataPath)
        }
        .width(this.size)
        .height(this.size)
        .fill(COLORS.PRIMARY + '33')
        .stroke(COLORS.PRIMARY)
        .strokeWidth(2)

        ForEach(this.dimensions, (dim: NutrientDimension, idx: number) => {
          Column() {
            Text(dim.name)
              .fontSize(9)
              .fontColor(COLORS.TEXT_TERTIARY)
            Text(`${Math.round(dim.value)}${dim.unit}`)
              .fontSize(8)
              .fontColor(COLORS.TEXT_SECONDARY)
          }
          .position(this.cachedLabelPositions[idx])
        }, (dim: NutrientDimension, idx: number) => `${idx}`)
      }
    }
    .width(this.size)
    .height(this.size)
    .accessibilityLevel('auto')
    .accessibilityText(this.dimensions.filter((d: NutrientDimension) => d.value > 0)
      .map((d: NutrientDimension) => `${d.label || d.name}${Math.round(d.value / d.maxValue * 100)}%`).join('，'))
  }

  private hexagonPath(level: number): string {
    const cx = this.size / 2;
    const cy = this.size / 2;
    const r = (this.size / 2 - 20) * level;
    const n = this.dimensions.length > 0 ? this.dimensions.length : 6;
    let cmds = `M ${cx + r} ${cy}`;
    for (let i = 1; i <= n; i++) {
      const angle = (2 * Math.PI * i) / n;
      cmds += ` L ${cx + r * Math.cos(angle)} ${cy + r * Math.sin(angle)}`;
    }
    cmds += ' Z';
    return cmds;
  }

  private dataPath(): string {
    const cx = this.size / 2;
    const cy = this.size / 2;
    const maxR = this.size / 2 - 20;
    const n = this.dimensions.length;
    if (n === 0) return '';
    let cmds = '';
    for (let i = 0; i <= n; i++) {
      const idx = i % n;
      const angle = (2 * Math.PI * idx) / n;
      const norm = this.normalize(this.dimensions[idx].value, this.dimensions[idx].maxValue);
      const r = maxR * norm;
      const x = cx + r * Math.cos(angle);
      const y = cy + r * Math.sin(angle);
      cmds += i === 0 ? `M ${x} ${y}` : ` L ${x} ${y}`;
    }
    cmds += ' Z';
    return cmds;
  }

  private labelPosition(idx: number): Position {
    const cx = this.size / 2;
    const cy = this.size / 2;
    const r = this.size / 2 - 2;
    const n = this.dimensions.length;
    const angle = (2 * Math.PI * idx) / n;
    return { x: cx + r * Math.cos(angle) - 20, y: cy + r * Math.sin(angle) - 10 } as Position;
  }
}

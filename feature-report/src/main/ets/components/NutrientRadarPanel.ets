// NutrientRadarPanel.ets
// HM 6.1: CanvasRenderingContext2D 已移除，改用 ArkUI 声明式绘图组件

export class NutrientScores {
  protein: number = 0;
  fiber: number = 0;
  vitamins: number = 0;
  minerals: number = 0;
  healthyFats: number = 0;
}

class ScoreDataItem {
  label: string = '';
  value: number = 0;
  score: number = 0;
  color: string = '';
}

@ComponentV2
export struct NutrientRadarPanel {
  @Param scores: NutrientScores = new NutrientScores()
  @Param showLabels: boolean = true
  @Param chartSize: number = 200
  @Param onDimensionClick?: (dimensionKey: string) => void

  private readonly labels: string[] = ['蛋白质', '膳食纤维', '维生素', '矿物质', '健康脂肪']

  private getAccessibilitySummary(): string {
    return `营养雷达图：蛋白质${this.scores.protein}分，膳食纤维${this.scores.fiber}分，维生素${this.scores.vitamins}分，矿物质${this.scores.minerals}分，健康脂肪${this.scores.healthyFats}分`
  }

  private getScore(key: string): number {
    if (key === 'protein') return this.scores.protein
    if (key === 'fiber') return this.scores.fiber
    if (key === 'vitamins') return this.scores.vitamins
    if (key === 'minerals') return this.scores.minerals
    if (key === 'healthyFats') return this.scores.healthyFats
    return 0
  }

  private getScoreColor(score: number): string {
    if (score >= 75) return '#4CAF50'
    if (score >= 50) return '#FF9800'
    return '#F44336'
  }

  private buildScoreData(): ScoreDataItem[] {
    const keys: string[] = ['protein', 'fiber', 'vitamins', 'minerals', 'healthyFats']
    const result: ScoreDataItem[] = []
    for (let i = 0; i < keys.length; i++) {
      const score = this.getScore(keys[i])
      const item: ScoreDataItem = new ScoreDataItem(
      item.label = this.labels[i]
      item.value = score / 100
      item.score = score
      item.color = this.getScoreColor(score)
      result.push(item)
    }
    return result
  }

  /** 多边形顶点 (预计算) */
  private polygonVertices(items: ScoreDataItem[], scale: number): number[][] {
    const cx: number = this.chartSize / 2
    const cy: number = this.chartSize / 2
    const radius: number = Math.min(cx, cy) * 0.75
    const sides: number = items.length
    const points: number[][] = []
    for (let i = 0; i < sides; i++) {
      const angle: number = (Math.PI * 2 * i) / sides - Math.PI / 2
      const r: number = radius * items[i].value * scale
      points.push([cx + r * Math.cos(angle), cy + r * Math.sin(angle)])
    }
    return points
  }

  /** 构建多边形 Path 命令字符串 */
  private polyPath(points: number[][]): string {
    if (points.length === 0) return ''
    let path: string = `M ${points[0][0]} ${points[0][1]}`
    for (let i = 1; i < points.length; i++) {
      path += ` L ${points[i][0]} ${points[i][1]}`
    }
    path += ' Z'
    return path
  }

  /** 轴线端点 (从中心到多边形的第 i 个顶点, scale=1) */
  private axisEndpoint(items: ScoreDataItem[], index: number): number[] {
    const cx: number = this.chartSize / 2
    const cy: number = this.chartSize / 2
    const radius: number = Math.min(cx, cy) * 0.75
    const angle: number = (Math.PI * 2 * index) / items.length - Math.PI / 2
    return [cx + radius * Math.cos(angle), cy + radius * Math.sin(angle)]
  }

  build() {
    Column({ space: 8 }) {
      if (this.chartSize > 0) {
        Stack() {
          // 背景网格
          ForEach([1, 2, 3, 4], (ring: number) => {
            Path()
              .commands(this.polyPath(
                this.polygonVertices(this.buildScoreData(), ring / 4)
              ))
              .stroke('#e0e0e0')
              .strokeWidth(1)
              .fillOpacity(0)
          }, (ring: number) => `grid_${ring}`)

          // 轴线
          ForEach(this.buildScoreData(), (_: ScoreDataItem, i: number) => {
            Line()
              .startPoint([this.chartSize / 2, this.chartSize / 2])
              .endPoint(this.axisEndpoint(this.buildScoreData(), i))
              .stroke('#e0e0e0')
              .strokeWidth(1)
          }, (_: ScoreDataItem, i: number) => `axis_${i}`)

          // 数据面
          Path()
            .commands(this.polyPath(
              this.polygonVertices(this.buildScoreData(), 1)
            ))
            .fill('rgba(76, 175, 80, 0.2)')
            .stroke('#4CAF50')
            .strokeWidth(2)

          // 数据点
          ForEach(
            this.polygonVertices(this.buildScoreData(), 1),
            (pt: number[], i: number) => {
              Circle()
                .width(8)
                .height(8)
                .fill(this.buildScoreData()[i].color)
                .position({ x: pt[0] - 4, y: pt[1] - 4 })
            },
            (_: number[], i: number) => `dot_${i}`
          )
        }
        .width(this.chartSize)
        .height(this.chartSize)
      }

      if (this.showLabels) {
        ForEach(this.buildScoreData(), (item: ScoreDataItem, i: number) => {
          Row({ space: 6 }) {
            Circle()
              .width(8)
              .height(8)
              .fill(item.color as ResourceColor)
            Text(`${item.label}: ${item.score}`)
              .fontSize(12)
              .fontColor('#333333')
          }
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            const keys: string[] = ['protein', 'fiber', 'vitamins', 'minerals', 'healthyFats'];
            if (this.onDimensionClick && i < keys.length) {
              this.onDimensionClick(keys[i]);
            }
          })
        }, (item: ScoreDataItem, i: number) => `score_${i}`)
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .accessibilityRole('image')
    .accessibilityText(this.getAccessibilitySummary())
    .accessibilityLevel('yes')
  }
}

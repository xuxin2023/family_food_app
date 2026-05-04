// NutrientRadarPanel.ets
// 营养雷达图组件 — 使用 Canvas 绘制五维营养评分

export interface NutrientScores {
  protein: number;    // 0-100
  fiber: number;      // 0-100
  vitamins: number;   // 0-100
  minerals: number;   // 0-100
  healthyFats: number; // 0-100
}

@Component
export struct NutrientRadarPanel {
  @Prop scores: NutrientScores = {
    protein: 70,
    fiber: 50,
    vitamins: 80,
    minerals: 60,
    healthyFats: 65
  }
  @Prop showLabels: boolean = true
  @Prop chartSize: number = 200

  private readonly labels: string[] = ['蛋白质', '膳食纤维', '维生素', '矿物质', '健康脂肪']

  // 工具方法 — 注意这些不能在 @Builder 中使用非UI语法
  private getScore(key: string): number {
    const map: Map<string, number> = new Map()
    map.set('protein', this.scores.protein)
    map.set('fiber', this.scores.fiber)
    map.set('vitamins', this.scores.vitamins)
    map.set('minerals', this.scores.minerals)
    map.set('healthyFats', this.scores.healthyFats)
    return map.get(key) ?? 0
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
      const item: ScoreDataItem = {
        label: this.labels[i],
        value: score / 100,
        score: score,
        color: this.getScoreColor(score)
      }
      result.push(item)
    }
    return result
  }

  build() {
    Column({ space: 8 }) {
      if (this.chartSize > 0) {
        // 使用 Canvas 绘制雷达图
        Canvas(this.contextReady.bind(this))
          .width(this.chartSize)
          .height(this.chartSize)
      }

      if (this.showLabels) {
        // 图例和分数显示（用 @Builder 外数据）
        ForEach(this.buildScoreData(), (item: ScoreDataItem) => {
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
        })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }

  private contextReady(ctx: CanvasRenderingContext2D) {
    if (!ctx) {
      return
    }
    this.drawRadarChart(ctx)
  }

  private drawRadarChart(ctx: CanvasRenderingContext2D) {
    const w = this.chartSize
    const h = this.chartSize
    const cx = w / 2
    const cy = h / 2
    const radius = Math.min(cx, cy) * 0.75
    const sides = 5
    const angleStep = (Math.PI * 2) / sides

    ctx.clearRect(0, 0, w, h)

    // 绘制背景网格（同心多边形）
    for (let ring = 1; ring <= 4; ring++) {
      const r = (radius * ring) / 4
      ctx.beginPath()
      for (let i = 0; i <= sides; i++) {
        const angle = angleStep * i - Math.PI / 2
        const x = cx + r * Math.cos(angle)
        const y = cy + r * Math.sin(angle)
        if (i === 0) ctx.moveTo(x, y)
        else ctx.lineTo(x, y)
      }
      ctx.closePath()
      ctx.strokeStyle = '#e0e0e0'
      ctx.lineWidth = 1
      ctx.stroke()
    }

    // 绘制轴线
    for (let i = 0; i < sides; i++) {
      const angle = angleStep * i - Math.PI / 2
      ctx.beginPath()
      ctx.moveTo(cx, cy)
      ctx.lineTo(cx + radius * Math.cos(angle), cy + radius * Math.sin(angle))
      ctx.strokeStyle = '#e0e0e0'
      ctx.lineWidth = 1
      ctx.stroke()
    }

    // 获取分数数据
    const items = this.buildScoreData()

    // 绘制数据多边形
    ctx.beginPath()
    for (let i = 0; i <= sides; i++) {
      const idx = i % sides
      const angle = angleStep * idx - Math.PI / 2
      const r = radius * items[idx].value
      const x = cx + r * Math.cos(angle)
      const y = cy + r * Math.sin(angle)
      if (i === 0) ctx.moveTo(x, y)
      else ctx.lineTo(x, y)
    }
    ctx.closePath()
    ctx.fillStyle = 'rgba(76, 175, 80, 0.2)'
    ctx.fill()
    ctx.strokeStyle = '#4CAF50'
    ctx.lineWidth = 2
    ctx.stroke()

    // 绘制数据点
    for (let i = 0; i < sides; i++) {
      const angle = angleStep * i - Math.PI / 2
      const r = radius * items[i].value
      const x = cx + r * Math.cos(angle)
      const y = cy + r * Math.sin(angle)

      ctx.beginPath()
      ctx.arc(x, y, 4, 0, Math.PI * 2)
      ctx.fillStyle = items[i].color as string
      ctx.fill()

      // 绘制标签
      const labelR = radius + 20
      const lx = cx + labelR * Math.cos(angle)
      const ly = cy + labelR * Math.sin(angle)
      ctx.font = '12px HarmonyOS Sans'
      ctx.textAlign = 'center'
      ctx.textBaseline = 'middle'
      ctx.fillStyle = '#666666'
      ctx.fillText(`${items[i].label}`, lx, ly)
    }
  }
}

interface ScoreDataItem {
  label: string
  value: number
  score: number
  color: string
}

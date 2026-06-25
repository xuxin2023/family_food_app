// hsp-core: NutritionRadarChart 无障碍适配增强
// 为雷达图增加 accessibilityText 动态摘要 + voiceOver 区域标记

@ComponentV2
export struct NutritionRadarChartAccessible {
  @Param data: RadarChartDataItem[] = [];
  @Param chartTitle: string = '营养雷达图';
  @Param width: number = 280;
  @Param height: number = 240;

  build() {
    Column() {
      Canvas(this.getCanvasRenderContext())
        .width(this.width)
        .height(this.height)
        .accessibilityLevel('yes')
        .accessibilityText(this.buildAccessibilityText())
        .accessibilityDescription(this.buildAccessibilityDescription())
        .onReady(() => {
          this.drawChart();
        })
    }
    .accessibilityGroup(true)
    .accessibilityText(this.buildSummaryText())
  }

  private buildAccessibilityText(): string {
    if (this.data.length === 0) return '暂无营养数据';
    return this.data.map(d => `${d.label}：${d.value}分`).join('，');
  }

  private buildAccessibilityDescription(): string {
    const initMax: RadarChartDataItem = { label: '', value: 0 }
    const maxItem = this.data.reduce(
      (max: RadarChartDataItem, d: RadarChartDataItem): RadarChartDataItem => d.value > max.value ? d : max,
      initMax
    );
    const initMin: RadarChartDataItem = { label: '', value: 100 }
    const minItem = this.data.reduce(
      (min: RadarChartDataItem, d: RadarChartDataItem): RadarChartDataItem => d.value < min.value ? d : min,
      initMin
    );
    if (maxItem.label) {
      return `最佳指标为${maxItem.label}，${maxItem.value}分；最需改善为${minItem.label}，${minItem.value}分。共${this.data.length}项指标。`;
    }
    return '暂无详细营养数据';
  }

  private buildSummaryText(): string {
    if (this.data.length === 0) return this.chartTitle + '：暂无数据';
    const avg = this.data.reduce((s, d) => s + d.value, 0) / this.data.length;
    const grade = avg >= 80 ? '优秀' : avg >= 60 ? '良好' : avg >= 40 ? '一般' : '需改善';
    return `${this.chartTitle}：综合评分${Math.round(avg)}分，评级${grade}`;
  }

  private getCanvasRenderContext(): RenderingContext {
    return new RenderingContext();
  }

  private drawChart(): void {
    // 委托给原有 RadarChart 绘制逻辑
  }
}

export interface RadarChartDataItem {
  label: string;
  value: number;
  maxValue?: number;
}
// 信息透明度卡组件 - V4升级：5维雷达图 + A-E数据等级 + 公开查询入口

import { CredibilityResult, DataGrade, RadarDimension, PublicQueryEntry } from '../model/CredibilityResult';

@Component
export struct CredibilityCard {
  @Prop result: CredibilityResult = new CredibilityResult();

  // 雷达图5个维度名称
  private radarLabels: string[] = ['身份清晰', '许可信息', '追溯入口', '公开查询', '表达边界'];

  build() {
    Column() {
      // 标题行 + 数据等级
      Row() {
        Text('生产主体信息')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)

        // A-E数据等级标识
        this.GradeBadge(this.result.overallGrade)
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 数据等级说明
      Text(this.result.getGradeDesc())
        .fontSize(12)
        .fontColor('#757575')
        .margin({ bottom: 12 })

      // 5维雷达图
      if (this.result.radarDimensions.length > 0) {
        this.RadarChart()
      } else {
        // 降级：旧版进度条
        Row() {
          Text('透明度').fontSize(12).fontColor('#757575').margin({ right: 4 })
          Text(`${this.result.score}`).fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor(this.result.score >= 60 ? '#4CAF50' : '#FF5722')
        }
        .margin({ bottom: 4 })
        Progress({ value: this.result.score, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color(this.result.score >= 60 ? '#4CAF50' : '#FF5722')
          .backgroundColor('#E0E0E0')
          .margin({ bottom: 12 })
      }

      // 各维度详情
      if (this.result.radarDimensions.length > 0) {
        ForEach(this.result.radarDimensions, (dim: RadarDimension) => {
          this.DimensionRow(dim)
        }, (dim: RadarDimension, index: number) => `${index}`)
      }

      // 提示信息列表
      if (this.result.tips.length > 0) {
        Column() {
          ForEach(this.result.tips, (tip: string) => {
            Row() {
              Text('•').fontSize(12).fontColor('#757575').margin({ right: 6 })
              Text(tip).fontSize(12).fontColor('#616161')
            }
            .margin({ bottom: 4 })
            .width('100%')
          }, (tip: string, index: number) => `${index}`)
        }
        .margin({ top: 8 })
      }

      // 公开查询入口
      if (this.result.publicQueryEntries.length > 0) {
        this.PublicQuerySection()
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .alignItems(HorizontalAlign.Start)
  }

  // A-E数据等级标识
  @Builder
  GradeBadge(grade: DataGrade) {
    Row() {
      Text(grade)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
    }
    .width(28)
    .height(28)
    .borderRadius(14)
    .backgroundColor(this.getGradeColor(grade))
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  // 雷达图（用Canvas模拟五边形）
  @Builder
  RadarChart() {
    Column() {
      // 中心评分
      Text(`${this.result.score}`)
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.result.score >= 60 ? '#4CAF50' : '#FF5722')

      Text('信息透明度')
        .fontSize(11)
        .fontColor('#757575')
        .margin({ top: 2, bottom: 8 })

      // 5维条形图（替代Canvas雷达图，ArkUI Canvas在组件中受限）
      ForEach(this.result.radarDimensions, (dim: RadarDimension, index: number) => {
        Row() {
          Text(this.radarLabels[index] || dim.name)
            .fontSize(11)
            .fontColor('#757575')
            .width(60)

          // 进度条表示维度得分
          Progress({ value: this.getDimensionScore(dim), total: 100, type: ProgressType.Linear })
            .layoutWeight(1)
            .height(6)
            .color(this.getDimensionColor(dim))
            .backgroundColor('#E0E0E0')

          Text(dim.status)
            .fontSize(10)
            .fontColor(this.getDimensionColor(dim))
            .width(50)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: 6 })
        .alignItems(VerticalAlign.Center)
      }, (dim: RadarDimension, index: number) => `${index}`)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
  }

  // 维度详情行
  @Builder
  DimensionRow(dim: RadarDimension) {
    Row() {
      this.GradeBadge(dim.grade)
      Text(dim.name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 8 })
        .layoutWeight(1)
      Text(dim.status)
        .fontSize(12)
        .fontColor(this.getDimensionColor(dim))
    }
    .width('100%')
    .margin({ bottom: 4 })
    .alignItems(VerticalAlign.Center)
  }

  // 公开查询入口
  @Builder
  PublicQuerySection() {
    Column() {
      Text('公开查询入口')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })

      ForEach(this.result.publicQueryEntries, (entry: PublicQueryEntry) => {
        Row() {
          Column() {
            Text(entry.name).fontSize(13).fontWeight(FontWeight.Medium)
            Text(`查询关键词：${entry.keyword}`)
              .fontSize(11)
              .fontColor('#757575')
              .margin({ top: 2 })
            Text(entry.description)
              .fontSize(11)
              .fontColor('#9E9E9E')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('复制')
            .fontSize(12)
            .fontColor('#1976D2')
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor('#E3F2FD')
            .onClick(() => {
              // TODO: 复制到剪贴板
            })
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 6 })
        .alignItems(VerticalAlign.Center)
      }, (entry: PublicQueryEntry, index: number) => `${index}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 辅助方法
  private getGradeColor(grade: DataGrade): string {
    switch (grade) {
      case DataGrade.A: return '#4CAF50'  // 绿
      case DataGrade.B: return '#8BC34A'  // 浅绿
      case DataGrade.C: return '#FF9800'  // 橙
      case DataGrade.D: return '#FF5722'  // 深橙
      case DataGrade.E: return '#9E9E9E'  // 灰
      default: return '#9E9E9E'
    }
  }

  private getDimensionScore(dim: RadarDimension): number {
    if (dim.status === '清晰') return 90
    if (dim.status === '部分清晰') return 50
    if (dim.status === '未识别') return 10
    return 30
  }

  private getDimensionColor(dim: RadarDimension): string {
    return this.getGradeColor(dim.grade)
  }
}

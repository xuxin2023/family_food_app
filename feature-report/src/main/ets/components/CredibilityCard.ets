// 信息透明度卡组件 - V4升级：5维雷达图 + A-E数据等级 + 公开查询入口
// V5: 实现剪贴板复制功能

import { CredibilityResult, DataGrade, RadarDimension, PublicQueryEntry, COLORS, HILOG_DOMAIN_DEFAULT, ToastHelper } from 'hsp_core';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CredibilityCard';
const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;

@ComponentV2
export struct CredibilityCard {
  @Param result: CredibilityResult = new CredibilityResult();

  // 雷达图5个维度名称
  private radarLabels: ResourceStr[] = [$r('app.string.credibility_radar_identity'), $r('app.string.credibility_radar_license'), $r('app.string.credibility_radar_trace'), $r('app.string.credibility_radar_public'), $r('app.string.credibility_radar_boundary')];

  build() {
    Column() {
      // 标题行 + 数据等级
      Row() {
        Text($r('app.string.producer_identity'))
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
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ bottom: 12 })

      // 5维雷达图
      if (this.result.radarDimensions.length > 0) {
        this.RadarChart()
      } else {
        // 降级：旧版进度条
        Row() {
          Text($r('app.string.transparency')).fontSize(12).fontColor(COLORS.TEXT_GRAY_7575).margin({ right: 4 })
          Text(`${this.result.score}`).fontSize(20).fontWeight(FontWeight.Bold)
            .fontColor(this.result.score >= 60 ? COLORS.ACCENT_GREEN_4CAF : COLORS.ACCENT_ORANGE)
        }
        .margin({ bottom: 4 })
        Progress({ value: this.result.score, total: 100, type: ProgressType.Linear })
          .width('100%')
          .color(this.result.score >= 60 ? COLORS.ACCENT_GREEN_4CAF : COLORS.ACCENT_ORANGE)
          .backgroundColor(COLORS.BORDER_LIGHT)
          .margin({ bottom: 12 })
      }

      // 各维度详情
      if (this.result.radarDimensions.length > 0) {
        ForEach(this.result.radarDimensions, (dim: RadarDimension) => {
          this.DimensionRow(dim)
        }, (_: RadarDimension, index: number) => `${index}`)
      }

      // 提示信息列表
      if (this.result.tips.length > 0) {
        Column() {
          ForEach(this.result.tips, (tip: string) => {
            Row() {
              Text('•').fontSize(12).fontColor(COLORS.TEXT_GRAY_7575).margin({ right: 6 })
              Text(tip).fontSize(12).fontColor(COLORS.TEXT_GRAY_6161)
            }
            .margin({ bottom: 4 })
            .width('100%')
          }, (_tip: string, index: number) => `${index}`)
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
    .backgroundColor(COLORS.WHITE)
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
        .fontColor(COLORS.WHITE)
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
        .fontColor(this.result.score >= 60 ? COLORS.ACCENT_GREEN_4CAF : COLORS.ACCENT_ORANGE)

      Text($r('app.string.info_transparency'))
        .fontSize(11)
        .fontColor(COLORS.TEXT_GRAY_7575)
        .margin({ top: 2, bottom: 8 })

      // 5维条形图（替代Canvas雷达图，ArkUI Canvas在组件中受限）
      ForEach(this.result.radarDimensions, (dim: RadarDimension, index: number) => {
        Row() {
          Text(this.radarLabels[index] || dim.name)
            .fontSize(11)
            .fontColor(COLORS.TEXT_GRAY_7575)
            .width(60)

          // 进度条表示维度得分
          Progress({ value: this.getDimensionScore(dim), total: 100, type: ProgressType.Linear })
            .layoutWeight(1)
            .height(6)
            .color(this.getDimensionColor(dim))
            .backgroundColor(COLORS.BORDER_LIGHT)

          Text(dim.status)
            .fontSize(10)
            .fontColor(this.getDimensionColor(dim))
            .width(50)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .margin({ bottom: 6 })
        .alignItems(VerticalAlign.Center)
      }, (_: RadarDimension, index: number) => `${index}`)
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
      Text($r('app.string.public_query_entry'))
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 12, bottom: 8 })

      ForEach(this.result.publicQueryEntries, (entry: PublicQueryEntry) => {
        Row() {
          Column() {
            Text(entry.name).fontSize(13).fontWeight(FontWeight.Medium)
            Text(`${$r('app.string.credibility_query_keyword')}${entry.keyword}`)
              .fontSize(11)
              .fontColor(COLORS.TEXT_GRAY_7575)
              .margin({ top: 2 })
            Text(entry.description)
              .fontSize(11)
              .fontColor('#9E9E9E')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text($r('app.string.copy_label'))
            .fontSize(12)
            .fontColor(COLORS.PRIMARY)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor('#E3F2FD')
            .onClick(() => {
              this.copyToClipboard(entry.keyword);
            })
            .accessibilityText($r('app.string.credibility_view_detail'))
            .accessibilityLevel('yes')
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .margin({ bottom: 6 })
        .alignItems(VerticalAlign.Center)
      }, (_entry: PublicQueryEntry, index: number) => `${index}`)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 辅助方法
  private getGradeColor(grade: DataGrade): string {
    switch (grade) {
      case DataGrade.A: return COLORS.ACCENT_GREEN_4CAF  // 绿
      case DataGrade.B: return '#8BC34A'  // 浅绿
      case DataGrade.C: return '#FF9800'  // 橙
      case DataGrade.D: return COLORS.ACCENT_ORANGE  // 深橙
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

  /**
   * 复制文本到系统剪贴板
   */
  private copyToClipboard(text: string): void {
    try {
      const pasteData: pasteboard.PasteData = pasteboard.createData(
        pasteboard.MIMETYPE_TEXT_PLAIN, text
      );
      const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
      systemPasteboard.setData(pasteData).then(() => {
        ToastHelper.show(this.getUIContext(), $r('app.string.credibility_copied'), 1500);
      }).catch((err) => {
        hilog.warn(DOMAIN_ZERO, TAG, 'Copy to clipboard failed: %{public}s', err.message);
        ToastHelper.show(this.getUIContext(), $r('app.string.credibility_copy_fail'), 1500);
      });
    } catch (error) {
      hilog.warn(DOMAIN_ZERO, TAG, 'Copy to clipboard error: %{public}s', JSON.stringify(error));
    }
  }
}
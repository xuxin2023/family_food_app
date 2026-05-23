/**
 * 单元格样式
 */
export class CJCellStyle {
  // 农历字体大小
  descFontSize?: number | string | Resource = 12
  // 农历字体颜色
  descFontColor?: ResourceColor
  // 不可用描述字体色
  descDisabledFontColor?: ResourceColor
  // 农历选中时字体颜色
  descSelectFontColor?: ResourceColor
  // 农历字体Weight
  descFontFontWeight?: FontWeight = FontWeight.Normal
  // 农历与日期的间距
  descMargin?: number = 0
  fontSize?: number | string | Resource = 18
  fontColor?: ResourceColor = "#252a34"
  fontFontWeight?: FontWeight = FontWeight.Normal
  // 今日不可用字体颜色
  todayFontColor?: string // = "#03A9F4"
  todayFontSize?: number | string | Resource // = "#03A9F4"
  todayBackgroundColor?: string // = "#FFFFFF"
  todayDisabledFontColor?: ResourceColor // = "#03A9F4"
  todayDisabledBackgroundColor?: ResourceColor // = "#FFFFFF"
  // 不能使用的日期字体颜色
  disabledFontColor?: ResourceColor = "#B1B1B1"
  // 不可用cell背景色
  disabledBackgroundColor?: ResourceColor
  // 选中日期字体颜色
  selectFontColor?: string // = "#FFFFFF"
  // 选中字体大小
  selectFontSize?: number | string | Resource = 20
  // 选中日期背景颜色, 默认与todayFontColor一致
  itemBackgroundColor?: ResourceColor = "#00000000"
  selectItemBackgroundColor?: string //= "#03A9F4"
  /**
   * RANGE 模式下生效，中间区域颜色变淡比例，范围：0-1
   */
  lightRatio: number = 0.65
  // 边框样式
  /** 边框颜色 */
  borderColor?: string
  /** 边框宽度 */
  borderWidth?: Length = 1
  /** 边框圆角 */
  borderRadius?: Length
  /** 选中边框颜色 */
  selectBoderColor?: string
  selectBoderWidth?: Length = 1
  // 标注字体大小
  markFontSize?: Length = 10
  // 标注字体颜色
  markFontColor?: ResourceColor // = "#03A9F4"
  markBackgroundColor?: ResourceColor
  markRadius?: Length
  markPadding?: Padding | Length | LocalizedPadding
  markSelectedFontColor?: ResourceColor // = "#03A9F4"
  markDisabledFontColor?: ResourceColor // = "#03A9F4"
  // 标注字体
  markFontWeight?: FontWeight = FontWeight.Normal
  // 标记边距
  markMarin?: Length = 4
  markImageWidth?: Length = 8
  markAlignment?: Alignment = Alignment.TopEnd
}

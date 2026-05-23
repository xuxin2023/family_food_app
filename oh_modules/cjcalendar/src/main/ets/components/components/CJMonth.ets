import { Solar } from 'lunar'
import { CJDateItem } from './CJDateItem'
import { SelectedShape } from './SelectedShape'
import { OptMode } from './OptMode'
import { SelectedStyle } from './SelectedStyle'
import { CJCalStyle } from './CJCalStyle'
import { CJCellStyle } from './CJCellStyle'
import { CellStatus } from './CellStatus'
import { CJWeek } from './CJWeek'
import { CJViewModel } from './CJViewModel'
import { CJMonthController } from './CJMonthController'
import { CJCalendarControlV2 } from './CJCalendarControlV2'
import { CJDay } from './CJDay'
import { CJLogUtil } from '../../utils/CJLogUtil'
import { WeekStartMode } from '../data/WeekStartMode'

const TAG = "CJMonth"

@Component
export struct CJMonth {
  cjMonthController: CJMonthController = new CJMonthController()
  @Consume selectedItems: Array<CJDateItem>
  @Consume extras: Record<string, number | string | boolean> | undefined
  @State weeks: Array<Array<CJDateItem>> = new Array()
  @State days: Array<CJDateItem> = new Array()
  @Consume itemCellHeight: number
  @Consume tempSelectedItem: CJDateItem
  @State month: CJDateItem | undefined = undefined
  @Consume weekStartMode: WeekStartMode
  weekCount: number = 1
  today: CJDateItem = new CJDateItem(new Date())
  startDate: Date = new Date("1970-01-01")
  endDate: Date = new Date(this.today.fullYear + 10, 0, 1)
  onReady?: (cjMonthController: CJMonthController) => void
  //======================

  // 缓存月数
  cacheMaonthCount: number = 1
  // 初始化默认选中日期：["2024-06-07"]
  defSelectedItems: Array<string | Date> | undefined = undefined
  /** 默认选中形状 */
  selectedShape: SelectedShape = SelectedShape.SHAPE_RECT
  //================
  /** 操作模式 */
  optMode: OptMode = OptMode.NORMAL
  selectedStyle: SelectedStyle = SelectedStyle.ALONE
  /** 样式 */
  calStyle: CJCalStyle = new CJCalStyle()
  cjDataItem?: CJDateItem
  @State animDuration: number = 500
  // =====theme======
  @Consume themeColor: string
  @Consume selectedBorderRadius: number
  @Consume isNeedMarkToday: boolean
  itemFontColor: ResourceColor = "#252a34"
  cjCellStatus: CellStatus = new CellStatus()
  cjCellStyle: CJCellStyle = new CJCellStyle()
  // 不能使用的日期字体颜色
  disabledFontColor: ResourceColor = "#9E9E9E"
  // 是否仅显示当月日期
  @Consume onlyShowCurrMonthDay: boolean
  // 是否显示农历
  @Consume showLunar: boolean
  @Consume showJieQi: boolean | undefined
  @Consume showJieRi: boolean | undefined
  @Consume viewModel: CJViewModel
  @Consume @Watch("isFoldChanged") isFold: boolean
  /** 自定义构建每一项的样式 */
  buildCellStyle: (cjDataItem: CJDateItem) => CJCellStyle = () => {
    return new CJCellStyle()
  }
  onCellClickIntercept?: (item: CJDateItem) => boolean | undefined
  cellClick: (cjDataItem: CJDateItem) => void = () => {
  }
  /**
   * 选择改变监听，
   */
  onSelectedChanged: (items: Array<CJDateItem>) => void = () => {

  }
  /**
   * 月份切换
   */
  onMonthChanged: (month: Date) => void = () => {
  }
  /**
   * 重新构建Item
   */
  reBuildCellItem?: (cjDateItem: CJDateItem) => void
  /**
   * 获取农历描述信息
   */
  buildCellLunarDesc?: (cjDateItem: CJDateItem) => string
  // ========自定义布局==========
  /** 构建单元格背景 */
  @BuilderParam buildCellBackground: CustomBuilder = this.BuildCellBackground
  /** 构建不可选中Cell背景，当实现buildCellBackground时，该方法无效 */
  @BuilderParam buildDisableCellBackground: CustomBuilder = this.BuildDisableCellBackground
  /** 构建单元格主体内容 */
  @BuilderParam buildCellBody: CustomBuilder = this.BuildCellBody
  /** 构建自定义标记 */
  @BuilderParam buildMark: CustomBuilder = this.BuildMark

  aboutToAppear(): void {
    CJLogUtil.debug(TAG, "月份初始化：aboutToAppear")
    this.cjMonthController.bind(this)
    this.onReady?.(this.cjMonthController)

    if (this.cjMonthController.getMonth()) {
      this.__calcMonthDays(new Date(this.cjMonthController.getMonth()!!.time))
    } else if (this.month) {
      this.__calcMonthDays(new Date(this.month.time))
    }
  }

  freshView = (item: CJDateItem) => {
    CJLogUtil.debug(TAG, "收到刷新：", JSON.stringify(item))
    if (this.month?.fullYear == item.fullYear && this.month.month == item.month) {
      // this.refresh()
    }
  }

  aboutToDisappear(): void {
    this.cjMonthController.unbind()
  }

  @Builder
  BuildCellBackground() {
  }

  @Builder
  BuildDisableCellBackground() {
  }

  @Builder
  BuildCellBody() {
  }

  @Builder
  BuildMark() {
  }

  build() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.days, (item: CJDateItem) => {
        CJDay({
          cjDataItem: item,
          today: this.today,
          cjCellStyle: this.buildCellStyle(item),
          buildDisableCellBackground: this.buildDisableCellBackground,
          buildCellBackground: this.buildCellBackground,
          buildCellBody: this.buildCellBody,
          buildMark: this.buildMark,
          onCellClickIntercept: (cellItem: CJDateItem) => {
            return this.onCellClickIntercept?.(cellItem)
          },
          cellClick: (cjDataItem: CJDateItem) => {
            CJLogUtil.debug(TAG, `cellClick foldRowIndex ${cjDataItem.foldRowIndex}`)
            this.cellClick(cjDataItem)
          }
        })
          .height(this.itemCellHeight)
          .width("14.28%")
      }, (item: CJDateItem) => JSON.stringify(item))
    }
    .translate({
      y: this.isFold ? -this.getFoldRowIndex() * this.itemCellHeight : 0
    })
    .animation({
      duration: this.animDuration,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal,
      onFinish: () => {
        this.animDuration = 0
      }
    })
    .width('100%')
  }

  // refresh(time: number) {
  //   this.__calcMonthDays(new Date(time))
  // }

  isFoldChanged() {
    this.animDuration = 500
  }

  /**
   * 计算指定月份的所有日期
   */
  __calcMonthDays(month: Date) {
    // TODO 测试 记得删除
    // this.today.reset(new Date("2024-12-30"))

    month.setDate(1)
    if (this.days.length > 0) {
      this.days.splice(0, this.days.length)
    }
    // 计算第一个月
    // 获取第一个月总天数
    let endDay: Date = new Date(
      month.getFullYear(),
      month.getMonth() + 1,
      0, 23, 59, 59)

    CJLogUtil.debug(TAG, "endDay：" + endDay.getFullYear() + "-" + (endDay.getMonth() + 1) + "-" + endDay.getDate())
    // TimeConversionTool.formatDateTime()

    let tempDate: Date = new Date(month)

    CJLogUtil.debug("tempDate：", tempDate.getFullYear() + "-" + (tempDate.getMonth() + 1) + "-" + tempDate.getDate())
    CJLogUtil.debug("tempDate 星期：", tempDate.getDay())

    const count = endDay.getDate()
    const preCount = month.getDay() - this.weekStartMode.valueOf() >= 0 ? month.getDay() - this.weekStartMode.valueOf() : 7 + month.getDay() - this.weekStartMode.valueOf()
    const nextCount = 6 - endDay.getDay() + this.weekStartMode.valueOf()
    const finilCount = count + preCount + nextCount


    // 补齐上一个月
    tempDate.setDate(tempDate.getDate() - preCount)
    CJLogUtil.debug("补齐上一个月 tempDate：",
      tempDate.getFullYear() + "-" + (tempDate.getMonth() + 1) + "-" + tempDate.getDate())

    // 添加日期
    const weekCount = finilCount / 7
    // this.rows.splice(0, this.rows.length)
    for (let weekIndex = 0; weekIndex < weekCount; weekIndex++) {
      for (let index = weekIndex * 7; index < (weekIndex + 1) * 7; index++) {
        let item = new CJDateItem(
          tempDate,
          (index < preCount ? true : false) || this.startDate.getTime() > tempDate.getTime(),
          (index >= preCount + count ? true : false) || this.endDate.getTime() < tempDate.getTime()
        )
        item.foldRowIndex = weekIndex
        item.isSmallThanStart = index < preCount
        item.isBigThanEnd = index >= preCount + count
        // CJLogUtil.debug("date:", item.date, ",isSmallThanStart:", item.isSmallThanStart, ",isBigThanEnd:", item.isBigThanEnd)
        item.isToday = tempDate.getFullYear() == this.today.fullYear && tempDate.getMonth() == this.today.month &&
          tempDate.getDate() == this.today.date
        if (this.reBuildCellItem) {
          // item = this.reBuildCellItem(item)
          this.reBuildCellItem?.(item)
        }
        if (this.showLunar) { // 显示农历
          item.solar = Solar.fromYmd(item.fullYear, item.month + 1, item.date)
          if (this.buildCellLunarDesc) {
            item.desc = this.buildCellLunarDesc(item)
          } else {
            item.desc = this._getLunarDesc(item, this.showJieQi, this.showJieRi)
          }
        }
        // this.reBuildDateItem(item)
        // week.push(item)
        this.days.push(item)
        tempDate.setDate(tempDate.getDate() + 1)
      }
      this.weekCount++
      // this.rows.push(weekIndex)
    }
  }

  refresh(date?: Date) {
    let temp: Date
    if (date) {
      this.month = new CJDateItem(date)
      temp = date
    } else {
      temp = new Date(this.month!!.fullYear, this.month!!.month, this.month!!.date)
    }
    this.__calcMonthDays(temp)
    // for (let date of this.days) {
    //   this.reBuildCellItem?.(date)
    // }
  }

  getFoldRowIndex(): number {
    for (let item of this.days) {
      if (this.tempSelectedItem.equalDay(item)) {
        return item.foldRowIndex
      }
    }
    return 0
  }

  _getLunarDesc(cjDataItem: CJDateItem, showJieQi: boolean | undefined, showJieRi: boolean | undefined): string {
    try {
      if (cjDataItem.solar) {
        if (showJieRi && cjDataItem.solar.getLunar().getFestivals().length > 0) {
          return cjDataItem.solar.getLunar().getFestivals().join()
        }
        if (showJieQi && cjDataItem.solar.getLunar().getJieQi()) {
          return cjDataItem.solar.getLunar().getJieQi()
        }
        return cjDataItem.solar.getLunar().getDayInChinese()
      }
    } catch (e) {

    }
    return ""
  }
}

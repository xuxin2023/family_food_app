/**
 * 日历控制器
 */
import { CJCalendarV2 } from './CJCalendarV2'
import { CJCalStatusParams } from './CJCalStatusParams'
import { CJDateItem } from './CJDateItem'
import { CJViewModel } from './CJViewModel'
import { OptMode } from './OptMode'

const TAG = "CJCalendarControlV2"

export class CJCalendarControlV2 {
  public static readonly FRESH_CJCALENDAR_VIEW: string = "fresh_cjcalendar_view"
  private cjCalendar: CJCalendarV2 | undefined

  bind(cjCalendar: CJCalendarV2) {
    this.cjCalendar = cjCalendar
  }

  unbind() {
    this.cjCalendar = undefined
  }

  /**
   * 上一个月
   */
  preMonth() {
    this.cjCalendar?.__prePage()
  }

  /**
   * 下一个月
   */
  nextMonth() {
    this.cjCalendar?.__nextPage()
  }

  /**
   * 回到今天
   */
  backToday() {
    this.cjCalendar?.__backToday()
  }

  /**
   * 跳转至指定的年月份
   * @param month “2016-08” / new Date(“2016-08”)
   */
  skipToDate(month: Date | string) {
    this.cjCalendar?.__skipToDate(month)
  }

  /**
   * 触发选中指定日期项
   * @param items ["2024-06-07"] 、 [new Date()]
   */
  selectItems(items: Array<string | Date> | undefined) {
    this.cjCalendar?.__changeSelectItems(items)
  }

  /**
   * 显示隐藏农历
   */
  showLunar(show: boolean) {
    this.cjCalendar?.changeShowLunar(show)
  }

  /**
   * 动态出发点击
   * @param item
   */
  clickItem(year: number, month?: number, date?: number) {
    // getContext().eventHub.emit(CJConstants.CJCALENDER_CJDAY_CLICK, year, month, date)
  }

  /**
   * 改变视图
   * @param model
   */
  changViewModel(model: CJViewModel) {
    this.cjCalendar?.changViewModel(model)
  }

  /**
   * 动态切换操作模式
   */
  changOptModel(optModel: OptMode) {
    this.cjCalendar?.changOptModel(optModel)
  }

  /**
   * 刷新日历
   * @param isAll：是否刷新所有月，默认刷新当前月
   */
  refresh(isAll: boolean = false) {
    this.cjCalendar?.refresh(isAll)
  }

  /**
   * 设置折叠状态
   * @param fold
   */
  setFoldStatue(fold: boolean) {
    this.cjCalendar?.setFoldStatue(fold)
  }

  /**
   * 获取当前月days, 月模式
   * @returns
   */
  getCurrMonthDays(): CJDateItem[] | undefined {
    return this.cjCalendar?.getPageItems()
  }

  /**
   * 获取上一月days
   * @returns
   */
  getPreMonthDays(): CJDateItem[] | undefined {
    return this.cjCalendar?.getPageItems(-1)
  }

  /**
   * 获取下一月days
   * @returns
   */
  getNextMonthDays(): CJDateItem[] | undefined {
    return this.cjCalendar?.getPageItems(1)
  }


  /**
   * 获取日历状态信息
   * @returns
   */
  getCJCalenderStatusParams(): CJCalStatusParams {
    return this.cjCalendar?.cjCalStatus!!
  }

  /**
   * 是否禁用滑动
   * 禁用组件滑动切换功能。设置为true禁用，false不禁用。默认值：false
   * @param enable
   */
  setDisableSwipe(enable: boolean) {
    this.cjCalendar?.setDisableSwipe(enable)
  }

}
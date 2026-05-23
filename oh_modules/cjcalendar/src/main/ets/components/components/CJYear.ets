import { CommonUtil } from '../../utils/CommonUtil'
import { ItemDataSource } from '../data/ItemDataSource'
import { CellStatus } from './CellStatus'
import { CJCalStyle } from './CJCalStyle'
import { CJCellStyle } from './CJCellStyle'
import { CJMonth } from './CJMonth'
import { CJDateItem } from './CJDateItem'
import { OptMode } from './OptMode'

const TAG = "TAG"

@Component
export struct CJYear {
  @State months: Array<CJDateItem> = new Array()
  //================
  today: CJDateItem = new CJDateItem(new Date())
  // 当前显示月份
  currYear: Date = new Date()
  startDate: Date = new Date("1970-01-01")
  endDate: Date = new Date(this.currYear.getFullYear() + 10, 0, 1)
  /** 星期标题字体大小 */
  weekTitleFontSize: number | string | Resource = 13
  /** 星期标题字体颜色 */
  weekTitleFontColor: ResourceColor = "#9E9E9E"
  weekTitleBackgroundColor: ResourceColor = "#00000000"
  // 星期标栏高度
  weekTitleHeight: Length = 40
  weeks: string[] = [
    "日",
    "一",
    "二",
    "三",
    "四",
    "五",
    "六",
  ]
  // =====theme======
  // 每一行高度
  @Consume itemCellHeight: number
  /** 操作模式 */
  @Consume optMode: OptMode
  cjCellStatus: CellStatus = new CellStatus()
  cjCellStyle: CJCellStyle = new CJCellStyle()
  // 不能使用的日期字体颜色
  disabledFontColor: ResourceColor = "#9E9E9E"
  @State title: string = ""
  // 标题栏高度
  titleHeight: Length = 50
  titleBackgroundColor: ResourceColor | undefined = undefined
  titleBackgroundImage: PixelMap | ResourceStr | DrawableDescriptor | undefined = undefined
  // 标题年月格式化,默认：yyyy-MM
  titleFormat: string = "yyyy-MM"
  // 标题字体大小
  titleFontSize: number | string | Resource = 18
  // 标题字体颜色
  titleFontColor: ResourceColor = "#252a34"
  // 是否显示快捷 今
  showFastToday: boolean = true
  fastTodayFontSize: number | string | Resource = 12
  fastTodayFontColor: ResourceColor = "#FFFFFF"
  fastTodayBackgroundColor: ResourceColor = "#03A9F4"
  // 设置后每一行会均分monthHeight高度
  monthHeight: number | undefined = undefined
  // 是否仅显示当月日期
  @Consume onlyShowCurrMonthDay: boolean
  // 是否显示农历
  @Consume showLunar: boolean
  @Consume showJieQi: boolean | undefined
  @Consume showJieRi: boolean | undefined
  /** 自定义构建每一项的样式 */
  buildCellStyle: (cjDataItem: CJDateItem) => CJCellStyle = (cjDataItem: CJDateItem) => {
    return new CJCellStyle()
  }
  /**
   * 选择改变监听，
   */
  onSelectedChanged: (items: Array<CJDateItem>) => void = () => {

  }
  /**
   * 点击日期事件响应
   */
  onCellItemClick: (item: CJDateItem) => void = () => {
  }
  /**
   * 不能点击项的点击日期事件响应
   */
  onDisableCellItemClick: (item: CJDateItem) => void = () => {
  }
  cellClick: (cjDataItem: CJDateItem) => void = () => {
  }
  /**
   * 重新构建Item
   */
  reBuildCellItem: (cjDateItem: CJDateItem) => CJDateItem = (cjDateItem: CJDateItem) => {
    return cjDateItem
  }
  // ========自定义布局==========
  /** 构建单元格背景 */
  @BuilderParam buildCellBackground: CustomBuilder = this.BuildCellBackground
  /** 构建不可选中Cell背景 */
  @BuilderParam buildDisableCellBackground: CustomBuilder = this.BuildDisableCellBackground
  /** 构建单元格主体内容 */
  @BuilderParam buildCellBody: CustomBuilder = this.BuildCellBody
  /** 构建自定义标记 */
  @BuilderParam buildMark: CustomBuilder = this.BuildMark

  aboutToAppear() {
    this.__initAttrs()
    // this.buildCellBackground.bind(this)
    // 初始化其他参数

    // 初始化日期项
    this.__initMonths()
  }

  /**
   * 初始化属性
   */
  __initAttrs() {
    // 初始化农历相关属性
    if (this.showLunar) {
      if (this.showJieQi == undefined) {
        this.showJieQi = true
      }
      if (this.showJieRi == undefined) {
        this.showJieRi = true
      }
    }
  }

  aboutToDisappear() {
  }

  build() {
    Column() {
      this.WeekLayout()
      // 日期
      this.BodyLayout()
    }
    .width('100%')

  }

  @Builder
  BuildDisableCellBackground() {
  }

  @Builder
  BuildCellBackground() {
  }

  @Builder
  BuildCellBody() {
  }

  @Builder
  BuildMark() {
  }

  @Builder
  WeekLayout() {
    Row() {
      ForEach(this.weeks, (item: string, index) => {
        this.WeekCell(item)
      })
    }
    .backgroundColor(this.weekTitleBackgroundColor)
    .alignItems(VerticalAlign.Center)
    .height(this.weekTitleHeight)

  }

  @Builder
  WeekCell(week: string) {
    Text(week)
      .textAlign(TextAlign.Center)
      .fontColor(this.weekTitleFontColor)
      .fontSize(this.weekTitleFontSize)
      .layoutWeight(1)
  }

  @Builder
  BodyLayout() {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(this.months, (item: CJDateItem) => {
        Column() {
          CJMonth({
            // cjDataItem: item,
            // monthHeight: this.monthHeight,
            startDate: this.startDate,
            endDate: this.endDate,
            month: item,
            today: this.today,
            buildDisableCellBackground: this.buildDisableCellBackground,
            cjCellStyle: this.cjCellStyle,
            buildCellBackground: this.buildCellBackground,
            buildMark: this.buildMark,
            buildCellBody: this.buildCellBody,
            buildCellStyle: this.buildCellStyle,
            reBuildCellItem: this.reBuildCellItem,
            cellClick: (cjDataItem: CJDateItem) => {
              this.cellClick(cjDataItem)
            }
          })
        }
        .width('33.33%')
      })
    }
  }

  /**
   * 初始化日期项
   */
  __initMonths() {
    this.__calcMonths(new Date(this.currYear))
  }

  /**
   * 计算指定月份的所有日期
   */
  __calcMonths(year: Date) {
    year.setMonth(0, 1)

    for (let index = 0; index < 12; index++) {
      if (this.currYear.getFullYear() == year.getFullYear() &&
        this.currYear.getMonth() == year.getMonth()) {
        this.title = year.getFullYear() + "-" + (year.getMonth() + 1).toString().padStart(2, "0")
      }
      console.log(TAG, JSON.stringify(year))
      this.months.push(new CJDateItem(year))
      year.setMonth(year.getMonth() + 1, 1)
    }
  }

  /**
   * 修改农历显示状态
   * @param show
   */
  changeShowLunar(show: boolean) {
    this.showLunar = show
  }
}
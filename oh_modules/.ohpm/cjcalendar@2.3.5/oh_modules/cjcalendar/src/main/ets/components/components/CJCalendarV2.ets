/**
 * 操作模式
 */
import { CJDateItem } from './CJDateItem'
import { ColorUtil } from '../../utils/ColorUtil'
import { Solar } from 'lunar'
import { CJCellStyle } from './CJCellStyle'
import { OptMode } from './OptMode'
import { SelectedStyle } from './SelectedStyle'
import { SelectedShape } from './SelectedShape'
import { CJCalStyle } from './CJCalStyle'
import { CellStatus } from './CellStatus'
import { CJCalStatusParams } from './CJCalStatusParams'
import { CJMonth } from './CJMonth'
import { ItemDataSource } from '../data/ItemDataSource'
import { CJCalendarControlV2 } from './CJCalendarControlV2'
import { CommonUtil } from '../../utils/CommonUtil'
import TimeConversionTool from '../../utils/TimeConversionTool'
import { CJViewModel } from './CJViewModel'
import { CJMonthController } from './CJMonthController'
import { CJWeek } from './CJWeek'
import { CJLogUtil } from '../../utils/CJLogUtil'
import { CJDateShowBackMode } from '../data/CJDateShowBackMode'
import { JSON } from '@kit.ArkTS'
import { WeekStartMode } from '../data/WeekStartMode'

const TAG = "CJCalendarV2"

@Component
export struct CJCalendarV2 {
  controller: CJCalendarControlV2 = new CJCalendarControlV2()
  cacheCount: number = 3
  logSwitch: boolean = false
  private swipers: Array<number> = []
  private cjMonthControllers: Array<CJMonthController> = []
  private swiperController: SwiperController = new SwiperController()
  @State private currentIndex: number = 0
  @Provide @Watch("__onStatusChange") cjCalStatus: CJCalStatusParams = new CJCalStatusParams()
  // 单选、多选不校验，时间段才必须是两个
  @Provide @Watch("__onSelectedChanged") selectedItems: Array<CJDateItem> = new Array()
  // 临时选中项，用于切换时的标记，月模式 标记 日期，周模式 标记 星期
  @Provide tempSelectedItem: CJDateItem = new CJDateItem(new Date())
  @State months: Array<CJDateItem> = new Array()
  @Provide extras: Record<string, number | string | boolean> | undefined = undefined
  @Provide weekStartMode: WeekStartMode = WeekStartMode.Sunday
  @State disableSwipe: boolean = false
  // 初始化默认选中日期：["2024-06-07"]
  defSelectedItems: Array<string | Date> | undefined = undefined
  /** 默认选中形状 */
  @Provide selectedShape: SelectedShape = SelectedShape.SHAPE_RECT
  // 视图模式，默认月视图
  @Provide @Watch("__onViewModelChange") viewModel: CJViewModel = CJViewModel.MONTH
  //================
  today: CJDateItem = new CJDateItem(new Date())
  // 当前显示月份、周、年==份
  currYMW: Date = new Date()
  // 初始化显示所在月/星期/年
  initShowDate: Date | undefined = undefined
  /** 操作模式 */
  @Provide optMode: OptMode = OptMode.NORMAL
  startDate: Date = new Date("1970-01-01")
  endDate: Date = new Date(new Date().getFullYear() + 10, 0, 1)
  endLastDay: Date = new Date(this.endDate.getFullYear(), this.endDate.getMonth() + 1, 0, 23, 59, 59)
  startFirstDay: Date = new Date(this.startDate.getFullYear(), this.startDate.getMonth(), 1, 0, 0, 0)
  @Provide selectedStyle: SelectedStyle = SelectedStyle.ALONE
  /** 样式 */
  calStyle: CJCalStyle = new CJCalStyle()
  cjDataItem?: CJDateItem
  weeks: string[] = []
  /** 星期标题字体大小 */
  weekTitleFontSize: number | string | Resource = 13
  /** 星期标题字体颜色 */
  weekTitleFontColor: ResourceColor = "#9E9E9E"
  weekTitleBackgroundColor: ResourceColor = "#00000000"
  // 星期标栏高度
  weekTitleHeight: Length = 40
  /** 是否显示星期标题 */
  showWeekTitle: boolean = true
  // =====theme======
  /** 主题色 */
  @Provide themeColor: string = "#03A9F4"
  /** 全局圆角设置，优先级低于单元格内部圆角 */
  @Provide selectedBorderRadius: number = 4
  /** 是否需要标记出今日，仅在Nomal模式下支持 */
  @Provide isNeedMarkToday: boolean = false
  itemFontColor: ResourceColor = "#252a34"
  // 每一行高度
  @Provide itemCellHeight: number = 55
  cjCellStatus: CellStatus = new CellStatus()
  cjCellStyle: CJCellStyle = new CJCellStyle()
  // 不能使用的日期字体颜色
  disabledFontColor: ResourceColor = "#9E9E9E"
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
  // 是否显示Toolbar
  showToolbar: boolean = true
  // 是否显示快捷 今
  showFastToday: boolean = true
  fastTodayFontSize: number | string | Resource = 12
  fastTodayFontColor: ResourceColor = "#FFFFFF"
  fastTodayBackgroundColor?: ResourceColor // = "#03A9F4"
  // 仅需要日期显示区域，不需要底部自定义区域
  onlyShowDateArea: boolean = false
  // 回显方式，仅支持Normal操作模式，当本月选中某日期，切换下一月时回显同样日期，当选中当月最后一天或者第一天时，会出现两种情况
  // 1、当前选中当月最后一天如：31，则下月同样显示31，如下月不够，则显示当月最后一天
  // 2、当前选中当月最后一天，切换月日期不足显示第一天，
  // 3、月份切换时，目标月回显当月1号，
  // 默认第一种
  dateShowBackMode: CJDateShowBackMode = CJDateShowBackMode.SHOW_LAST
  // 是否将底部用户布局添加到整体，默认是每个月
  @State isAttchCustomLayoutToWhole: boolean = false
  // 是否显示折叠按钮
  @State isShowFoldView: boolean = true
  // 设置后每一行会均分monthHeight高度
  monthHeight: number | undefined = undefined
  private isFirst: boolean = true
  // 是否折叠
  @Provide isFold: boolean = false
  @State foldRowIndex: number = 0
  // 是否仅显示当月日期
  @Provide onlyShowCurrMonthDay: boolean = false
  // 是否显示农历
  @Provide showLunar: boolean = false
  @Provide showJieQi: boolean | undefined = undefined
  @Provide showJieRi: boolean | undefined = undefined
  //
  @Provide markAlignment: Alignment = Alignment.TopEnd
  // 从点击或者制定日期导致切换
  _month_change_from_click: boolean = false
  /** 状态改变回调 */
  onStatusChange: (cjCalStatus: CJCalStatusParams) => void = () => {
    console.debug("状态变化：", JSON.stringify(this.cjCalStatus))
  }
  /**
   * 获取农历描述信息
   */
  buildCellLunarDesc?: (cjDateItem: CJDateItem) => string
  /** 自定义构建每一项的样式 */
  buildCellStyle: (cjDataItem: CJDateItem) => CJCellStyle = (cjDataItem: CJDateItem) => {
    return new CJCellStyle()
  }
  /**
   * 选择改变监听，选择操作模式下才会触发
   */
  onSelectedChanged: (items: Array<CJDateItem>) => void = () => {

  }
  /**
   * 点击前置拦截
   * @returns true 表示 拦截， false：不拦截
   */
  onCellClickIntercept?: (item: CJDateItem) => boolean | undefined
  /**
   * 点击日期事件响应
   * @returns true: 拦截点击
   */
  onCellItemClick?: (item: CJDateItem) => boolean
  /**
   * 不能点击项的点击日期事件响应
   * @returns true: 拦截点击
   */
  onDisableCellItemClick?: (item: CJDateItem) => boolean
  /**
   * 月份切换之前
   */
  onMonthChangeBefore?: (curr: CJDateItem, target: CJDateItem) => void
  /**
   * 变化之后
   */
  onAnimationEnd?: (item: CJDateItem) => void
  /**
   * 月份切换
   */
  onMonthChanged?: (month: CJDateItem) => void
  /**
   * 重新构建Item
   */
  reBuildCellItem?: (cjDateItem: CJDateItem) => void
  // ========自定义布局==========
  /** 构建整体标题栏 */
  @BuilderParam toolbarLayout: CustomBuilder = this.ToolbarLayout
  /** 仅构建标题栏背景 */
  @BuilderParam buildToolbarLayoutBackground: CustomBuilder = this.ToolbarLayoutBackground
  /** 构建单元格背景 */
  @BuilderParam buildCellBackground: CustomBuilder = this.BuildCellBackground
  /** 构建不可选中Cell背景 */
  @BuilderParam buildDisableCellBackground: CustomBuilder = this.BuildDisableCellBackground
  /** 构建单元格主体内容 */
  @BuilderParam buildCellBody: CustomBuilder = this.BuildCellBody
  /** 构建自定义标记 */
  @BuilderParam buildMark: CustomBuilder = this.BuildMark
  /** 用户内容区 */
  @BuilderParam buildMonthCustomLayout: CustomBuilder
  /** 自定义折叠 */
  @BuilderParam buildFoldCustomLayout: CustomBuilder
  /** 自定义星期cell */
  @BuilderParam buildWeekTitleCell: (week: string) => void
  // ============滑动处理===============
  @State offsetY: number = 0
  @State positionY: number = 0
  isAniming: boolean = false
  startY: number = 0
  startX: number = 0
  // 初始化完成
  onInitFinish?: () => void

  aboutToAppear() {
    this.__initAttrs()
    // this.buildCellBackground.bind(this)
    // 初始化其他参数
    // this.fastTodayBackgroundColor = this.themeColor
    this.cjCalStatus.showFastToday = this.showFastToday

    // 初始化日期项
    this.__initDays()

    // 初始化完成回调
    if (this.onInitFinish) {
      this.onInitFinish()
    }
  }

  /**
   * 初始化星期标题栏参数
   */
  __initWeekParams() {
    if (this.weeks.length == 0 || !this.weeks) {
      if (this.weekStartMode == WeekStartMode.Sunday) {
        this.weeks = ["日", "一", "二", "三", "四", "五", "六"]
      } else if (this.weekStartMode == WeekStartMode.Saturday) {
        this.weeks = ["六", "日", "一", "二", "三", "四", "五"]
      } else if (this.weekStartMode == WeekStartMode.Friday) {
        this.weeks = ["五", "六", "日", "一", "二", "三", "四"]
      } else if (this.weekStartMode == WeekStartMode.Thursday) {
        this.weeks = ["四", "五", "六", "日", "一", "二", "三"]
      } else if (this.weekStartMode == WeekStartMode.Wednesday) {
        this.weeks = ["三", "四", "五", "六", "日", "一", "二"]
      } else if (this.weekStartMode == WeekStartMode.Tuesday) {
        this.weeks = ["二", "三", "四", "五", "六", "日", "一"]
      } else {
        this.weeks = ["一", "二", "三", "四", "五", "六", "日"]
      }
    }
  }

  /**
   * 初始化属性
   */
  __initAttrs() {

    CJLogUtil.IS_DEBUG = this.logSwitch

    this.__initWeekParams()

    if (!this.fastTodayBackgroundColor) {
      this.fastTodayBackgroundColor = this.themeColor
    }

    if (this.optMode != OptMode.NORMAL) {
      this.isNeedMarkToday = false
    }

    // 初始化swiper item
    this.__calcSwiperCount()

    // 初始化农历相关属性
    if (this.showLunar) {
      if (this.showJieQi == undefined) {
        this.showJieQi = true
      }
      if (this.showJieRi == undefined) {
        this.showJieRi = true
      }
    }

    // 初始化defSelectedItems
    this.__changeSelectItems(this.defSelectedItems, false)

    // 操作模式初始化
    if (this.optMode == OptMode.NORMAL || this.optMode == OptMode.SINGLE) {
      if (this.optMode == OptMode.SINGLE) {
        if (this.selectedItems.length == 0) {
          this.selectedItems.push(new CJDateItem(new Date()))
        }
      } else {
        if (this.selectedItems && this.selectedItems.length > 0) {
          this.selectedItems.splice(0, this.selectedItems.length)
        }
        this.selectedItems.push(new CJDateItem(new Date()))
      }
    }

    if (this.endDate) {
      this.endLastDay = new Date(this.endDate.getFullYear(), this.endDate.getMonth() + 1, 0, 23, 59, 59)
    }
    if (this.startDate) {
      this.startDate.setHours(0, 0, 0)
      this.startFirstDay = new Date(this.startDate.getFullYear(), this.startDate.getMonth(), 1, 0, 0, 0)
    }

    if (this.initShowDate) {
      if (this.initShowDate.getTime() > this.endDate.getTime()) {
        this.initShowDate = new Date(this.endDate)
      }
      if (this.initShowDate.getTime() < this.startDate.getTime()) {
        this.initShowDate = new Date(this.startDate)
      }
      this.tempSelectedItem.reset(this.initShowDate)
    } else {
      if (this.selectedItems.length > 0) {
        this.tempSelectedItem.reset(this.selectedItems[this.selectedItems.length - 1])
      }
    }

    // 初始化ctroller
    if (!this.controller) {
      this.controller = new CJCalendarControlV2()
    }
    this.controller.bind(this)

    if (this.viewModel == CJViewModel.WEEK) {
      this.isFold = true
      this.currYMW.setDate(this.tempSelectedItem.date - this.tempSelectedItem.week)
    } else if (this.viewModel == CJViewModel.MONTH) {
      // this.cjMonthController = new CJMonthController()
    } else if (this.viewModel == CJViewModel.YEAR) {

    }
  }

  /**
   * 计算页数
   */
  __calcSwiperCount() {
    if (this.viewModel == CJViewModel.MONTH) {
      let temp = TimeConversionTool.monthsBetween(this.startDate, this.endDate)
      if (temp < this.cacheCount) {
        this.cacheCount = temp
      }
    }
    for (let i = 0; i < this.cacheCount; i++) {
      this.swipers.push(i)
      this.cjMonthControllers.push(new CJMonthController())
    }
  }

  aboutToDisappear() {
    this.controller.unbind()
  }

  build() {
    Column() {
      // this.testTitle()
      // 顶部导航
      if (this.showToolbar && this.toolbarLayout) {
        this.toolbarLayout()
      }
      // 星期
      if (this.showWeekTitle && this.viewModel != CJViewModel.YEAR) {
        this.WeekTitleLayout()
      }
      // 日期
      this.BodyLayout()

      // 整体底部区域
      if (!this.onlyShowDateArea) {
        if (this.viewModel != CJViewModel.YEAR && this.buildMonthCustomLayout && this.isAttchCustomLayoutToWhole) {
          Column() {
            this.buildMonthCustomLayout()
          }
          .width("100%")
          .layoutWeight(1)
        }
      }
    }
    .width("100%")
    .height(this.onlyShowDateArea ? undefined : "100%")
    .onTouch((event?: TouchEvent) => {
      if (!this.onlyShowDateArea) {
        //TODO 处理滑动逻辑
        if (event) {
          if (event.type === TouchType.Down) {

          } else if (event.type === TouchType.Move) {

          } else if (event.type === TouchType.Up) {

          } else if (event.type === TouchType.Cancel) {

          }
        }
      }
    })

  }

  @Builder
  BuildDisableCellBackground() {

  }

  @Builder
  BuildCellBackground() {
    if (this.cjDataItem?.disabled) {
      if (this.buildDisableCellBackground) {
        this.buildDisableCellBackground()
      }
    } else {
      // if (this.cjDataItem?.fullYear == 2025 && this.cjDataItem.month == 0 && this.cjDataItem.date == 3 && this.cjDataItem.isNext){
      //   Column()
      //     .backgroundColor("#55aacc")
      //     .width(100)
      //     .height(100)
      // }
      if (this.optMode == OptMode.NORMAL ||
        this.optMode == OptMode.MULTIPLE ||
        this.optMode == OptMode.SINGLE) {

        if (this.selectedShape == SelectedShape.LINE_CIRCLE) { // 线型-圆
          Column()
            .backgroundColor(this.cjCellStatus.backgroundColor)
            .width('90%')
            .aspectRatio(1)
            .border(this.cjCellStatus?.borderColor ? {
              width: this.cjCellStatus.borderWidth,
              color: this.cjCellStatus.borderColor,
              radius: 200
            } : undefined)
        } else if (this.selectedShape == SelectedShape.LINE_RECT) { // 线型 - 矩形
          Column()
            .backgroundColor(this.cjCellStatus.backgroundColor)
            .width('90%')
            .aspectRatio(1)
            .border(this.cjCellStatus?.borderColor ? {
              width: this.cjCellStatus.borderWidth,
              color: this.cjCellStatus.borderColor
            } : undefined)
            .borderRadius(this.cjCellStyle.borderRadius)
        } else if (this.selectedShape == SelectedShape.SHAPE_CIRCLE) { // 圆形
          Column()
            .backgroundColor(this.cjCellStatus.backgroundColor)
            .width('90%')
            .aspectRatio(1)
            .border(this.cjCellStatus.borderColor ? {
              width: this.cjCellStatus.borderWidth,
              color: this.cjCellStatus.borderColor,
            } : undefined)
            .borderRadius(200)
        } else if (this.selectedShape == SelectedShape.SHAPE_RECT) { // 矩形
          Column()
            .backgroundColor(this.cjCellStatus.backgroundColor)
            .width('90%')
            .aspectRatio(1)
            .border(this.cjCellStatus.borderColor ? {
              width: this.cjCellStatus.borderWidth,
              color: this.cjCellStatus.borderColor
            } : undefined)
            .borderRadius(this.cjCellStyle.borderRadius)
        }
      } else if (this.optMode == OptMode.RANGE) {
        if (this.selectedStyle == SelectedStyle.ALONE) { // 独立
          if (this.selectedShape == SelectedShape.LINE_CIRCLE) { // 线型-圆
            Column()
              .backgroundColor(this.cjCellStatus.backgroundColor)
              .width('90%')
              .aspectRatio(1)
              .border(this.cjCellStatus?.borderColor ? {
                width: this.cjCellStatus.borderWidth,
                color: this.cjCellStatus.borderColor,
                radius: 200
              } : undefined)
          } else if (this.selectedShape == SelectedShape.LINE_RECT) { // 线型 - 矩形
            Column()
              .backgroundColor(this.cjCellStatus.backgroundColor)
              .width('90%')
              .aspectRatio(1)
              .border(this.cjCellStatus?.borderColor ? {
                width: this.cjCellStatus.borderWidth,
                color: this.cjCellStatus.borderColor
              } : undefined)
              .borderRadius(this.cjCellStyle.borderRadius)
          } else if (this.selectedShape == SelectedShape.SHAPE_CIRCLE) {
            Column()
              .backgroundColor(this.cjCellStatus.backgroundColor)
              .width('90%')
              .aspectRatio(1)
              .border(this.cjCellStatus.borderColor ? {
                width: this.cjCellStatus.borderWidth,
                color: this.cjCellStyle.borderColor,
              } : undefined)
              .borderRadius(200)
          } else if (this.selectedShape == SelectedShape.SHAPE_RECT) {
            Column()
              .backgroundColor(this.cjCellStatus.backgroundColor)
              .width('90%')
              .aspectRatio(1)
              .border(this.cjCellStatus.borderColor ? {
                width: this.cjCellStatus.borderWidth,
                color: this.cjCellStatus.borderColor
              } : undefined)
              .borderRadius(this.cjCellStyle.borderRadius)
          }
        } else {
          Column()
            .backgroundColor(this.cjCellStatus.backgroundColor)
            .width('100%')
            .height("90%")// .aspectRatio(1)
            .border(this.cjCellStatus.borderColor ? {
              width: this.cjCellStatus.borderWidth,
              color: this.cjCellStatus.borderColor
            } : undefined)
            .borderRadius({
              topLeft: this.cjCellStatus.isStart ? this.cjCellStyle.borderRadius : 0,
              topRight: this.cjCellStatus.isEnd ? this.cjCellStyle.borderRadius : 0,
              bottomLeft: this.cjCellStatus.isStart ? this.cjCellStyle.borderRadius : 0,
              bottomRight: this.cjCellStatus.isEnd ? this.cjCellStyle.borderRadius : 0
            })
          // .borderRadius(this.cjCellStyle.boderRadius)
        }
      }
    }

    // Text(this.selectedStyle + "")
  }

  @Builder
  BuildCellBody() {
    Column() {
      if (this.selectedShape == SelectedShape.LINE_CIRCLE || this.selectedShape == SelectedShape.LINE_RECT) { // 线型
        Text(this.cjDataItem?.dateText ? this.cjDataItem.dateText : this.cjDataItem?.date + '')
          .fontColor(this.cjCellStatus.fontColor)
          .fontSize(this.cjCellStatus.fontSize)
          .fontWeight(this.cjCellStyle.fontFontWeight)
        if (this.showLunar && this.cjDataItem?.desc) {
          Text(this.cjDataItem.desc)
            .fontSize(this.cjCellStyle.descFontSize)
            .fontColor(this.cjCellStatus.descFontColor)
            .fontWeight(this.cjCellStyle.descFontFontWeight)
            .margin({
              top: this.cjCellStyle.descMargin
            })
        }
      } else {
        Text(this.cjDataItem?.dateText ? this.cjDataItem.dateText : this.cjDataItem?.date + '')
          .fontColor(this.cjCellStatus.fontColor)
          .fontSize(this.cjCellStatus.fontSize)
          .fontWeight(this.cjCellStyle.fontFontWeight)
        if (this.showLunar && this.cjDataItem?.desc) {
          Text(this.cjDataItem.desc)
            .fontSize(this.cjCellStyle.descFontSize)
            .fontColor(this.cjCellStatus.descFontColor)
            .fontWeight(this.cjCellStyle.descFontFontWeight)
            .margin({
              top: this.cjCellStyle.descMargin
            })
        }
      }

    }
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  BuildMark() {
    Stack() {
      if (this.cjDataItem?.markImageUrl || this.cjDataItem?.markIcon) {
        Image(this.cjDataItem?.markImageUrl)
          .alt(this.cjDataItem?.markIcon)
          .objectFit(ImageFit.Contain)
          .width(this.cjCellStyle.markImageWidth)
          .height(this.cjCellStyle.markImageWidth)
      } else {
        Text(this.cjDataItem?.markText)
          .fontSize(this.cjCellStyle.markFontSize)
          .fontColor(this.cjCellStatus.markFontColor)
          .fontWeight(this.cjCellStyle.fontFontWeight)
          .backgroundColor(this.cjCellStyle.markBackgroundColor)
          .borderRadius(this.cjCellStyle.markRadius)
          .padding(this.cjCellStyle.markPadding)
      }
    }
  }

  @Builder
  ToolbarLayoutBackground() {
    if (this.titleBackgroundImage) {
      Image(this.titleBackgroundImage)
        .width("100%")
        .height("100%")
        .objectFit(ImageFit.Fill)
    }
    if (this.titleBackgroundColor) {
      Row()
        .width("100%")
        .height("100%")
        .backgroundColor(this.titleBackgroundColor)
    }

  }

  @Builder
  ToolbarLayout() {
    Stack() {
      if (this.buildToolbarLayoutBackground) {
        this.buildToolbarLayoutBackground()
      }
      Row() {
        Image($r("app.media.ic_public_arrow_left"))
          .width(28)
          .fillColor(this.cjCalStatus.hasPre ? this.itemFontColor : this.disabledFontColor)
          .aspectRatio(1)
          .onClick(() => {
            // this.cjCalStatus.title = "2024-04"
            this.controller.preMonth()
          })

        Blank()

        Row() {
          Text(this.cjCalStatus.title)
            .fontSize(this.titleFontSize)
            .fontColor(this.titleFontColor)

          if (this.showFastToday && this.cjCalStatus.showFastToday) {
            Text("今")
              .fontSize(this.fastTodayFontSize)
              .fontColor(this.fastTodayFontColor)
              .backgroundColor(this.fastTodayBackgroundColor)
              .borderRadius(50)
              .padding(4)
              .margin({ left: 4 })
              .onClick(() => {
                this.controller.backToday()
              })
          }
        }

        Blank()

        Image($r("app.media.ic_public_arrow_right_filled"))
          .width(28)
          .fillColor(this.cjCalStatus.hasNext ? this.itemFontColor : this.disabledFontColor)
          .aspectRatio(1)
          .onClick(() => {
            // this.cjCalStatus.title = "2024-06"
            this.controller.nextMonth()
          })
      }
      .width('100%')
      .height("100%")
      .backgroundColor("#00000000")
      .alignItems(VerticalAlign.Center)
    }
    .width("100%")
    .height(this.titleHeight)
  }

  @Builder
  WeekTitleLayout() {
    Row() {
      ForEach(this.weeks, (item: string, index: number) => {
        this.WeekTitleCell(item)
      }, (item: string) => JSON.stringify(item))
    }
    .backgroundColor(this.weekTitleBackgroundColor)
    .alignItems(VerticalAlign.Center)
    .height(this.weekTitleHeight)

  }

  @Builder
  WeekTitleCell(week: string) {
    if (this.buildWeekTitleCell) {
      this.buildWeekTitleCell(week)
    } else {
      Text(week)
        .textAlign(TextAlign.Center)
        .fontColor(this.weekTitleFontColor)
        .fontSize(this.weekTitleFontSize)
        .layoutWeight(1)
    }
  }

  @Builder
  YearLayout() {
    // CJYear({})
  }

  @Builder
  MonthLayout() {
    ForEach(this.cjMonthControllers, (item: CJMonthController, index: number) => {
      Column() {
        Column() {
          CJMonth({
            // cjDataItem: item,
            cjMonthController: item,
            startDate: this.startDate,
            endDate: this.endDate,
            month: this.__getInitDate(index),
            today: this.today,
            // optMode: this.optMode,
            buildDisableCellBackground: this.buildDisableCellBackground,
            // cjCalStatus: this.cjCalStatus,
            // themeColor: this.themeColor,
            cjCellStyle: this.cjCellStyle,
            // selectedStyle: this.selectedStyle,
            // selectedShape: this.selectedShape,
            // buildCellBackground: (item: CJDateItem, cjCellStyle: CJCellStyle, cjCellStatus: CellStatus) => {
            //   this.buildCellBackground(item, cjCellStyle, cjCellStatus)
            // },
            buildCellBackground: this.buildCellBackground,
            buildCellBody: this.buildCellBody,
            buildMark: this.buildMark,
            buildCellStyle: this.buildCellStyle,
            reBuildCellItem: this.reBuildCellItem,
            buildCellLunarDesc: this.buildCellLunarDesc,
            onCellClickIntercept: (cellItem: CJDateItem) => {
              return this.onCellClickIntercept?.(cellItem)
            },
            cellClick: (cellItem: CJDateItem) => {
              CJLogUtil.debug(TAG, "cellClick" + cellItem.toString())
              if (!this.__cellItemClick(cellItem)) {
                if (cellItem.isPre) {
                  if (this.controller) {
                    this._month_change_from_click = true
                    this.controller.preMonth()
                  }
                } else if (cellItem.isNext) {
                  if (this.controller) {
                    this._month_change_from_click = true
                    this.controller.nextMonth()
                  }
                }
              }
            },
          })
        }
        .height(this.isFold ? this.itemCellHeight : undefined)
        .animation({
          duration: 500,
          curve: Curve.EaseOut,
          iterations: 1,
          playMode: PlayMode.Normal,
          onFinish: () => {
            this.__foldAnimFinish()
          }
        })
        .clip(true)
        .width('100%')

        if (!this.onlyShowDateArea) {
          if (this.isShowFoldView) {
            Row() {
              Image(this.isFold ? $r('app.media.icon_fold') : $r('app.media.icon_minus'))
                .height(20)
                .width(40)
                .padding(4)
            }
            // .backgroundColor(Color.Brown)
            .justifyContent(FlexAlign.Center)
            .width("100%")
            .onClick(() => {
              this.isFold = !this.isFold
            })
          }

          // 用户内容区
          if (this.buildMonthCustomLayout && !this.isAttchCustomLayoutToWhole) {
            Column() {
              this.buildMonthCustomLayout()
            }
            .width("100%")
            .layoutWeight(1)
          }
        }

      }
      .width("100%")
      .height(this.onlyShowDateArea || this.buildMonthCustomLayout && this.isAttchCustomLayoutToWhole ? undefined :
        "100%")
    }, (item: CJMonthController, index: number) => JSON.stringify(item.getMonth()) + index)
  }

  getKey(item: CJDateItem) {
    return item.fullYear + "-" + item.month
  }

  @Builder
  WeekLayout(item: CJDateItem) {
    CJWeek({
      startItem: item,
      startDate: this.startDate,
      endDate: this.endDate,
      today: this.today,
      buildCellStyle: this.buildCellStyle,
      buildDisableCellBackground: this.buildDisableCellBackground,
      buildCellBackground: this.buildCellBackground,
      buildCellBody: this.buildCellBody,
      reBuildCellItem: this.reBuildCellItem,
      cellClick: (cjDataItem: CJDateItem) => {
        this.__cellItemClick(cjDataItem)
      }
    })
  }

  @Builder
  BodyLayout() {
    Column() {
      Swiper(this.swiperController) {
        if (this.viewModel == CJViewModel.MONTH || this.viewModel == CJViewModel.WEEK) {
          // 月、周
          this.MonthLayout()
        } else if (this.viewModel == CJViewModel.YEAR) {
          if (!this.onlyShowDateArea) {
            // 年
            this.YearLayout()
          }
        }
      }
      .index(this.currentIndex)
      .indicator(false)
      .autoPlay(false)
      .loop(true)
      .cachedCount(1)
      .disableSwipe(this.disableSwipe)
      .onAnimationStart((index, targetIndex) => {
        CJLogUtil.debug(TAG, "onAnimationStart index：" + index + "，targetIndex：" + targetIndex)
        this.onMonthChangeBefore?.(this.cjMonthControllers[index].getMonth()!!,
          this.cjMonthControllers[targetIndex].getMonth()!!)
        this.__onAnimationStart(index, targetIndex)
      })
      .onAnimationEnd((index: number) => {
        CJLogUtil.debug(TAG, "onAnimationEnd index：" + index)
        this.__onSwiperIndexChanged()
        this.__refreshPageData()
      })
      .onChange((index: number) => {
        this.currentIndex = index
        CJLogUtil.debug(TAG, "index:" + index + ",currentIndex:" + this.currentIndex)
      })
      .height(this.onlyShowDateArea || this.buildMonthCustomLayout && this.isAttchCustomLayoutToWhole ? undefined :
        "100%")
      .width("100%")
    }
    .clip(true)
    .width('100%')
    .layoutWeight(this.onlyShowDateArea || this.buildMonthCustomLayout && this.isAttchCustomLayoutToWhole ? undefined :
      1)
  }

  __onStatusChange() {
    this.onStatusChange(this.cjCalStatus)
  }

  __onAnimationStart(index: number, targetIndex: number) {
    if (index != targetIndex) {
      if (index == 0 && targetIndex == this.cacheCount - 1) {
        // 上一页
        this.__onAnimationStartPreImpl(targetIndex)
      } else if (index == this.cacheCount - 1 && targetIndex == 0) {
        // 下一页
        this.__onAnimationStartNextImpl(targetIndex)
      } else if (targetIndex > index) {
        // 下一页
        this.__onAnimationStartNextImpl(targetIndex)
      } else {
        // 上一页
        this.__onAnimationStartPreImpl(targetIndex)
      }
    }

    this.__resetTempSelectedItem(index, targetIndex)
    this.__checkToolStatus()
  }

  /**
   * 上一页
   * @param targetIndex
   */
  __onAnimationStartPreImpl(targetIndex: number) {
    if (this.viewModel == CJViewModel.MONTH) {
      let preDate: Date = new Date(this.currYMW)
      preDate.setDate(0)

      this.currYMW.setMonth(this.currYMW.getMonth() - 1,
        this.currYMW.getDate() <= preDate.getDate() ? this.currYMW.getDate() : preDate.getDate())
    } else if (this.viewModel == CJViewModel.WEEK) {
      this.currYMW = new Date(
        this.tempSelectedItem.fullYear,
        this.tempSelectedItem.month,
        this.tempSelectedItem.date - 7 - this.tempSelectedItem.week
      )
    }
  }

  /**
   * 下一页
   * @param targetIndex
   */
  __onAnimationStartNextImpl(targetIndex: number) {
    if (this.viewModel == CJViewModel.MONTH) {
      let nextDate: Date = new Date(this.currYMW)
      nextDate.setMonth(nextDate.getMonth() + 2, 0)

      this.currYMW.setMonth(this.currYMW.getMonth() + 1,
        this.currYMW.getDate() <= nextDate.getDate() ? this.currYMW.getDate() : nextDate.getDate())
    } else if (this.viewModel == CJViewModel.WEEK) {
      this.currYMW = new Date(
        this.tempSelectedItem.fullYear,
        this.tempSelectedItem.month,
        this.tempSelectedItem.date + 7 - this.tempSelectedItem.week
      )
    }
  }

  /**
   * 调整临时选中项目
   */
  __resetTempSelectedItem(index: number, targetIndex: number) {
    let isNext: boolean = this.isNextPage(index, targetIndex)
    let date: number
    if (this.selectedItems.length > 0) {
      date = this.selectedItems[this.selectedItems.length - 1].date
    } else {
      date = new Date().getDate()
    }
    let temp: Date = new Date(this.tempSelectedItem.fullYear, this.tempSelectedItem.month, this.tempSelectedItem.date)

    let t: CJDateItem = this.cjMonthControllers[targetIndex].getMonth()!!
    CJLogUtil.debug("月份切换：", `date: ${date}，t：${t.toString()}`)
    if (this.viewModel == CJViewModel.MONTH) {
      this.currYMW.setFullYear(t.fullYear, t.month, 1)
      // 末尾选中
      let show_click: boolean = (this.dateShowBackMode & CJDateShowBackMode.SHOW_CLICK) == CJDateShowBackMode.SHOW_CLICK
      let mode = show_click ? this.dateShowBackMode - CJDateShowBackMode.SHOW_CLICK : this.dateShowBackMode
      let last: Date = new Date(t.fullYear, t.month + 1, 0)
      if (mode == CJDateShowBackMode.SHOW_FIRST) {
        if (show_click && this._month_change_from_click) {
          this._month_change_from_click = false
        } else {
          if (this.today.fullYear == t.fullYear && this.today.month == t.month) {
            // 当月
            this.tempSelectedItem.reset(new Date())
            // this._resetSelectedItems()
          } else {
            this.tempSelectedItem.reset(this.currYMW)
          }
        }
        // this._resetSelectedItems()
      } else if (mode == CJDateShowBackMode.SHOW_PRE_LAST_NEXT_FIRST) {
        if (show_click && this._month_change_from_click) {
          this._month_change_from_click = false
        } else {
          if (this.today.fullYear == t.fullYear && this.today.month == t.month) {
            // 当月
            this.tempSelectedItem.reset(new Date())
            // this._resetSelectedItems()
          } else {
            // 非当月
            if (isNext) { // 下一月
              this.tempSelectedItem.reset(new Date(t.fullYear, t.month, 1))
              // this._resetSelectedItems()
            } else { // 上一月
              this.tempSelectedItem.reset(last)
              // this._resetSelectedItems()
            }
          }
        }
      } else {
        if (date <= last.getDate()) {
          this.tempSelectedItem.reset(new Date(t.fullYear, t.month, date))
        } else {
          if (mode == CJDateShowBackMode.SHOW_LAST) {
            this.tempSelectedItem.reset(new Date(t.fullYear, t.month, last.getDate()))
          } else if (mode == CJDateShowBackMode.SHOW_LAST_TO_FIRST) {
            if ((this.dateShowBackMode & CJDateShowBackMode.SHOW_CLICK) == CJDateShowBackMode.SHOW_CLICK &&
            this._month_change_from_click) {
              // 点击或者指定日期跳转
              this._month_change_from_click = false
            } else {
              this.tempSelectedItem.reset(this.currYMW)
            }
          }
        }
      }

      CJLogUtil.debug("月份切换：", `tempSelectedItem: ${this.tempSelectedItem.toString()}}`)
    } else if (this.viewModel == CJViewModel.WEEK) {
      // 判断是否在同一个星期
      let d = new Date(this.currYMW.getTime())
      d.setDate(d.getDate() + this.tempSelectedItem.week)
      this.tempSelectedItem.reset(d)
    }
    // this.tempSelectedItem.

    this._resetSelectedItems()
  }

  _resetSelectedItems() {
    if (this.optMode == OptMode.NORMAL) {
      // 常规操作模式只会存在当前月标记
      if (this.selectedItems.length > 0 &&
        !this.tempSelectedItem.equalDay(this.selectedItems[this.selectedItems.length - 1])) {
        let t: CJDateItem = new CJDateItem(new Date())
        t.reset(this.tempSelectedItem)
        this.selectedItems[0] = t
      }
    }
  }

  /**
   * 判断是否是下一页
   * @param index
   * @param targetIndex
   */
  isNextPage(index: number, targetIndex: number): boolean {
    if (index == this.cacheCount - 1 && targetIndex == 0) {
      return true
    } else if (index == 0 && targetIndex == this.cacheCount - 1) {
      return false
    } else if (targetIndex > index) {
      return true
    }
    return false
  }

  // 索引发生变化时
  __onSwiperIndexChanged() {
    // this.onAnimationEnd?.(this.itemDataSource.getData(index))
    let cjItem: CJDateItem = new CJDateItem(this.currYMW) // this.itemDataSource.getData(index)
    this.onMonthChanged?.(this.tempSelectedItem)
  }

  /**
   * 视图切换监听
   */
  private __onViewModelChange() {
    CJLogUtil.debug(TAG, "视图模式切换：", this.viewModel)
    if (this.selectedItems.length > 0) {
      let item: CJDateItem = this.selectedItems[this.selectedItems.length - 1]
      if (item.fullYear == this.tempSelectedItem.fullYear &&
        item.month == this.tempSelectedItem.month &&
        item.date != this.tempSelectedItem.date) {
        this.tempSelectedItem.reset(item)
      }
    }
    if (this.viewModel == CJViewModel.WEEK) {
      this.currYMW.setDate(this.tempSelectedItem.date - this.tempSelectedItem.week)
    } else {
      this.currYMW.setDate(1)
    }
    this.__refreshPageData()
  }

  private __cellItemClick(cellItem: CJDateItem): boolean | void {
    let flag: boolean | void = false
    if (cellItem.smallThan(new CJDateItem(this.startDate)) ||
    cellItem.bigThan(new CJDateItem(this.endDate)) || cellItem.disabled) {
      if (this.onDisableCellItemClick) {
        flag = this.onDisableCellItemClick(cellItem)
      } else {
        if (this.onCellItemClick) {
          flag = this.onCellItemClick(cellItem)
        }
      }
    } else {
      if (this.onCellItemClick) {
        flag = this.onCellItemClick(cellItem)
      }
    }

    return flag
    // this.onSelectedChanged(this.selectedItems)
  }

  private __checkToolStatus() {
    this.cjCalStatus.title = TimeConversionTool.formatDateTime(this.currYMW, this.titleFormat)

    const currItem = new CJDateItem(this.currYMW)
    if (this.viewModel == CJViewModel.WEEK) {
      // 判断是否有上一星期
      if (this.startDate.getTime() < new Date(currItem.fullYear, currItem.month, currItem.date).getTime()) {
        this.cjCalStatus.hasPre = true
      } else {
        this.cjCalStatus.hasPre = false
      }
      // 判断是否有下一月
      if (this.endDate.getTime() >= new Date(currItem.fullYear, currItem.month, currItem.date + 7).getTime()) {
        this.cjCalStatus.hasNext = true
      } else {
        this.cjCalStatus.hasNext = false
      }
      // 判断是否显示 今
      if (this.today.time < currItem.time ||
        this.today.time >= new Date(currItem.fullYear, currItem.month, currItem.date + 7).getTime()) {
        this.cjCalStatus.showFastToday = true
      } else {
        this.cjCalStatus.showFastToday = false
      }
    } else if (this.viewModel == CJViewModel.MONTH) {
      // 判断是否有上一月
      if (TimeConversionTool.calcMontsBetween(this.startDate.getFullYear(), this.startDate.getMonth(),
        currItem.fullYear, currItem.month) > 0) {
        this.cjCalStatus.hasPre = true
      } else {
        this.cjCalStatus.hasPre = false
      }
      // 判断是否有下一月
      if (TimeConversionTool.calcMontsBetween(currItem.fullYear, currItem.month, this.endDate.getFullYear(),
        this.endDate.getMonth()) > 0) {
        this.cjCalStatus.hasNext = true
      } else {
        this.cjCalStatus.hasNext = false
      }
      // 判断是否显示 今
      // 本月不显示，本月不在开始与结束时间区域内时，不显示
      if (currItem.fullYear == this.today.fullYear &&
        currItem.month == this.today.month || (this.today.time < this.startDate.getTime()) ||
        this.today.time > this.endDate.getTime()) {
        this.cjCalStatus.showFastToday = false
      } else {
        this.cjCalStatus.showFastToday = true
      }
    } else if (this.viewModel == CJViewModel.YEAR) {

    }
  }

  /**
   * 修改选中项目
   */
  __changeSelectItems(items: Array<string | Date> | undefined, fresh: boolean = true) {
    if (fresh && this.selectedItems.length > 0) {
      this.selectedItems.splice(0, this.selectedItems.length)
    }
    if (items && items.length > 0) {
      if (this.optMode == OptMode.SINGLE) {
        if (typeof items[0] == "string") {
          this.selectedItems.push(new CJDateItem(new Date(items[0])))
        } else {
          this.selectedItems.push(new CJDateItem(items[0]))
        }
      } else if (this.optMode == OptMode.MULTIPLE) {
        items.forEach((item: string | Date) => {
          if (typeof item == "string") {
            this.selectedItems.push(new CJDateItem(new Date(item)))
          } else {
            this.selectedItems.push(new CJDateItem(item))
          }
        })
      } else if (this.optMode == OptMode.RANGE) {
        if (typeof items[0] == "string") {
          this.selectedItems.push(new CJDateItem(new Date(items[0])))
        } else {
          this.selectedItems.push(new CJDateItem(items[0]))
        }
        if (items.length >= 2) {
          if (typeof items[1] == "string") {
            this.selectedItems.push(new CJDateItem(new Date(items[1])))
          } else {
            this.selectedItems.push(new CJDateItem(items[1]))
          }
        }
      }
    }
  }

  __onSelectedChanged() {
    if (this.selectedItems.length > 0 &&
      !this.tempSelectedItem.equalDay(this.selectedItems[this.selectedItems.length - 1])) {
      this.tempSelectedItem.reset(this.selectedItems[this.selectedItems.length - 1])
    }
    if (this.optMode != OptMode.NORMAL) {
      this.onSelectedChanged(this.selectedItems)
    }
  }

  /**
   * 上一月
   */
  __prePage() {
    if (!this.cjCalStatus.hasPre) {
      return
    }
    this.swiperController.showPrevious()
  }

  /**
   * 初始化时，只会有第0页面、最后一页，第一页
   * @param index
   * @returns
   */
  __getInitDate(index: number): CJDateItem {
    if (index == 0) {
      return new CJDateItem(new Date(this.currYMW.getFullYear(), this.currYMW.getMonth(), 1))
    } else if (index == this.cacheCount - 1) {
      let preMonth: Date = new Date(this.currYMW.getFullYear(), this.currYMW.getMonth() - 1, 1, 0, 0, 0)
      if (preMonth.getTime() < this.startFirstDay.getTime()) {
        preMonth = new Date(this.endDate.getFullYear(), this.endDate.getMonth(), 1)
      }
      return new CJDateItem(preMonth)
    } else {
      let nextMonth: Date = new Date(this.currYMW.getFullYear(), this.currYMW.getMonth() + 1, 1)
      if (nextMonth.getTime() > this.endLastDay.getTime()) {
        nextMonth = new Date(this.startDate.getFullYear(), this.startDate.getMonth(), 1)
      }
      return new CJDateItem(nextMonth)
    }
  }

  /**
   * 下一月
   */
  __nextPage() {
    if (!this.cjCalStatus.hasNext) {
      return
    }
    this.swiperController.showNext()
  }

  /**
   * 回到今天
   */
  __backToday() {
    CJLogUtil.debug(TAG, "==============  回到当前年/月/周   ==============")
    this.__skipToDate(new Date())
  }

  /**
   * 跳转至指定的年月份
   * @param month “2016-08” / new Date(“2016-08”)
   */
  __skipToDate(date: Date | string) {
    CJLogUtil.debug(TAG, "==============  跳转指定年/月/周   ==============")
    let temp: Date
    if (typeof date == "string") {
      temp = new Date(date)
    } else {
      temp = date
    }

    this.tempSelectedItem.reset(temp)
    if (this.optMode == OptMode.NORMAL ||
      this.optMode == OptMode.SINGLE) {
      if (this.selectedItems.length > 0) {
        this.selectedItems.splice(0, this.selectedItems.length)
      }
      this.selectedItems.push(new CJDateItem(temp))
    }

    if (this.viewModel == CJViewModel.MONTH) {

      let count: number =
        TimeConversionTool.calcMontsBetween(this.currYMW.getFullYear(), this.currYMW.getMonth(), temp.getFullYear(),
          temp.getMonth())

      // if (count != 0) {
      // this._month_change_from_click = true
      // }

      if (count == 1) {
        this.__nextPage()
        return
      } else if (count == -1) {
        this.__prePage()
        return
      }

      this.currYMW = temp
      this.currYMW.setDate(1)

    } else if (this.viewModel == CJViewModel.WEEK) {
      this.currYMW.setFullYear(temp.getFullYear(), temp.getMonth(), temp.getDate() - temp.getDay())
    }
    this.cjMonthControllers[this.currentIndex].refresh(new Date(this.currYMW))

    this.__checkToolStatus()
    this.__refreshPageData()
  }

  /**
   * 初始化日期项
   */
  __initDays() {
    this.__calcItems(new Date(this.currYMW))
  }

  /**
   * 计算指定月份的所有日期
   */
  __calcItems(date: Date) {
    date.setHours(0, 0, 0, 0)

    if (this.viewModel == CJViewModel.WEEK) { // 周视图
      let temp: Date
      if (this.initShowDate) {
        if (this.initShowDate.getTime() < this.startDate.getTime()) {
          temp = this.startDate
        } else if (this.initShowDate.getTime() > this.endDate.getTime()) {
          temp = this.endDate
        } else {
          temp = this.initShowDate
        }
      } else {
        if (this.currYMW.getTime() < this.startDate.getTime()) {
          temp = this.startDate
        } else if (this.currYMW.getTime() > this.endDate.getTime()) {
          temp = this.endDate
        } else {
          temp = this.currYMW
        }
      }

      // 回到当前星期第一天
      date.setTime(temp.getTime())
      date.setDate(date.getDate() - date.getDay())
      // date.setDate(date.getDate() - 7 * Number.parseInt((this.firstInitCount / 5 * 4).toString()))

    } else if (this.viewModel == CJViewModel.MONTH) { // 月视图
      date.setDate(1)

      let temp: Date
      if (this.initShowDate) {
        if (this.initShowDate.getTime() < this.startDate.getTime()) {
          temp = this.startDate
        } else if (this.initShowDate.getTime() > this.endDate.getTime()) {
          temp = this.endDate
        } else {
          temp = this.initShowDate
        }
      } else {
        if (this.currYMW.getTime() < this.startDate.getTime()) {
          temp = this.startDate
        } else if (this.currYMW.getTime() > this.endDate.getTime()) {
          temp = this.endDate
        } else {
          temp = this.currYMW
        }
      }

      this.currYMW = temp
      if (!this.isFirst) {
        this.tempSelectedItem.reset(temp)
      } else {
        this.isFirst = false
      }

    } else {
      // date.setFullYear(date.getFullYear() - Number.parseInt((this.firstInitCount / 5 * 4).toString()), 0, 1)

      let temp: Date
      if (this.initShowDate) {
        if (this.initShowDate.getTime() < this.startDate.getTime()) {
          temp = this.startDate
        } else if (this.initShowDate.getTime() > this.endDate.getTime()) {
          temp = this.endDate
        } else {
          temp = this.initShowDate
        }
      } else {
        if (this.currYMW.getTime() < this.startDate.getTime()) {
          temp = this.startDate
        } else if (this.currYMW.getTime() > this.endDate.getTime()) {
          temp = this.endDate
        } else {
          temp = this.currYMW
        }
      }

      // 年视图

    }

    this.__refreshPageData()
    // 状态校验
    this.__checkToolStatus()
  }

  /**
   * 修改农历显示状态
   * @param show
   */
  changeShowLunar(show: boolean) {
    this.showLunar = show
  }

  /**
   * 获取当指定页days
   * index: 0, 当前页， 1，下一页(大于0下一页)， -1，上一页（小于0上一页）
   * @param index
   * @returns
   */
  getPageItems(index: number = 0): CJDateItem[] | undefined {
    if (this.viewModel == CJViewModel.WEEK) {

    } else if (this.viewModel == CJViewModel.MONTH) {
      // return this.monthControllerMap.get(this.getKey(this.itemDataSource.getData(this.currentIndex)))?.getItems()
      if (index == 0) {
        return this.cjMonthControllers[this.currentIndex].getItems()
      } else if (index < 0) { //上一页
        if (this.cjMonthControllers.length > 1) {
          if (this.currentIndex == 0) {
            return this.cjMonthControllers[this.cjMonthControllers.length - 1].getItems()
          } else {
            return this.cjMonthControllers[this.currentIndex - 1].getItems()
          }
        } else {
          return undefined
        }
      } else { // 下一页
        if (this.cjMonthControllers.length > 1) {
          if (this.currentIndex == this.cjMonthControllers.length - 1) {
            return this.cjMonthControllers[0].getItems()
          } else {
            return this.cjMonthControllers[this.currentIndex + 1].getItems()
          }
        } else {
          return undefined
        }
      }
    } else if (this.viewModel == CJViewModel.YEAR) {

    }
    return undefined
  }

  changViewModel(model: CJViewModel) {
    if (this.viewModel != model) {
      if (model == CJViewModel.WEEK) {
        this.isFold = true
      } else {
        this.isFold = false
      }
    }
    this.viewModel = model
  }

  /**
   * 切换操作模式
   */
  changOptModel(optModel: OptMode) {
    this.optMode = optModel
    if (this.optMode == OptMode.NORMAL || this.optMode == OptMode.SINGLE) {
      if (this.selectedItems.length > 1) {
        this.selectedItems.splice(0, this.selectedItems.length - 1)
      }
    } else {
      if (this.selectedItems.length > 0) {
        this.selectedItems.splice(0, this.selectedItems.length)
      }
    }

  }

  /**
   * 刷新日历
   * @param isAll：是否刷新所有月，默认刷新当前月
   */
  refresh(isAll: boolean = false) {
    if (isAll) {
      this.cjMonthControllers.forEach(controller => {
        controller.refresh()
      })
    } else {
      this.cjMonthControllers[this.currentIndex].refresh()
    }
  }

  // ======================V3=============================
  __refreshPageData() {
    if (this.cacheCount < 3) {
      return
    }
    if (this.viewModel == CJViewModel.WEEK) {

      let temp: Date = new Date(this.tempSelectedItem.time)

      if (this.currentIndex == 0) {
        this.cjMonthControllers[this.cacheCount - 1]
          .refresh(new Date(temp.getFullYear(), temp.getMonth(), temp.getDate() - 7))
        this.cjMonthControllers[1]
          .refresh(new Date(temp.getFullYear(), temp.getMonth(), temp.getDate() + 7))
      } else if (this.currentIndex == this.cacheCount - 1) {
        this.cjMonthControllers[0]
          .refresh(new Date(temp.getFullYear(), temp.getMonth(), temp.getDate() + 7))
        this.cjMonthControllers[this.cacheCount - 2]
          .refresh(new Date(temp.getFullYear(), temp.getMonth(), temp.getDate() - 7))
      } else {
        this.cjMonthControllers[this.currentIndex - 1]
          .refresh(new Date(temp.getFullYear(), temp.getMonth(), temp.getDate() - 7))
        this.cjMonthControllers[this.currentIndex + 1]
          .refresh(new Date(temp.getFullYear(), temp.getMonth(), temp.getDate() + 7))
      }
    } else if (this.viewModel == CJViewModel.MONTH) {

      let preMonth: Date = new Date(this.currYMW.getFullYear(), this.currYMW.getMonth() - 1, 1)
      let nextMonth: Date = new Date(this.currYMW.getFullYear(), this.currYMW.getMonth() + 1, 1)

      if (preMonth.getTime() < this.startFirstDay.getTime()) {
        preMonth = new Date(this.endDate.getFullYear(), this.endDate.getMonth(), 1)
      }

      if (nextMonth.getTime() > this.endLastDay.getTime()) {
        nextMonth = new Date(this.startDate.getFullYear(), this.startDate.getMonth(), 1)
      }

      if (this.currentIndex == 0) {
        this.cjMonthControllers[this.cacheCount - 1].refresh(preMonth)
        this.cjMonthControllers[1].refresh(nextMonth)
      } else if (this.currentIndex == this.cacheCount - 1) {
        this.cjMonthControllers[0].refresh(nextMonth)
        this.cjMonthControllers[this.cacheCount - 2].refresh(preMonth)
      } else {
        this.cjMonthControllers[this.currentIndex - 1].refresh(preMonth)
        this.cjMonthControllers[this.currentIndex + 1].refresh(nextMonth)
      }

    }
  }

  /**
   * 折叠动画结束
   */
  __foldAnimFinish() {
    if (this.isFold) {
      // 周模式
      this.viewModel = CJViewModel.WEEK
    } else {
      // 月模式
      this.viewModel = CJViewModel.MONTH
    }
  }

  /**
   * 是否禁用滑动
   * 禁用组件滑动切换功能。设置为true禁用，false不禁用。默认值：false
   * @param enable
   */
  setDisableSwipe(enable: boolean) {
    this.disableSwipe = enable
  }

  /**
   * 折叠
   */
  setFoldStatue(fold: boolean) {
    this.foldRowIndex = this.cjMonthControllers[this.currentIndex].getFoldRowIndex()
    console.log(TAG, "setFoldStatue foldRowIndex：", this.foldRowIndex)
    this.isFold = fold
  }
}
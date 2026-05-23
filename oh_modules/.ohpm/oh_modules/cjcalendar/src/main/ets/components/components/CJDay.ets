import { ColorUtil } from '../../utils/ColorUtil'
import { CJDateItem } from './CJDateItem'
import { CJCellStyle } from './CJCellStyle'
import { CellStatus } from './CellStatus'
import { SelectedStyle } from './SelectedStyle'
import { CJCalStatusParams } from './CJCalStatusParams'
import { SelectedShape } from './SelectedShape'
import { OptMode } from './OptMode'
import { CommonUtil } from '../../utils/CommonUtil'
import { CJConstants } from './CJConstants'
import { CJLogUtil } from '../../utils/CJLogUtil'

@Component
export struct CJDay {
  @State cjCellStatus: CellStatus = new CellStatus()
  @ObjectLink cjDataItem: CJDateItem
  @Prop today: CJDateItem
  @Consume @Watch("__onSelectChange") selectedItems: Array<CJDateItem>
  @Consume cjCalStatus: CJCalStatusParams
  @Consume extras: Record<string, number | string | boolean> | undefined
  @Consume selectedStyle: SelectedStyle
  /** 默认选中形状 */
  @Consume selectedShape: SelectedShape
  @Consume optMode: OptMode
  @Consume itemCellHeight: number
  cjCellStyle: CJCellStyle = new CJCellStyle()
  @Consume onlyShowCurrMonthDay: boolean
  @Consume showLunar: boolean
  @Consume showJieQi: boolean
  @Consume showJieRi: boolean
  @Consume markAlignment: Alignment
  @Consume themeColor: string
  @Consume selectedBorderRadius: number
  @Consume isNeedMarkToday: boolean
  @Consume @Watch("__onTempSelectedChangeed") tempSelectedItem: CJDateItem
  // 点击
  cellClick: (cjDataItem: CJDateItem) => void = () => {
  }
  onCellClickIntercept?: (item: CJDateItem) => boolean | undefined
  // ========自定义布局=======
  @BuilderParam buildCellBackground: CustomBuilder = this.BuildCellBackground
  /** 构建不可选中Cell背景 */
  @BuilderParam buildDisableCellBackground: CustomBuilder = this.BuildDisableCellBackground
  @BuilderParam buildCellBody: CustomBuilder = this.BuildCellBody
  /** 构建自定义标记 */
  @BuilderParam buildMark: CustomBuilder = this.BuildMark

  aboutToAppear(): void {
    // if (this.cjDataItem.equalDay(this.today)) {
    //   this.cjCellStatus.fontColor = this.themeColor
    // } else {
    //   this.cjCellStatus.fontColor = this.cjCellStyle.fontColor
    // }
    // getContext().eventHub.on(CJConstants.CJCALENDER_CJDAY_CLICK, this.eventFunc)
    this._initStyle()
    this.__onSelectChange()
  }

  _onThemeColorChange() {
    this._initStyle()
  }

  _initStyle() {
    if (this.themeColor) {
      if (!this.cjCellStyle.selectItemBackgroundColor) {
        this.cjCellStyle.selectItemBackgroundColor = this.themeColor
      }
      if (!this.cjCellStyle.markFontColor) {
        this.cjCellStyle.markFontColor = this.themeColor
      }
    }
    if (this.selectedBorderRadius) {
      if (!this.cjCellStyle.borderRadius) {
        this.cjCellStyle.borderRadius = this.selectedBorderRadius
      }
    }
  }

  eventFunc(year: number, month: number, date: number) {
    console.log(`eventFunc is called, ${year}, ${month},${date}`);
  }

  aboutToDisappear(): void {
    // getContext().eventHub.off(CJConstants.CJCALENDER_CJDAY_CLICK)
  }

  build() {
    if (this.onlyShowCurrMonthDay && (this.cjDataItem.isSmallThanStart || this.cjDataItem.isBigThanEnd)) {
      Stack()
    } else {
      Stack() {
        // 背景
        this.CellBackground()

        // 主题内容
        this.CellMain()

        // 标记
        this.CellMark()
      }
      .height("100%")
      .height("100%")
      .onClick(() => {
        if (this.onCellClickIntercept?.(this.cjDataItem)) {
          return
        }
        if (!this.cjDataItem.disabled) {
          if ((!this.cjDataItem.isPre && !this.cjDataItem.isNext) ||
            (this.cjDataItem.isPre && this.cjCalStatus.hasPre) ||
            (this.cjDataItem.isNext && this.cjCalStatus.hasNext)) {

            if (this.optMode == OptMode.NORMAL) { // 正常

              this.selectedItems[0] = this.cjDataItem
              // this.cjDataItem.date = 66
            } else if (this.optMode == OptMode.SINGLE) { // 单选

              this.selectedItems[0] = this.cjDataItem

            } else if (this.optMode == OptMode.MULTIPLE) { //多选

              const index = this.containsItem(this.cjDataItem)
              if (index >= 0) {
                this.selectedItems.splice(index, 1)
              } else {
                this.selectedItems.push(this.cjDataItem)
              }

            } else if (this.optMode == OptMode.RANGE) { //范围

              if (this.selectedItems.length == 0) { //一个没选
                this.selectedItems.push(this.cjDataItem)
              } else if (this.selectedItems.length == 1) { // 选了一个
                if (this.cjDataItem.bigThan(this.selectedItems[0])) {
                  this.selectedItems.push(this.cjDataItem)
                } else {
                  this.selectedItems.splice(0, 0, this.cjDataItem)
                }

              } else if (this.selectedItems.length == 2) { // 选了两个
                this.selectedItems.splice(0, 2)
                this.selectedItems.push(this.cjDataItem)
              }

            }

          }
        }

        // 回调点击
        this.cellClick(this.cjDataItem)
      })
    }
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

  @Builder
  CellBackground() {
    Stack() {
      if (this.buildCellBackground) {
        this.buildCellBackground()
      }
    }
    .width('100%')
    .height('100%')
    .clip(true)
  }

  @Builder
  CellMain() {
    if (this.buildCellBody) {
      this.buildCellBody()
    }
  }

  @Builder
  CellMark() {
    if ((this.cjDataItem.markText || this.cjDataItem.markIcon || this.cjDataItem.markImageUrl) && this.buildMark) {
      Stack() {
        this.buildMark()
      }
      .padding(this.cjCellStyle.markMarin)
      .alignContent(this.cjCellStyle.markAlignment ?? this.markAlignment)
      .width('100%')
      .height('100%')
      .clip(true)
    }
  }

  /**
   * 选中要改变
   */
  __onSelectChange() {
    this._styleSetting()
  }

  /**
   * 样式改造
   */
  _styleSetting() {
    // 先处理状态、再调整样式
    // 常规显示
    if (this.optMode == OptMode.NORMAL) {
      if (this.cjDataItem.equalDay(this.selectedItems[0])) {
        this.cjDataItem.isSelected = true
      } else {
        this.cjDataItem.isSelected = false
      }
      this._changeStyleImpl(this._getStyleNum())
    } else if (this.optMode == OptMode.SINGLE) {
      // 单选
      if (this.cjDataItem.equalDay(this.selectedItems[0])) {
        this.cjDataItem.isSelected = true
      } else {
        this.cjDataItem.isSelected = false
      }
      this._changeStyleImpl(this._getStyleNum())
    } else if (this.optMode == OptMode.MULTIPLE) {
      // 多选
      if (this.containsItem(this.cjDataItem) >= 0) {
        this.cjDataItem.isSelected = true
      } else {
        this.cjDataItem.isSelected = false
      }
      this._changeStyleImpl(this._getStyleNum())
    } else if (this.optMode == OptMode.RANGE) {

      let isStart = this.cjDataItem.equalDay(this.selectedItems[0])
      let isEnd = this.cjDataItem.equalDay(this.selectedItems[1])
      if (isStart && !this.selectedItems[1]) {
        isEnd = true
      }

      this.cjCellStatus.isStart = isStart
      this.cjCellStatus.isEnd = isEnd

      // 范围选择
      if (isStart || isEnd) { // 两端状态
        this.cjDataItem.isSelected = true
        this._changeStyleImpl(2)
      } else if (this.selectedItems.length == 2 &&
        (this.cjDataItem.bigThan(this.selectedItems[0]) && this.cjDataItem.smallThan(this.selectedItems[1]))) {
        //中间状态
        this.cjDataItem.isSelected = true
        this._changeStyleImpl(3)
      } else {
        this.cjDataItem.isSelected = false
        this._changeStyleImpl(this._getStyleNum())
      }

    }
  }

  _getStyleNum() {
    let disabled = this.cjDataItem.isPre || this.cjDataItem.isNext || this.cjDataItem.disabled
    if (disabled) {
      if (this.cjDataItem.isSelected) {
        return 5
      } else {
        return 4
      }
    } else {
      if (this.cjDataItem.isSelected) {
        return 2
      } else {
        return 1
      }
    }
  }

  /**
   * 处理单元格样式
   * @param style
   * 1、常规状态
   * 2、常规选中状态
   * 3、常规半选状态
   * 4、一般不可用状态，结合常规模式下的是否需要回显
   * 5、不可用选中状态
   * 都需要区别每种状态下的 “今天”
   * 需要结合状态是否需要回显 “今天”
   * 内置样式考虑：线型、面型、
   * 操作状态考虑：常规、单选、多选、范围选择
   */
  _changeStyleImpl(style: number) {
    let isLineStye = this.selectedShape == SelectedShape.LINE_CIRCLE || this.selectedShape == SelectedShape.LINE_RECT
    // if (this.cjDataItem.fullYear == 2025 && this.cjDataItem.month == 0 && this.cjDataItem.date == 3 && this.cjDataItem.isNext){
    //   CJLogUtil.debug("xxx", "====")
    // }
    // 1、日期字体色
    // 2、描述字颜色
    // 3、标注颜色
    // 4、背景景色
    // 5、边框色
    // 常规状态
    if (style == 1) {

      if (this.cjDataItem.isToday) {

        if (isLineStye) {
          // 常规-今日-线型
          // 1、日期颜色
          this.cjCellStatus.fontColor = this.cjCellStyle.todayFontColor ?? this.themeColor
          this.cjCellStatus.fontSize = this.cjCellStyle.fontSize
          // 2、描述颜色
          this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStatus.fontColor
          // 3、标注颜色
          this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor
          // 4、背景颜色
          this.cjCellStatus.backgroundColor = this.cjCellStyle.itemBackgroundColor
          // 5、边框颜色
          this.cjCellStatus.borderColor = this.cjCellStyle.borderColor
        } else {
          // 常规-今日-面型

          if (this.isNeedMarkToday) {
            // 1、日期颜色
            this.cjCellStatus.fontColor = this.cjCellStyle.todayFontColor ?? "#FFFFFF"
            this.cjCellStatus.fontSize = this.cjCellStyle.todayFontSize ?? this.cjCellStyle.fontSize
            // 2、描述颜色
            this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStatus.fontColor
            // 3、标注颜色
            this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor ?? this.cjCellStatus.fontColor
            // 4、背景颜色
            this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor ?? ColorUtil.lightenColor(this.cjCellStyle.todayBackgroundColor ?? this.themeColor, this.cjCellStyle.lightRatio)
          } else {
            // 1、日期颜色
            this.cjCellStatus.fontColor = this.cjCellStyle.todayFontColor ?? this.themeColor
            this.cjCellStatus.fontSize = this.cjCellStyle.todayFontSize ?? this.cjCellStyle.fontSize
            // 2、描述颜色
            this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStatus.fontColor
            // 3、标注颜色
            this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor
            // 4、背景颜色
            this.cjCellStatus.backgroundColor = this.cjCellStyle.todayBackgroundColor ?? this.cjCellStyle.itemBackgroundColor
          }
          // 5、边框颜色
          this.cjCellStatus.borderColor = this.cjCellStyle.borderColor

        }
      } else {
        if (isLineStye) {
          // 常规-非今日-线型

          // 1、日期颜色
          this.cjCellStatus.fontColor = this.cjCellStyle.fontColor
          this.cjCellStatus.fontSize = this.cjCellStyle.fontSize
          // 2、描述颜色
          this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStyle.disabledFontColor
          // 3、标注颜色
          this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor
          // 4、背景颜色
          this.cjCellStatus.backgroundColor = this.cjCellStyle.itemBackgroundColor
          // 5、边框颜色
          this.cjCellStatus.borderColor = this.cjCellStyle.borderColor

        } else {
          // 常规-非今日-面型

          // 1、日期颜色
          this.cjCellStatus.fontColor = this.cjCellStyle.fontColor
          this.cjCellStatus.fontSize = this.cjCellStyle.fontSize
          // 2、描述颜色
          this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStyle.disabledFontColor
          // 3、标注颜色
          this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor
          // 4、背景颜色
          this.cjCellStatus.backgroundColor = this.cjCellStyle.itemBackgroundColor
          // 5、边框颜色
          this.cjCellStatus.borderColor = this.cjCellStyle.borderColor

        }
      }

    } else if (style == 2) {
      // 常规选中状态
      if (isLineStye) {
        // 常规选中 - 线型
        // 1、日期颜色
        this.cjCellStatus.fontColor = this.cjCellStyle.selectFontColor ?? this.themeColor
        this.cjCellStatus.fontSize = this.cjCellStyle.selectFontSize ?? this.cjCellStyle.fontSize
        // 2、描述颜色
        this.cjCellStatus.descFontColor = this.cjCellStyle.descSelectFontColor ?? (this.cjCellStyle.descFontColor ?? this.cjCellStatus.fontColor)
        // 3、标注颜色
        this.cjCellStatus.markFontColor = this.cjCellStyle.markSelectedFontColor ?? (this.cjCellStyle.markFontColor ?? this.cjCellStatus.fontColor)
        // 4、背景颜色
        this.cjCellStatus.backgroundColor = this.cjCellStyle.itemBackgroundColor
        // 5、边框颜色
        this.cjCellStatus.borderColor = this.cjCellStyle.selectBoderColor ?? this.themeColor

      } else {
        // 常规选中 - 面型

        // 1、日期颜色
        this.cjCellStatus.fontColor = this.cjCellStyle.selectFontColor ?? "#FFFFFF"
        this.cjCellStatus.fontSize = this.cjCellStyle.selectFontSize ?? this.cjCellStyle.fontSize
        // 2、描述颜色
        this.cjCellStatus.descFontColor = this.cjCellStyle.descSelectFontColor ?? this.cjCellStatus.fontColor
        // 3、标注颜色
        this.cjCellStatus.markFontColor = this.cjCellStyle.markSelectedFontColor ?? this.cjCellStatus.fontColor
        // 4、背景颜色
        this.cjCellStatus.backgroundColor = this.cjCellStyle.selectItemBackgroundColor ?? this.themeColor
        // 5、边框颜色
        this.cjCellStatus.borderColor = this.cjCellStyle.selectBoderColor

      }
    } else if (style == 3) {
      // 常规半选状态 - 只有范围选择区间内才存在

      if (isLineStye) {
        // 常规半选状态 - 线型
        // 1、日期颜色
        this.cjCellStatus.fontColor = ColorUtil.lightenColor(this.cjCellStyle.selectFontColor ?? this.themeColor, this.cjCellStyle.lightRatio)
        this.cjCellStatus.fontSize = this.cjCellStyle.fontSize
        // 2、描述颜色
        this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStatus.fontColor
        // 3、标注颜色
        this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor
        // 4、背景颜色
        this.cjCellStatus.backgroundColor = this.cjCellStyle.itemBackgroundColor
        // 5、边框颜色
        this.cjCellStatus.borderColor = ColorUtil.lightenColor(this.cjCellStyle.selectBoderColor ?? this.themeColor, this.cjCellStyle.lightRatio)
      } else {
        // 常规半选状态 - 面型
        // 1、日期颜色
        this.cjCellStatus.fontColor = this.cjCellStyle.todayDisabledFontColor ?? "#FFFFFF"
        this.cjCellStatus.fontSize = this.cjCellStyle.fontSize
        // 2、描述颜色
        this.cjCellStatus.descFontColor = this.cjCellStyle.descDisabledFontColor ?? this.cjCellStatus.fontColor
        // 3、标注颜色
        this.cjCellStatus.markFontColor = this.cjCellStyle.disabledFontColor ?? this.cjCellStatus.fontColor
        // 4、背景颜色
        this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor ?? ColorUtil.lightenColor(this.cjCellStyle.todayBackgroundColor ?? this.themeColor, this.cjCellStyle.lightRatio)
        // 5、边框颜色
        this.cjCellStatus.borderColor = ColorUtil.lightenColor(this.cjCellStyle.selectBoderColor, this.cjCellStyle.lightRatio)

      }

    } else if (style == 4) {
      // 一般不可用状态
      if (this.cjDataItem.isToday) {
        if (isLineStye) {
          if (this.isNeedMarkToday) {
            // 一般不可用 - 今日 - 线型 - 需要回显
            // 1、日期颜色
            this.cjCellStatus.fontColor = this.cjCellStyle.todayDisabledFontColor ??
            ColorUtil.lightenColor(this.cjCellStyle.todayFontColor ?? this.themeColor, this.cjCellStyle.lightRatio)
            this.cjCellStatus.fontSize = this.cjCellStyle.todayFontSize ?? this.cjCellStyle.fontSize
            // 2、描述颜色
            this.cjCellStatus.descFontColor = this.cjCellStyle.descDisabledFontColor ?? this.cjCellStatus.fontColor
            // 3、标注颜色
            this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor ?? this.cjCellStyle.disabledFontColor
            // 4、背景颜色
            this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor
            // 5、边框颜色
            this.cjCellStatus.borderColor = ColorUtil.lightenColor(this.cjCellStyle.borderColor ?? this.themeColor, this.cjCellStyle.lightRatio)
          } else {
            // 一般不可用 - 今日 - 线型 - 不需要回显
            // 1、日期颜色
            this.cjCellStatus.fontColor = this.cjCellStyle.todayDisabledFontColor ?? this.cjCellStyle.disabledFontColor
            this.cjCellStatus.fontSize = this.cjCellStyle.todayFontSize ?? this.cjCellStyle.fontSize
            // 2、描述颜色
            this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStyle.disabledFontColor
            // 3、标注颜色
            this.cjCellStatus.markFontColor = this.cjCellStyle.markFontColor ?? this.cjCellStyle.disabledFontColor
            // 4、背景颜色
            this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor
            // 5、边框颜色
            this.cjCellStatus.borderColor = this.cjCellStyle.borderColor
          }
        } else {
          if (this.isNeedMarkToday) {
            // 一般不可用 - 今日 - 面型 - 需要回显
            // 1、日期颜色
            this.cjCellStatus.fontColor = this.cjCellStyle.todayDisabledFontColor ?? "#FFFFFF"
            this.cjCellStatus.fontSize = this.cjCellStyle.todayFontSize ?? this.cjCellStyle.fontSize
            // 2、描述颜色
            this.cjCellStatus.descFontColor = this.cjCellStyle.descDisabledFontColor ?? this.cjCellStatus.fontColor
            // 3、标注颜色
            this.cjCellStatus.markFontColor = this.cjCellStyle.disabledFontColor ?? this.cjCellStatus.fontColor
            // 4、背景颜色
            this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor ?? ColorUtil.lightenColor(this.cjCellStyle.todayBackgroundColor ?? this.themeColor, this.cjCellStyle.lightRatio)
            // 5、边框颜色
            this.cjCellStatus.borderColor = ColorUtil.lightenColor(this.cjCellStyle.selectBoderColor ?? this.themeColor, this.cjCellStyle.lightRatio)

          } else {
            // 一般不可用 - 今日 - 面型 - 不需要回显
            // 1、日期颜色
            this.cjCellStatus.fontColor = this.cjCellStyle.todayDisabledFontColor ?? this.cjCellStyle.disabledFontColor
            this.cjCellStatus.fontSize = this.cjCellStyle.todayFontSize ?? this.cjCellStyle.fontSize
            // 2、描述颜色
            this.cjCellStatus.descFontColor = this.cjCellStyle.descDisabledFontColor ?? this.cjCellStatus.fontColor
            // 3、标注颜色
            this.cjCellStatus.markFontColor = this.cjCellStyle.disabledFontColor ?? this.cjCellStatus.fontColor
            // 4、背景颜色
            this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor ?? this.cjCellStyle.itemBackgroundColor
            // 5、边框颜色
            this.cjCellStatus.borderColor = this.cjCellStyle.selectBoderColor ?? this.cjCellStyle.borderColor

          }
        }
      } else {
        if (isLineStye) {
          // 一般不可用 - 非今日 - 线型
          // 1、日期颜色
          this.cjCellStatus.fontColor = this.cjCellStyle.disabledFontColor
          this.cjCellStatus.fontSize = this.cjCellStyle.fontSize
          // 2、描述颜色
          this.cjCellStatus.descFontColor = this.cjCellStyle.descFontColor ?? this.cjCellStyle.disabledFontColor
          // 3、标注颜色
          this.cjCellStatus.markFontColor = this.cjCellStyle.markDisabledFontColor ?? this.cjCellStyle.disabledFontColor
          // 4、背景颜色
          this.cjCellStatus.backgroundColor = this.cjCellStyle.itemBackgroundColor
          // 5、边框颜色
          this.cjCellStatus.borderColor = this.cjCellStyle.borderColor

        } else {
          // 一般不可用 - 非今日 - 面型
          // 1、日期颜色
          this.cjCellStatus.fontColor = this.cjCellStyle.disabledFontColor
          this.cjCellStatus.fontSize = this.cjCellStyle.fontSize
          // 2、描述颜色
          this.cjCellStatus.descFontColor = this.cjCellStyle.descDisabledFontColor ?? this.cjCellStatus.fontColor
          // 3、标注颜色
          this.cjCellStatus.markFontColor = this.cjCellStyle.disabledFontColor ?? this.cjCellStatus.fontColor
          // 4、背景颜色
          this.cjCellStatus.backgroundColor = this.cjCellStyle.disabledBackgroundColor ?? this.cjCellStyle.itemBackgroundColor
          // 5、边框颜色
          this.cjCellStatus.borderColor = this.cjCellStyle.borderColor

        }

      }

    } else if (style == 5) {
      // 一般不可用 - 选中
      if (isLineStye) {
        if (this.cjDataItem.isToday) {
          // 一般不可用 - 选中 - 线型 - 今日
          // 1、日期颜色
          this.cjCellStatus.fontColor = this.cjCellStyle.todayDisabledFontColor ?? ColorUtil.lightenColor(this.cjCellStyle.selectFontColor ?? this.themeColor, this.cjCellStyle.lightRatio)
          this.cjCellStatus.fontSize = this.cjCellStyle.selectFontSize ?? this.cjCellStyle.fontSize
          // 2、描述颜色
          this.cjCellStatus.descFontColor = this.cjCellStyle.todayDisabledFontColor ?? this.cjCellStatus.fontColor
          // 3、标注颜色
          this.cjCellStatus.markFontColor = this.cjCellStyle.todayDisabledFontColor ?? this.cjCellStatus.fontColor
          // 4、背景颜色
          this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor ?? this.cjCellStyle.itemBackgroundColor
          // 5、边框颜色
          this.cjCellStatus.borderColor = ColorUtil.lightenColor(this.cjCellStyle.selectBoderColor ?? this.themeColor, this.cjCellStyle.lightRatio)

        } else {
          // 一般不可用 - 选中 - 线型 - 非今日
          // 1、日期颜色
          this.cjCellStatus.fontColor = ColorUtil.lightenColor(this.cjCellStyle.selectFontColor ?? this.themeColor, this.cjCellStyle.lightRatio)
          this.cjCellStatus.fontSize = this.cjCellStyle.selectFontSize ?? this.cjCellStyle.fontSize
          // 2、描述颜色
          this.cjCellStatus.descFontColor = this.cjCellStyle.descDisabledFontColor ?? this.cjCellStatus.fontColor
          // 3、标注颜色
          this.cjCellStatus.markFontColor = this.cjCellStyle.disabledFontColor ?? this.cjCellStatus.fontColor
          // 4、背景颜色
          this.cjCellStatus.backgroundColor = this.cjCellStyle.disabledBackgroundColor ?? this.cjCellStyle.itemBackgroundColor
          // 5、边框颜色
          this.cjCellStatus.borderColor = ColorUtil.lightenColor(this.cjCellStyle.selectBoderColor ?? this.themeColor, this.cjCellStyle.lightRatio)

        }

      } else {
        // 一般不可用 - 选中 - 面型
        // 1、日期颜色
        this.cjCellStatus.fontColor = this.cjCellStyle.todayDisabledFontColor ?? "#FFFFFF"
        this.cjCellStatus.fontSize = this.cjCellStyle.selectFontSize ?? this.cjCellStyle.fontSize
        // 2、描述颜色
        this.cjCellStatus.descFontColor = this.cjCellStyle.descDisabledFontColor ?? this.cjCellStatus.fontColor
        // 3、标注颜色
        this.cjCellStatus.markFontColor = this.cjCellStyle.disabledFontColor ?? this.cjCellStatus.fontColor
        // 4、背景颜色
        this.cjCellStatus.backgroundColor = this.cjCellStyle.todayDisabledBackgroundColor ?? ColorUtil.lightenColor(this.cjCellStyle.todayBackgroundColor ?? this.themeColor, this.cjCellStyle.lightRatio)
        // 5、边框颜色
        this.cjCellStatus.borderColor = ColorUtil.lightenColor(this.cjCellStyle.selectBoderColor, this.cjCellStyle.lightRatio)
      }
    }

  }

  /**
   * 临时选中项改变
   */
  __onTempSelectedChangeed() {
    // 目前仅常规模式会有临时选中项
    if (this.optMode == OptMode.NORMAL) {
      if (!this.cjDataItem.isPre && !this.cjDataItem.isNext && !this.cjDataItem.disabled) {
        // 同一天
        if (this.cjDataItem.equalDay(this.tempSelectedItem)) {
          // this.setSelectedStyle()
        } else {
          // this.setNormalCententStyle()
        }
      }
    }
  }

  containsItem(cellItem: CJDateItem): number {
    return this.selectedItems.findIndex(item => item.equalDay(cellItem))
  }
}
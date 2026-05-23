import { Solar } from 'lunar'
import { CJCellStyle } from './CJCellStyle'
import { CJDateItem } from './CJDateItem'
import { CJDay } from './CJDay'

@Component
export struct CJWeek {
  @State startItem: CJDateItem | undefined = undefined
  @State days: Array<CJDateItem> = new Array()
  @Consume showLunar: boolean
  today: CJDateItem = new CJDateItem(new Date())
  startDate: Date = new Date("1970-01-01")
  endDate: Date = new Date(new Date().getFullYear() + 10, 0, 1)
  // ========自定义布局==========
  /** 构建单元格背景 */
  @BuilderParam buildCellBackground: CustomBuilder = this.BuildCellBackground
  /** 构建不可选中Cell背景，当实现buildCellBackground时，该方法无效 */
  @BuilderParam buildDisableCellBackground: CustomBuilder = this.BuildDisableCellBackground
  /** 构建单元格主体内容 */
  @BuilderParam buildCellBody: CustomBuilder = this.BuildCellBody
  /** 构建自定义标记 */
  @BuilderParam buildMark: CustomBuilder = this.BuildMark
  /**
   * 重新构建Item
   */
  reBuildCellItem?: (cjDateItem: CJDateItem) => void
  /** 自定义构建每一项的样式 */
  buildCellStyle: (cjDataItem: CJDateItem) => CJCellStyle = () => {
    return new CJCellStyle()
  }
  cellClick: (cjDataItem: CJDateItem) => void = () => {
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

  aboutToAppear(): void {
    if (this.startItem) {
      let tempDate: Date = new Date(this.startItem.time)
      for (let index = 0; index < 7; index++) {
        let item = new CJDateItem(
          tempDate,
          // (index < preCount ? true : false) || this.startDate.getTime() > tempDate.getTime(),
          // (index >= preCount + count ? true : false) || this.endDate.getTime() < tempDate.getTime()
        )
        // item.isSmallThanStart = index < preCount
        // item.isBigThanEnd = index >= preCount + count
        // console.log("date:", item.date, ",isSmallThanStart:", item.isSmallThanStart, ",isBigThanEnd:", item.isBigThanEnd)
        item.isToday = tempDate.getFullYear() == this.today.fullYear && tempDate.getMonth() == this.today.month &&
          tempDate.getDate() == this.today.date
        if (this.reBuildCellItem) {
          // item = this.reBuildCellItem(item)
          this.reBuildCellItem(item)
        }
        if (this.showLunar) { // 显示农历
          item.solar = Solar.fromYmd(item.fullYear, item.month + 1, item.date)
        }

        this.days.push(item)
        tempDate.setDate(tempDate.getDate() + 1)
      }
    }
  }

  build() {
    Row() {
      ForEach(this.days, (item: CJDateItem) => {
        CJDay({
          cjDataItem: item,
          today: this.today,
          cjCellStyle: this.buildCellStyle(item),
          buildDisableCellBackground: this.buildDisableCellBackground,
          buildCellBackground: this.buildCellBackground,
          buildCellBody: this.buildCellBody,
          buildMark: this.buildMark,
          cellClick: (cjDataItem: CJDateItem) => {
            this.cellClick(cjDataItem)
          }
        })
          .layoutWeight(1)
      }, (item: CJDateItem) => item.time.toString())
    }
    .width("100%")
  }
}
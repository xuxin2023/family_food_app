import { SelectedShape } from '../components/SelectedShape'
import { OptMode } from '../components/OptMode'
import { SelectedStyle } from '../components/SelectedStyle'
import { CJCellStyle } from '../components/CJCellStyle'
import { CellStatus } from '../components/CellStatus'
import { CJCalStatusParams } from '../components/CJCalStatusParams'

// import { CJCalendar as CJCalendarV2 } from '../components/CJCalendarV2';
import { CJDateItem } from '../components/CJDateItem';
import { Solar } from 'lunar';
import { CJCalendarV2 } from '../components/CJCalendarV2'
import { CJCalendarControlV2 } from '../components/CJCalendarControlV2'
import { CJViewModel } from '../components/CJViewModel'

const TAG = "MainPage"

@Component
@Entry
export struct MainPage {
  cjDataItem: CJDateItem = new CJDateItem(new Date())
  @State message: string = 'Hello World';
  cjCellStyle: CJCellStyle = new CJCellStyle()
  cjCalStatus: CJCalStatusParams = new CJCalStatusParams()
  cjCellStatus: CellStatus = new CellStatus()
  controller: CJCalendarControlV2 = new CJCalendarControlV2()
  @State defSelectedItems: Array<string> = ["2024-06-03", "2024-06-08"]
  @State extras: Record<string, number | string | boolean> = {}
  // 测试刷新
  @State test: string = ""

  build() {
    Column() {
      Text("日历Demo")
        .height(50)
        .textAlign(TextAlign.Center)
      Scroll() {
        Column() {

          CJCalendarV2({
            controller: this.controller,
            extras: this.extras,
            // 初始化默认选中项目
            optMode: OptMode.SINGLE,
            viewModel: CJViewModel.MONTH,
            // 初始化选中项
            defSelectedItems: ["2024-06-03"],
            selectedStyle: SelectedStyle.ALONE,
            // 指定每一行高度，如果没有特殊需求不需要指定
            // itemCellHeight: 50,
            startDate: new Date("2024-02-3"),
            endDate: new Date("2024-09-25"),
            // 默认选中样式形状，optMode = OptMode.MULTIPLE、OptMode.SINGLE
            // 或者 optMode = OptMode.RANGE 且 selectedStyle = SelectedStyle.ALONE 、
            // 时 SelectedShape.CIRCLE生效
            // 否则 SelectedShape.RECT 生效
            selectedShape: SelectedShape.SHAPE_RECT,
            showFastToday: true,
            initShowDate: new Date("2024-05-01"),
            // 标题栏高度
            // titleHeight: 100,
            // 标题栏背景色
            // titleBackgroundColor: Color.Green,
            // 标题格式化显示
            titleFormat: "yyyy年MM月",
            // 是否显示农历
            showLunar: true,
            // 设置整个月份视图高度
            // monthHeight: 300,
            // 是否显示节日
            // showJieRi: false,
            // 是否显示节气
            // showJieQi: false,
            // 是否仅显示当月日期
            // onlyShowCurrMonthDay: true,
            // showToolbar: true,
            // 自定义标题栏
            // toolbarLayout: this.ToolbarLayout,
            // 不可选中Cell背景
            // buildDisableCellBackground: this.BuildDisableCellBackground,
            // 自定义单元格背景
            // buildCellBackground: this.BuildCellBackground,
            onMonthChanged: (month: CJDateItem) => {
              console.log("月份切换：", JSON.stringify(month))
            },
            onCellItemClick: (item: CJDateItem) => {
              // 这里修改数据后会同步更新到界面
              // item.date = item.date + 1
              // item.extras.set("test", "-" + (item.date + 1) + "-")
              console.log("点击了：", JSON.stringify(item))
              return false
            },
            onDisableCellItemClick: (item: CJDateItem) => {
              console.log("越界点击了：", JSON.stringify(item))
              return false
            },
            onSelectedChanged: (items: Array<CJDateItem>) => {
              console.log("选择变化：", JSON.stringify(items))
            },
            // 自定义标注
            // buildMark: this.BuildMark,
            // 自定义主体部分
            // buildCellBody: this.BuildCellBody,
            // 向CellItem中添加自定义属性
            reBuildCellItem: (cjDateItem: CJDateItem) => {
              // 需要向 CJDateItem 中添加附加数据时，可是使用如下方式
              cjDateItem.extras.test = "自定义附加属性" + cjDateItem.date
              if (cjDateItem.date > 15 && cjDateItem.date < 20) {
                // 文字与图片优先显示图片
                cjDateItem.markText = "标"

                cjDateItem.markIcon = $r("app.media.icon")
                cjDateItem.markImageUrl =
                  "https://img2.baidu.com/it/u=2105446738,2493267053&fm=253&fmt=auto&app=138&f=JPEG?w=100&h=100"
              }
              if (cjDateItem.fullYear == 2024 && cjDateItem.month == 7
                && cjDateItem.date < 20 && cjDateItem.date > 15) {
                // 设置不能选中
                cjDateItem.disabled = true
              }
              if (cjDateItem.date > 5 && cjDateItem.date < 7) {
                cjDateItem.markText = this.test
              }
              return cjDateItem
            },

            // 自定义Cell样式风格
            buildCellStyle: (item: CJDateItem) => {
              let cjCellStyle: CJCellStyle = new CJCellStyle()
              // 设置选中色
              cjCellStyle.selectItemBackgroundColor = "#FF00BB"
              // 标注样式
              cjCellStyle.markFontColor = "#ff922f08"
              cjCellStyle.markFontSize = 10
              cjCellStyle.markMarin = 2
              cjCellStyle.markFontWeight = FontWeight.Bold
              cjCellStyle.markImageWidth = 12
              cjCellStyle.markAlignment = Alignment.TopEnd

              if (item.isToday) {
                cjCellStyle.fontColor = "#FFFFFF"
                cjCellStyle.itemBackgroundColor = "#ff1c6a46"
              }
              // 设置今天文字颜色
              // cjCellStyle.todayFontColor = "#FFFFFF"
              // 设置今天背景色
              // cjCellStyle.todayBackgroundColor = "#ff1c6a46"

              // 设置空心
              // if (item.isToday) {
              //   cjCellStyle.todayFontColor = "#ff1c6a46"
              //   cjCellStyle.todayBackgroundColor = "#FFFFFF"
              //   cjCellStyle.boderColor = "#ff1c6a46"
              //   cjCellStyle.boderWidth = 1
              //   cjCellStyle.boderRadius = 100
              // }
              // 根绝条件修改背景色、字体色等
              if (item.date < 7) {
                cjCellStyle.itemBackgroundColor = "#abedd8"
                cjCellStyle.fontColor = "#3f72af"
              } else if (item.date >= 10 && item.date < 16) {
                cjCellStyle.itemBackgroundColor = "#e4f9f5"
                cjCellStyle.fontColor = "#3d84a8"
              } else if (item.date >= 20 && item.date <= 28) {
                cjCellStyle.itemBackgroundColor = "#88304e"
                cjCellStyle.fontColor = "#fae3d9"
              }
              return cjCellStyle
            }
          })

          Flex({ wrap: FlexWrap.Wrap }) {
            Button("触发点击")
              .onClick(() => {
                // 实现还没写完
                this.controller.clickItem(2024, 6, 6)
              })
            Button("设置选中")
              .onClick(() => {
                this.controller.selectItems(["2024-06-09"])
              })
            Button("显示农历")
              .onClick(() => {
                this.controller.showLunar(true)
              })
            Button("隐藏农历")
              .onClick(() => {
                this.controller.showLunar(false)
              })
            Button("切换周模式")
              .onClick(() => {
                this.controller.changViewModel(CJViewModel.WEEK)
              })
            Button("切换月模式")
              .onClick(() => {
                this.controller.changViewModel(CJViewModel.MONTH)
              })
            Button("切换年模式")
              .onClick(() => {
                this.controller.changViewModel(CJViewModel.YEAR)
              })
            Button("跳转至指定星期/月份/年份")
              .onClick(() => {
                this.controller.skipToDate("2024-02-01")
              })
            Button("刷新")
              .onClick(() => {
                this.test = "11"
                this.controller.refresh()
              })
          }
          .margin({
            top: 20
          })
        }
        .justifyContent(FlexAlign.Start)
      }
      .align(Alignment.Top)
      .layoutWeight(1)
    }
    .height("100%")
  }

  @Builder
  ToolbarLayout() {
    Column() {
      Row() {
        Button("上一月")
          .onClick(() => {
            this.controller.preMonth()
          })
        Blank()
        Text(this.cjCalStatus.title + (this.extras.test ?? ""))
          .fontColor(Color.White)
          .onClick(() => {
            this.extras.test = "测试"
            // let datas = this.controller.getItemSource()
            // if (datas) {
            //   console.log("测试", "点击11")
            // datas.getData().date = 29
            // datas[0].extras.set("test", "测试")
            // }
          })
        Blank()
        Button("下一月")
          .onClick(() => {
            this.controller.nextMonth()
            // this.defSelectedItems = ["2024-06-05", "2024-06-13"]
            // this.controller.skipToMonth("2024-06-01")

          })
      }
      .width("100%")

      Text("此处可添加广告位")
        .fontSize(20)
        .textAlign(TextAlign.Center)
        .width("100%")
        .height(100)
        .backgroundColor(Color.Pink)
    }
    .backgroundColor(Color.Orange)
    .width("100%")

  }

  @Builder
  BuildMark() {
    Circle()
      .width(10)
      .height(10)
      .fill("#aa2288")
    // 或者以下可自定义各种复杂布局
    // Stack() {
    //   // ......
    // }
    // .width("100%")
    // .height("100%")
    // .alignContent(Alignment.TopEnd)
  }

  @Builder
  BuildCellBackground() {
    if (this.cjDataItem.isToday) { // 今天
      Column()
        .backgroundColor(Color.Yellow)
        .width('85%')
        .aspectRatio(1)
        .border({
          width: this.cjCellStyle.borderWidth,
          color: this.cjCellStyle.borderColor
        })
        .borderRadius(this.cjCellStyle.borderRadius)
    } else {
      Column() {
        if (this.cjDataItem.isSelected) {
          Circle()
            .width(10)
            .height(10)
            .backgroundColor(Color.Brown)
        }
      }
      .alignItems(HorizontalAlign.End)
      .justifyContent(FlexAlign.Start)
      .backgroundColor(this.cjCellStatus.backgroundColor)
      .width('85%')
      .aspectRatio(1)
      .border({
        width: this.cjCellStyle.borderWidth,
        color: this.cjCellStyle.borderColor
      })
      .borderRadius(this.cjCellStyle.borderRadius)
    }

  }

  @Builder
  BuildCellBody() {
    Column() {
      Text(this.cjDataItem.date + '')
        .fontColor(this.cjCellStatus.fontColor)
        .fontSize(this.cjCellStyle.fontSize)
        .fontWeight(this.cjCellStyle.fontFontWeight)
      // 可以加备注之类的自定义信息
      Text(this.cjDataItem.extras.test as string)
        .fontSize(10)
        .fontColor(Color.Gray)
        .fontColor(this.cjCellStatus.fontColor)
    }
    .alignItems(HorizontalAlign.Center)

  }

  @Builder
  BuildDisableCellBackground() {
    Column() {
      Text("测试")
    }
    .backgroundColor(Color.Yellow)
    .width('85%')
    .aspectRatio(1)
    .border({
      width: this.cjCellStyle.borderWidth,
      color: this.cjCellStyle.borderColor
    })
    .borderRadius(this.cjCellStyle.borderRadius)

  }
}

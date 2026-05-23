# 版本更新记录

## v2.3.5
1. 添加setDisableSwipe，设置禁用组件滑动切换功能

## v2.3.4
1. CJCellStyle 添加属性 markBackgroundColor?: ResourceColor 、markRadius?: Length 、markPadding?: Padding | Length | LocalizedPadding

## v2.3.3
1. 添加枚举 WeekStartMode：切换从日历从周一/周二/周二/周三/周四/周五/周六/周天开始

## v2.3.2
1. 修复部分已知问题

## v2.3.1
1. 添加属性 weekStartMode：切换从日历从周一 或 周天开始 


## v2.3.0
1. 修复已知问题

## v2.2.9
1. CJDateItem 添加 dateText 属性，当dateText被赋值时，会替代date日期显示

## v2.2.8
1. 添加自定义样式字体处理

## v2.2.7
1. 选中样式SelectedShape添加：线型-圆（LINE_CIRCLE）、线型-矩形（LINE_RECT）
2. 选中样式SelectedShape字段调整：CIRCLE -> SHAPE_CIRCLE, RECT -> SHAPE_RECT
3. 添加主题色：themeColor，会自定关联选中色、今日、标签色等
4. 新加字段CJCellStyle中：todayDisabledFontColor、todayDisabledBackgroundColor·······
5. 添加字段是否标记今日，仅在常规模式下支持，isNeedMarkToday，
6. 添加字段全局圆角设置，优先级低于单元格内部圆角，selectedBorderRadius，
7. 样式结构算法整体调整

## v2.2.6
1. CJDateItem 添加描述 desc，用于承载之前的农历，也可以是其他描述，区别于Mark的文字标签
2. CJCellStyle 下变量名调整：
lunarFontSize -> descFontSize， lunarFontColor -> descFontColor，lunarFontFontWeight -> descFontFontWeight,
lunarMargin -> descMargin, selectLunarFontColor -> selectDescFontColor
3. CJCellStyle 添加不可用描述字体颜色控制字段：disabledDescFontColor
4. 添加农历描述信息构建方法，可添加更满足业务的实现：buildCellLunarDesc
5. CJDateShowBackMode添加回显模式：SHOW_CLICK，当点击或指定日期时，选中操作的日期, 可与其他的同时使用, 
比如：CJDateShowBackMode.SHOW_CLICK | CJDateShowBackMode.SHOW_PRE_LAST_NEXT_FIRST

## v2.2.5
1. CJDateShowBackMode添加回显模式：SHOW_PRE_LAST_NEXT_FIRST，切换上月显示最后一天，切换下月显示第一天
2. 丰富农历字体颜色控制，更加便捷控制样式显示
3. 添加点击事件前置拦截：onCellClickIntercept

## v2.2.4
1. 修复因Swiper因嵌套其他带滑动容器所导致的数据加载异常问题
2. onDisableCellItemClick添加返回值，需要拦击返回true
3. onCellItemClick添加返回值，需要拦击返回true
4. 完善部分文档

## v2.2.3
1. 新增buildWeekTitleCell：自定义星期cell

## v2.2.2
1. 控制器添加方法 getPreMonthDays：获取上一月days项
2. 控制器添加方法 getNextMonthDays：获取下一月days项
3. 添加CJDateShowBackMode：月份切换回显模式，：
  -- SHOW_LAST：显示最后一天
  -- SHOW_FIRST: 显示第一天
  -- SHOW_LAST_TO_FIRST: 日期不足显示第一天
4. 添加onMonthChangeBefore：月份切换之前监听函数


## v2.2.1
1、添加月份切换切换时，回显最后一次选中日期日期，比如选中10月20日，切换11月时，会标记11月20日
2、调整为常规模式下才会回显

## v2.2.0
1. 新增字段 onlyShowDateArea：仅需要日期显示区域，不需要底部自定义区域
2. 修复已知问题

## v2.1.9
1. 新增字段 isAttchCustomLayoutToWhole：是否将底部用户布局添加到整体，默认是每个月，可跟随滑动
2. 新增方法 onInitFinish：日历初始化数据完成
2. 完善部分内部功能
3. 完善部分文档信息

## v2.1.8
1. 新增自定义布局 buildMonthCustomLayout：月视图底部用户自定义区域
2. 新增字段 isShowFoldView，是否显示折叠按钮
3. 新增自定义布局 buildFoldCustomLayout：自定义折叠区域样式
4. 日历内部调整
5. reBuildCellItem 去掉返回值
5. 年模式待更新...
6. 文档不断完善中，有疑问进群讨论

## v2.1.5
1. 完善部分周模式功能

## v2.1.4
1. 完善部分新功能

## v2.1.3
1. 分离标注、自定义标注等，更加简洁添加标注信息等

## v2.1.2
1. 修复已知BUG

## v2.1.1
1. 修复已知BUG

## v2.1.0
1. 添加滑动
2. 内部结构调整

## v2.0.7
1、添加单元格是否选中状态 isSelected

## v2.0.6
1、修复已知BUG

## v2.0.5
1、添加标题格式化显示 titleFormat
2、添加初始化加载月份 initMonth
3、修复已知问题

## v2.0.4
1、CJCalendarControl 添加 selectItems

## v2.0.3
1、修复已知问题

## v2.0.2
1、修复已知问题

## v2.0.1
1、添加日历控制器 controller
2、添加初始化默认选中项目 defSelectedItems

## v2.0.0
1、文档调整
2、属性调整

## v1.2.3
1、添加是否显示农历控制字段
2、添加是否显示节气
3、添加是否显示节日

## v1.2.2
1、添加是否仅显示当月日期字段

## v1.2.1
1、功能完善

## v1.2.0
1、代码重构 适配NEXT版本

## v1.1.8
1. 修复已知BUG

## v1.1.7
1. 修复设置startDate时，不包含当天的BUG

## v1.1.6
1. 修复兼容部分next语法

## v1.1.5
1. 添加 selectedBackgroundLayout, 添加自定义独立选中风格样式
2. 添加 仅自定义 每项 日期文字注意区域
3. 添加属性extremityRadius，当为RANGE、CLOSE 时，两头的圆角

## v1.1.4
1. 兼容处理rangeStyle == 2 的样式

## v1.1.3
1. 移除weekTitle默认背景色
2. 修复初始化加载选中项

## v1.1.2
1. 添加自定义顶部布局：cusTopLayout、cusTopStateListener

## v1.1.1
1. 添加月份改变回调：onMonthChange

## v1.1.0
1. 调整默认不显示时间选择
2. 添加文档案例

## v1.0.9
1. 添加属性：showTime
2. onSelectChange 更名为 onDateChange
3. 添加 onTimeChange
4. 添加 CJTimeItem
5. 时间选择交互还在不断优化中

## v1.0.8
1. 细节调整

## v1.0.7
1. 添加 startDate、endDate 日期限制

## v1.0.6
1. 使用文档更新

## v1.0.5
1. 添加属性 已选中日期 selectedDates
2. 添加属性 不能使用日期颜色  disabledFontColor

## v1.0.3

1. 添加时间范围选择

## v1.0.2

1. fastTodayBg 修改默认背景 为当前主题色

## v1.0.1

1. 添加属性 selectItemBgColor
2. 文档整理

## v1.0.0
1. 日历组件
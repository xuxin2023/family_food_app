/**v
 * 日期回显方式
 */
export enum CJDateShowBackMode {
  /** 当前选择日期大于切换月最大日期时，选中切换月最后一天 */
  SHOW_LAST = 0x01,
  /** 当前选择日期大于切换月最大日期时，选中切换月第一天 */
  SHOW_LAST_TO_FIRST = 0x02,
  /** 当切换月分时，都显示1号，可以SHOW_CLICK结合使用 */
  SHOW_FIRST = 0x03,
  /** 切换上月显示最后一天，切换下月显示第一天，可与SHOW_CLICK结合使用 */
  SHOW_PRE_LAST_NEXT_FIRST = 0x04,
  /** 当点击或指定日期时，选中操作的日期, 可与其他的同时使用，
   *  比如：CJDateShowBackMode.SHOW_CLICK | CJDateShowBackMode.SHOW_PRE_LAST_NEXT_FIRST
   */
  SHOW_CLICK = 0x10
}
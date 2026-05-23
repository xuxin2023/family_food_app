import { CJDateItem } from '../components/components/CJDateItem'

const TAG = "CommonUtil"

export class CommonUtil {
  /**
   * 是否被包含在不可选中集合中
   * @returns
   */
  // static isInDisableArray(cellItem: CJDateItem, disableSelectedItems: Array<string | Date> | undefined): boolean {
  //   if (disableSelectedItems) {
  //     let index = disableSelectedItems.findIndex((value: string | Date) => {
  //       let temp: Date
  //       if (typeof value == "string") {
  //         temp = new Date(value)
  //       } else {
  //         temp = value
  //       }
  //
  //       return cellItem.fullYear == temp.getFullYear() &&
  //         cellItem.month == temp.getMonth() &&
  //         cellItem.date == temp.getDate()
  //     })
  //
  //     return index >= 0
  //   }
  //   return false
  // }
}
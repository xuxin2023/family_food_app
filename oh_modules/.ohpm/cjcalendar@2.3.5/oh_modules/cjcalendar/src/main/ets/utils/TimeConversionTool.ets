class TimeConversionTool {
  /**
   * 下面是一个通用较高的自定义日期时间格式化函数的示例
   */
  static formatDateTime(date: Date, format: string = "yyyy-MM-dd"): string {
    let yearMat = "yyyy"
    let monthMat = "MM"
    let dayMat = "dd"
    let hourMat = "HH"
    let minuteMat = "mm"
    let secondMat = "ss"
    let result = format
    if (result.indexOf(yearMat) >= 0) {
      result = result.replace(yearMat, date.getFullYear().toString())
    }
    if (result.indexOf(monthMat) >= 0) {
      result = result.replace(monthMat, TimeConversionTool.formatZero(date.getMonth() + 1))
    }
    if (result.indexOf(dayMat) >= 0) {
      result = result.replace(dayMat, TimeConversionTool.formatZero(date.getDate()))
    }
    if (result.indexOf(hourMat) >= 0) {
      result = result.replace(hourMat, TimeConversionTool.formatZero(date.getHours()))
    }
    if (result.indexOf(minuteMat) >= 0) {
      result = result.replace(minuteMat, TimeConversionTool.formatZero(date.getMinutes()))
    }
    if (result.indexOf(secondMat) >= 0) {
      result = result.replace(secondMat, TimeConversionTool.formatZero(date.getSeconds()))
    }
    return result;
  }

  static formatZero(num: number): string {
    return num.toString().padStart(2, "0")
  }

  static monthsBetween(date1: Date, date2: Date): number {
    const months = (date2.getFullYear() - date1.getFullYear()) * 12
    const monthDiff = date2.getMonth() - date1.getMonth() + 1
    return months + monthDiff;
  }

  static calcMontsBetween(startYear: number, startMonth: number, endYear: number, endMonth: number): number {
    const month1 = (endYear - startYear) * 12
    const month2 = endMonth - startMonth
    return month1 + month2
  }

  static calcWeeksBetween(date1: Date, date2: Date): number {
    const msPerDay = 24 * 60 * 60 * 1000;
    const daysBetween = Math.floor((date2.getTime() - date1.getTime()) / msPerDay);
    const weeksBetween = Math.floor(daysBetween / 7);
    return weeksBetween;
  }
}

export default TimeConversionTool;
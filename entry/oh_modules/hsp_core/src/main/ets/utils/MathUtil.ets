// 数学工具类

export class MathUtil {
  /**
   * 限制数值范围
   */
  static clamp(value: number, min: number, max: number): number {
    return Math.max(min, Math.min(max, value));
  }

  /**
   * 四舍五入到指定小数位
   */
  static roundTo(value: number, decimals: number): number {
    const factor = Math.pow(10, decimals);
    return Math.round(value * factor) / factor;
  }

  /**
   * 计算百分比
   */
  static percent(part: number, total: number): number {
    if (total === 0) return 0;
    return MathUtil.clamp((part / total) * 100, 0, 100);
  }
}

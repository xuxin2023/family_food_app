// 统一日志工具 — 封装 hilog，统一前缀与域
// 支持 release 包中自动 strip（配合 build-profile.json5 的 removeLog）

import { hilog } from '@kit.PerformanceAnalysisKit';
import { HILOG_DOMAIN_DEFAULT } from '../constants/AppConfig';

const DOMAIN_ZERO = HILOG_DOMAIN_DEFAULT;
const PREFIX = 'FamilyFood';

export class Logger {
  /**
   * INFO 级别日志 — 普通业务流程
   */
  static info(tag: string, format: string, ...args: Object[]): void {
    hilog.info(DOMAIN_ZERO, `${PREFIX}_${tag}`, format, args);
  }

  /**
   * ERROR 级别日志 — 可恢复异常
   */
  static error(tag: string, format: string, ...args: Object[]): void {
    hilog.error(DOMAIN_ZERO, `${PREFIX}_${tag}`, format, args);
  }

  /**
   * WARN 级别日志 — 非预期但可降级
   */
  static warn(tag: string, format: string, ...args: Object[]): void {
    hilog.warn(DOMAIN_ZERO, `${PREFIX}_${tag}`, format, args);
  }

  /**
   * DEBUG 级别日志 — 仅开发调试
   */
  static debug(tag: string, format: string, ...args: Object[]): void {
    hilog.debug(DOMAIN_ZERO, `${PREFIX}_${tag}`, format, args);
  }

  /**
   * FATAL 级别日志 — 致命错误，应用不可恢复
   */
  static fatal(tag: string, format: string, ...args: Object[]): void {
    hilog.fatal(DOMAIN_ZERO, `${PREFIX}_${tag}`, format, args);
  }
}

import hilog from '@ohos.hilog';

export class CJLogUtil {
  static IS_DEBUG: boolean = true
  static MODULE: number = 0x0000
  static readonly TAG_PRE = "CJCalendar"

  static info(tag: string, ...args: any) {
    if (CJLogUtil.IS_DEBUG) {
      hilog.info(CJLogUtil.MODULE, CJLogUtil.TAG_PRE + tag, '%{public}s', args.join());
    }
  }

  static error(tag: string, ...args: any) {
    if (CJLogUtil.IS_DEBUG) {
      hilog.error(CJLogUtil.MODULE, CJLogUtil.TAG_PRE + tag, '%{public}s', args.join());
    }
  }

  static debug(tag: string, ...args: any) {
    if (CJLogUtil.IS_DEBUG) {
      hilog.debug(CJLogUtil.MODULE, CJLogUtil.TAG_PRE + tag, '%{public}s', args.join());
    }
  }

  static warn(tag: string, ...args: any) {
    if (CJLogUtil.IS_DEBUG) {
      hilog.warn(CJLogUtil.MODULE, CJLogUtil.TAG_PRE + tag, '%{public}s', args.join());
    }
  }
}
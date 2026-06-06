import { display } from '@kit.ArkUI';

export enum DeviceType {
  PHONE = 'phone',
  TABLET = 'tablet',
  TWO_IN_ONE = '2in1'
}

export enum Breakpoint {
  SM = 'sm',
  MD = 'md',
  LG = 'lg'
}

export class DeviceAdapter {
  private static cachedType: DeviceType | null = null;
  private static cachedBreakpoint: Breakpoint | null = null;
  private static cachedWidthVp: number = 0;

  static getDeviceType(): DeviceType {
    if (DeviceAdapter.cachedType !== null) {
      return DeviceAdapter.cachedType;
    }
    try {
      const disp = display.getDefaultDisplaySync();
      const widthPx: number = disp.width;
      const density: number = disp.densityDPI / 160;
      const widthVp: number = widthPx / density;
      DeviceAdapter.cachedWidthVp = widthVp;
      if (widthVp >= 840) {
        DeviceAdapter.cachedType = DeviceType.TWO_IN_ONE;
      } else if (widthVp >= 600) {
        DeviceAdapter.cachedType = DeviceType.TABLET;
      } else {
        DeviceAdapter.cachedType = DeviceType.PHONE;
      }
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      DeviceAdapter.cachedType = DeviceType.PHONE;
    }
    return DeviceAdapter.cachedType;
  }

  static getBreakpoint(widthVp?: number): Breakpoint {
    const vp: number = widthVp ?? DeviceAdapter.getWidthVp();
    if (vp >= 840) {
      return Breakpoint.LG;
    } else if (vp >= 600) {
      return Breakpoint.MD;
    }
    return Breakpoint.SM;
  }

  static getWidthVp(): number {
    if (DeviceAdapter.cachedWidthVp > 0) {
      return DeviceAdapter.cachedWidthVp;
    }
    try {
      const disp = display.getDefaultDisplaySync();
      const density: number = disp.densityDPI / 160;
      DeviceAdapter.cachedWidthVp = disp.width / density;
    } catch (_e) {
      hilog.warn(DOMAIN_ZERO, TAG, "Exception: %{public}s", JSON.stringify(_e));
      DeviceAdapter.cachedWidthVp = 360;
    }
    return DeviceAdapter.cachedWidthVp;
  }

  static invalidateCache(): void {
    DeviceAdapter.cachedType = null;
    DeviceAdapter.cachedBreakpoint = null;
    DeviceAdapter.cachedWidthVp = 0;
  }

  static getGridColumns(): number {
    const bp: Breakpoint = DeviceAdapter.getBreakpoint();
    switch (bp) {
      case Breakpoint.LG: return 12;
      case Breakpoint.MD: return 8;
      default: return 4;
    }
  }

  static getCardColumns(): number {
    const bp: Breakpoint = DeviceAdapter.getBreakpoint();
    switch (bp) {
      case Breakpoint.LG: return 3;
      case Breakpoint.MD: return 2;
      default: return 1;
    }
  }

  static getCardSpacing(): number {
    const bp: Breakpoint = DeviceAdapter.getBreakpoint();
    switch (bp) {
      case Breakpoint.LG: return 24;
      case Breakpoint.MD: return 16;
      default: return 12;
    }
  }

  static getFontSizeScale(): number {
    const bp: Breakpoint = DeviceAdapter.getBreakpoint();
    switch (bp) {
      case Breakpoint.LG: return 1.15;
      case Breakpoint.MD: return 1.05;
      default: return 1.0;
    }
  }

  static getContentMaxWidth(): number {
    const bp: Breakpoint = DeviceAdapter.getBreakpoint();
    switch (bp) {
      case Breakpoint.LG: return 840;
      case Breakpoint.MD: return 600;
      default: return 0;
    }
  }

  static getSideMargin(): number {
    const bp: Breakpoint = DeviceAdapter.getBreakpoint();
    switch (bp) {
      case Breakpoint.LG: return 32;
      case Breakpoint.MD: return 24;
      default: return 16;
    }
  }

  static scaledFontSize(base: number): number {
    return Math.round(base * DeviceAdapter.getFontSizeScale());
  }

  static isTabletOrLarger(): boolean {
    const dt: DeviceType = DeviceAdapter.getDeviceType();
    return dt === DeviceType.TABLET || dt === DeviceType.TWO_IN_ONE;
  }

  static isWideScreen(): boolean {
    return DeviceAdapter.getBreakpoint() !== Breakpoint.SM;
  }
}

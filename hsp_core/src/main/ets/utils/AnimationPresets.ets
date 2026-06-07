import { curves } from '@kit.ArkUI';

export class AnimationPresets {
  static readonly FADE_IN: Record<string, number | Object> = { duration: 300, curve: curves.easeOut() } as Record<string, number | Object>;
  static readonly FADE_OUT: Record<string, number | Object> = { duration: 200, curve: curves.easeIn() } as Record<string, number | Object>;
  static readonly SLIDE_UP: Record<string, number | Object> = { duration: 400, curve: curves.springMotion(0.6, 0.8) } as Record<string, number | Object>;
  static readonly SLIDE_DOWN: Record<string, number | Object> = { duration: 300, curve: curves.easeOut() } as Record<string, number | Object>;
  static readonly SCALE_IN: Record<string, number | Object> = { duration: 350, curve: curves.springMotion(0.5, 0.9) } as Record<string, number | Object>;
  static readonly SCALE_OUT: Record<string, number | Object> = { duration: 250, curve: curves.easeIn() } as Record<string, number | Object>;
  static readonly BOUNCE: Record<string, number | Object> = { duration: 600, curve: curves.springMotion(0.4, 0.6) } as Record<string, number | Object>;
  static readonly STAGGER_DELAY: number = 50;

  static getStaggerDelay(index: number): number { return index * this.STAGGER_DELAY; }
}

export class ButtonStylePreset {
  static readonly PRESSED_SCALE: number = 0.97;
  static readonly PRESSED_OPACITY: number = 0.8;
  static readonly TRANSITION_DURATION: number = 150;

  static applyPressStyle(): Record<string, Object> {
    return {
      pressed: { scale: { x: 0.97, y: 0.97 }, opacity: 0.8 } as Record<string, Object>,
      normal: { scale: { x: 1, y: 1 }, opacity: 1 } as Record<string, Object>
    } as Record<string, Object>;
  }
}

export class PageTransitionStyle {
  static standardEnter(): Record<string, Object> {
    return { duration: 300, curve: Curve.EaseInOut } as Record<string, Object>;
  }
  static standardExit(): Record<string, Object> {
    return { duration: 250, curve: Curve.EaseInOut } as Record<string, Object>;
  }
  static cardExpand(): Record<string, Object> {
    return { duration: 250, curve: Curve.EaseOut } as Record<string, Object>;
  }
  static listItemSlideIn(index: number): Record<string, Object> {
    return { duration: 200 + index * 30, delay: index * 30, curve: Curve.EaseOut } as Record<string, Object>;
  }
}
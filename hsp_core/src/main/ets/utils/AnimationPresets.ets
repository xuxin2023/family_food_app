import { curves } from '@kit.ArkUI';
import { COLORS } from '../constants/AppTheme';

export class AnimationPresets {
  static readonly FADE_IN = { duration: 300, curve: curves.easeOut() };
  static readonly FADE_OUT = { duration: 200, curve: curves.easeIn() };
  static readonly SLIDE_UP = { duration: 400, curve: curves.springMotion(0.6, 0.8) };
  static readonly SLIDE_DOWN = { duration: 300, curve: curves.easeOut() };
  static readonly SCALE_IN = { duration: 350, curve: curves.springMotion(0.5, 0.9) };
  static readonly SCALE_OUT = { duration: 250, curve: curves.easeIn() };
  static readonly BOUNCE = { duration: 600, curve: curves.springMotion(0.4, 0.6) };
  static readonly STAGGER_DELAY = 50;

  static getStaggerDelay(index: number): number {
    return index * this.STAGGER_DELAY;
  }
}

export class ButtonStylePreset {
  static readonly PRESSED_SCALE = 0.97;
  static readonly PRESSED_OPACITY = 0.8;
  static readonly TRANSITION_DURATION = 150;

  static applyPressStyle(): object {
    return {
      pressed: { scale: { x: 0.97, y: 0.97 }, opacity: 0.8 },
      normal: { scale: { x: 1, y: 1 }, opacity: 1 }
    };
  }
}

export class PageTransitionStyle {
  static standardEnter(): object {
    return { duration: 300, curve: Curve.EaseInOut };
  }

  static standardExit(): object {
    return { duration: 250, curve: Curve.EaseInOut };
  }

  static cardExpand(): object {
    return { duration: 250, curve: Curve.EaseOut };
  }

  static listItemSlideIn(index: number): object {
    return {
      duration: 200 + index * 30,
      delay: index * 30,
      curve: Curve.EaseOut
    };
  }
}
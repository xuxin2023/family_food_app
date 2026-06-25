import { curves } from '@kit.ArkUI';

// 定义动画参数接口
interface AnimationParams {
  duration: number;
  curve: Curve | ICurve;
}

interface AnimationParamsWithDelay extends AnimationParams {
  delay?: number;
}

// 定义缩放接口
interface ScaleParams {
  x: number;
  y: number;
}

// 定义按钮样式接口
interface ButtonStateStyle {
  scale?: ScaleParams;
  opacity?: number;
}

interface ButtonStyle {
  pressed: ButtonStateStyle;
  normal: ButtonStateStyle;
}

export class AnimationPresets {
  static readonly STAGGER_DELAY: number = 50;
  
  static getFadeIn(): AnimationParams {
    const params: AnimationParams = { duration: 300, curve: Curve.EaseOut };
    return params;
  }
  
  static getFadeOut(): AnimationParams {
    const params: AnimationParams = { duration: 200, curve: Curve.EaseIn };
    return params;
  }
  
  static getSlideUp(): AnimationParams {
    const params: AnimationParams = { duration: 400, curve: curves.springMotion(0.6, 0.8) };
    return params;
  }
  
  static getSlideDown(): AnimationParams {
    const params: AnimationParams = { duration: 300, curve: Curve.EaseOut };
    return params;
  }
  
  static getScaleIn(): AnimationParams {
    const params: AnimationParams = { duration: 350, curve: curves.springMotion(0.5, 0.9) };
    return params;
  }
  
  static getScaleOut(): AnimationParams {
    const params: AnimationParams = { duration: 250, curve: Curve.EaseIn };
    return params;
  }
  
  static getBounce(): AnimationParams {
    const params: AnimationParams = { duration: 600, curve: curves.springMotion(0.4, 0.6) };
    return params;
  }

  static getStaggerDelay(index: number): number { 
    return index * AnimationPresets.STAGGER_DELAY; 
  }
}

export class ButtonStylePreset {
  static readonly PRESSED_SCALE: number = 0.97;
  static readonly PRESSED_OPACITY: number = 0.8;
  static readonly TRANSITION_DURATION: number = 150;

  static applyPressStyle(): ButtonStyle {
    const scale1: ScaleParams = { x: 0.97, y: 0.97 };
    const scale2: ScaleParams = { x: 1, y: 1 };
    const pressedStyle: ButtonStateStyle = { scale: scale1, opacity: 0.8 };
    const normalStyle: ButtonStateStyle = { scale: scale2, opacity: 1 };
    const style: ButtonStyle = { pressed: pressedStyle, normal: normalStyle };
    return style;
  }
}

export class PageTransitionStyle {
  static standardEnter(): AnimationParams {
    const params: AnimationParams = { duration: 300, curve: Curve.EaseInOut };
    return params;
  }
  
  static standardExit(): AnimationParams {
    const params: AnimationParams = { duration: 250, curve: Curve.EaseInOut };
    return params;
  }
  
  static cardExpand(): AnimationParams {
    const params: AnimationParams = { duration: 250, curve: Curve.EaseOut };
    return params;
  }
  
  static listItemSlideIn(index: number): AnimationParamsWithDelay {
    const params: AnimationParamsWithDelay = { duration: 200 + index * 30, delay: index * 30, curve: Curve.EaseOut };
    return params;
  }
}

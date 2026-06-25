import { curves } from '@kit.ArkUI';

export class Springs {
  static readonly CARD_ENTRANCE: ICurve = curves.springCurve(0.6, 14, 0.5, 1.0);
  static readonly TAB_SWITCH: ICurve = curves.springCurve(0.7, 12, 0.4, 1.0);
  static readonly BUBBLE_ENTRANCE: ICurve = curves.springCurve(0.5, 16, 0.6, 1.0);
  static readonly BUTTON_PRESS: ICurve = curves.springCurve(0.8, 20, 0.3, 1.0);
  static readonly GENTLE: ICurve = curves.springCurve(0.4, 10, 0.7, 1.0);
  static readonly OVERSHOOT: ICurve = curves.springCurve(0.3, 12, 0.5, 1.0);
  static readonly SCORE_REVEAL: ICurve = curves.springCurve(0.5, 18, 0.4, 1.0);
}

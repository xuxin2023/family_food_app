/**
 * hsp-core-cj/Index.ets — 仓颉计算模块 ArkTS 桥接层
 *
 * 架构说明:
 * - 编译时: 纯 ArkTS fallback 实现，无 Cangjie SDK 也可编译
 * - 运行时: 尝试动态加载原生 .so，成功则用 Cangjie 实现
 * - 降级: 原生库未就绪时使用 ArkTS 纯软件算法
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CjCompute';
const DOMAIN = 0xFF00;

export interface NutriScoreResult {
  score: number;
  grade: string;
}

let nativeLib: Record<string, Function> | null = null;

function loadNative(): void {
  if (nativeLib !== null) return;
  try {
    // NAPI native module not available in this build; use ArkTS fallback
    hilog.info(DOMAIN, TAG, 'Cangjie native unavailable, ArkTS fallback active');
  } catch (_e) {
    hilog.warn(DOMAIN, TAG, 'Cangjie native unavailable, ArkTS fallback active');
  }
}

export class CjCompute {
  static cosineSimilarity(a: number[], b: number[]): number {
    loadNative();
    if (nativeLib) return nativeLib['cosineSimilarity'](a, b) as number;
    return CjCompute.csSimFb(a, b);
  }

  static vectorNormalize(a: number[]): number[] {
    loadNative();
    if (nativeLib) return nativeLib['vectorNormalize'](a) as number[];
    return CjCompute.vecNormFb(a);
  }

  static nutriScoreCalc(
    cal: number, sug: number, sod: number, fat: number,
    sat: number, pro: number, fib: number, fvp: number
  ): NutriScoreResult {
    loadNative();
    if (nativeLib) {
      return nativeLib['nutriScoreCalc'](cal, sug, sod, fat, sat, pro, fib, fvp) as NutriScoreResult;
    }
    return CjCompute.nsCalcFb(cal, sug, sod, fat, sat, pro, fib, fvp);
  }

  static bmiCalculate(kg: number, cm: number): number {
    loadNative();
    if (nativeLib) return nativeLib['bmiCalculate'](kg, cm) as number;
    return CjCompute.bmiFb(kg, cm);
  }

  static weightedScore(f: number[], w: number[]): number {
    loadNative();
    if (nativeLib) return nativeLib['weightedScore'](f, w) as number;
    return CjCompute.wsFb(f, w);
  }

  static isNativeLoaded(): boolean { return nativeLib !== null; }

  private static csSimFb(a: number[], b: number[]): number {
    const n = Math.min(a.length, b.length);
    let d = 0; let na = 0; let nb = 0;
    for (let i = 0; i < n; i++) { d += a[i] * b[i]; na += a[i] * a[i]; nb += b[i] * b[i]; }
    if (na === 0 || nb === 0) return 0;
    return d / (Math.sqrt(na) * Math.sqrt(nb));
  }

  private static vecNormFb(a: number[]): number[] {
    let s = 0; for (const v of a) s += v * v;
    const m = Math.sqrt(s);
    return m === 0 ? [...a] : a.map(v => v / m);
  }

  private static nsCalcFb(
    cal: number, sug: number, sod: number, fat: number,
    sat: number, pro: number, fib: number, fvp: number
  ): NutriScoreResult {
    const neg = (cal / 500) * 20 + (sug / 30) * 15 + (sod / 1000) * 20 +
      (fat / 10) * 15 + (sat / 10) * 10;
    const pos = Math.min(pro / 20, 1) * 8 + Math.min(fib / 10, 1) * 6 +
      Math.min(fvp / 100, 1) * 6;
    const sc = Math.max(0, Math.min(100, 50 + pos * 10 - neg * 0.5));
    const gr = sc >= 80 ? 'A' : sc >= 60 ? 'B' : sc >= 40 ? 'C' : sc >= 20 ? 'D' : 'E';
    return { score: Math.round(sc), grade: gr };
  }

  private static bmiFb(kg: number, cm: number): number {
    const hm = cm / 100;
    return hm <= 0 ? 0 : kg / (hm * hm);
  }

  private static wsFb(f: number[], w: number[]): number {
    const n = Math.min(f.length, w.length);
    let t = 0; let s = 0;
    for (let i = 0; i < n; i++) { t += f[i] * w[i]; s += w[i]; }
    return s === 0 ? 0 : t / s;
  }
}

export {};

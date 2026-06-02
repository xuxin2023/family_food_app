// hsp-core-cj: 仓颉(Native Computing)高性能计算引擎
// NAPI 桥接暴露给 ArkTS 调用 — 用于数值密集型计算路径
// 函数: cosineSimilarity / nutriScoreCalc / vectorNormalize / bmiCalculate

package com.familyfood.compute

@Cdef
native func cj_compute_init(): unit

public func cosineSimilarity(a: Array<Float64>, b: Array<Float64>): Float64 {
    let n = min(a.size, b.size)
    var dotProduct: Float64 = 0.0
    var normA: Float64 = 0.0
    var normB: Float64 = 0.0
    for i in 0..n {
        dotProduct += a[i] * b[i]
        normA += a[i] * a[i]
        normB += b[i] * b[i]
    }
    if normA == 0.0 || normB == 0.0 {
        return 0.0
    }
    return dotProduct / (sqrt(normA) * sqrt(normB))
}

public func vectorNormalize(a: Array<Float64>): Array<Float64> {
    var sumSquares: Float64 = 0.0
    for i in 0..a.size {
        sumSquares += a[i] * a[i]
    }
    let magnitude = sqrt(sumSquares)
    if magnitude == 0.0 {
        return a
    }
    let result = Array<Float64>(a.size, item: 0.0)
    for i in 0..a.size {
        result[i] = a[i] / magnitude
    }
    return result
}

public struct NutriScoreResult {
    var score: Float64
    var grade: String
}

public func nutriScoreCalc(
    calories: Float64,
    sugar: Float64,
    sodium: Float64,
    fat: Float64,
    saturatedFat: Float64,
    protein: Float64,
    fiber: Float64,
    fruitVegPercent: Float64
): NutriScoreResult {
    var negativePoints = (calories / 500.0) * 20.0
    negativePoints += (sugar / 30.0) * 15.0
    negativePoints += (sodium / 1000.0) * 20.0
    negativePoints += (fat / 10.0) * 15.0
    negativePoints += (saturatedFat / 10.0) * 10.0

    var positivePoints = min(protein / 20.0, 1.0) * 8.0
    positivePoints += min(fiber / 10.0, 1.0) * 6.0
    positivePoints += min(fruitVegPercent / 100.0, 1.0) * 6.0

    var score = 50.0 + positivePoints * 10.0 - negativePoints * 0.5
    score = max(0.0, min(100.0, score))

    var grade = if score >= 80.0 { "A" }
                else if score >= 60.0 { "B" }
                else if score >= 40.0 { "C" }
                else if score >= 20.0 { "D" }
                else { "E" }

    return NutriScoreResult(score: score, grade: grade)
}

public func bmiCalculate(weightKg: Float64, heightCm: Float64): Float64 {
    let heightM = heightCm / 100.0
    if heightM <= 0.0 {
        return 0.0
    }
    return weightKg / (heightM * heightM)
}

public func weightedScore(
    factors: Array<Float64>,
    weights: Array<Float64>
): Float64 {
    let n = min(factors.size, weights.size)
    var total: Float64 = 0.0
    var weightSum: Float64 = 0.0
    for i in 0..n {
        total += factors[i] * weights[i]
        weightSum += weights[i]
    }
    if weightSum == 0.0 {
        return 0.0
    }
    return total / weightSum
}
package com.okx.ai.trader.indicators

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow
import kotlin.math.sqrt

/** Basic time series helpers */
private fun sma(values: List<Double>, period: Int): List<Double?> {
    if (period <= 0) return List(values.size) { null }
    val out = MutableList<Double?>(values.size) { null }
    var sum = 0.0
    for (i in values.indices) {
        sum += values[i]
        if (i >= period) sum -= values[i - period]
        if (i >= period - 1) out[i] = sum / period
    }
    return out
}

private fun ema(values: List<Double>, period: Int): List<Double?> {
    if (period <= 0) return List(values.size) { null }
    val out = MutableList<Double?>(values.size) { null }
    val k = 2.0 / (period + 1)
    var prev: Double? = null
    for (i in values.indices) {
        val v = values[i]
        prev = if (prev == null) v else (v - prev!!) * k + prev!!
        if (i >= period - 1) out[i] = prev
    }
    return out
}

private fun stddev(values: List<Double>, period: Int): List<Double?> {
    val avg = sma(values, period)
    val out = MutableList<Double?>(values.size) { null }
    for (i in values.indices) {
        val mean = avg[i] ?: continue
        var sumSq = 0.0
        for (j in i - period + 1..i) {
            val d = values[j] - mean
            sumSq += d * d
        }
        out[i] = sqrt(sumSq / period)
    }
    return out
}

private fun rsi(closes: List<Double>, period: Int = 14): List<Double?> {
    var gain = 0.0
    var loss = 0.0
    val out = MutableList<Double?>(closes.size) { null }
    for (i in 1 until closes.size) {
        val change = closes[i] - closes[i - 1]
        val g = max(change, 0.0)
        val l = max(-change, 0.0)
        if (i <= period) {
            gain += g
            loss += l
            if (i == period) {
                val rs = if (loss == 0.0) Double.POSITIVE_INFINITY else (gain / period) / (loss / period)
                out[i] = 100 - (100 / (1 + rs))
            }
        } else {
            val prevAvgGain = gain / period
            val prevAvgLoss = loss / period
            val avgGain = (prevAvgGain * (period - 1) + g) / period
            val avgLoss = (prevAvgLoss * (period - 1) + l) / period
            gain = avgGain * period
            loss = avgLoss * period
            val rs = if (avgLoss == 0.0) Double.POSITIVE_INFINITY else avgGain / avgLoss
            out[i] = 100 - (100 / (1 + rs))
        }
    }
    return out
}

private data class Macd(val macd: List<Double?>, val signal: List<Double?>, val hist: List<Double?>)
private fun macd(values: List<Double>, fast: Int = 12, slow: Int = 26, signalPeriod: Int = 9): Macd {
    val emaFast = ema(values, fast)
    val emaSlow = ema(values, slow)
    val macdLine = values.indices.map { i ->
        val f = emaFast[i]
        val s = emaSlow[i]
        if (f != null && s != null) f - s else null
    }
    val signalLine = ema(macdLine.map { it ?: 0.0 }, signalPeriod)
    val hist = values.indices.map { i ->
        val m = macdLine[i]
        val s = signalLine[i]
        if (m != null && s != null) m - s else null
    }
    return Macd(macdLine, signalLine, hist)
}

private data class BB(val upper: List<Double?>, val mid: List<Double?>, val lower: List<Double?>)
private fun bollinger(values: List<Double>, period: Int = 20, k: Double = 2.0): BB {
    val mid = sma(values, period)
    val sd = stddev(values, period)
    val upper = values.indices.map { i ->
        val m = mid[i]; val s = sd[i]
        if (m != null && s != null) m + k * s else null
    }
    val lower = values.indices.map { i ->
        val m = mid[i]; val s = sd[i]
        if (m != null && s != null) m - k * s else null
    }
    return BB(upper, mid, lower)
}

private fun atr(highs: List<Double>, lows: List<Double>, closes: List<Double>, period: Int = 14): List<Double?> {
    val tr = MutableList<Double>(highs.size) { 0.0 }
    for (i in highs.indices) {
        if (i == 0) {
            tr[i] = highs[i] - lows[i]
        } else {
            val hl = highs[i] - lows[i]
            val hc = abs(highs[i] - closes[i - 1])
            val lc = abs(lows[i] - closes[i - 1])
            tr[i] = max(hl, max(hc, lc))
        }
    }
    val out = ema(tr, period)
    return out
}

private data class Stoch(val k: List<Double?>, val d: List<Double?>)
private fun stochastic(highs: List<Double>, lows: List<Double>, closes: List<Double>, kPeriod: Int = 14, dPeriod: Int = 3): Stoch {
    val kValues = MutableList<Double?>(closes.size) { null }
    for (i in closes.indices) {
        if (i >= kPeriod - 1) {
            var highest = Double.NEGATIVE_INFINITY
            var lowest = Double.POSITIVE_INFINITY
            for (j in i - kPeriod + 1..i) {
                highest = max(highest, highs[j])
                lowest = min(lowest, lows[j])
            }
            kValues[i] = if (highest == lowest) 0.0 else (closes[i] - lowest) / (highest - lowest) * 100.0
        }
    }
    val dValues = sma(kValues.map { it ?: 0.0 }, dPeriod)
    return Stoch(kValues, dValues)
}

private fun obv(closes: List<Double>, volumes: List<Double>): List<Double> {
    val out = MutableList<Double>(closes.size) { 0.0 }
    for (i in 1 until closes.size) {
        out[i] = out[i - 1] + when {
            closes[i] > closes[i - 1] -> volumes[i]
            closes[i] < closes[i - 1] -> -volumes[i]
            else -> 0.0
        }
    }
    return out
}

private data class Ichimoku(val tenkan: List<Double?>, val kijun: List<Double?>)
private fun ichimoku(highs: List<Double>, lows: List<Double>): Ichimoku {
    fun mid(period: Int, i: Int): Double? {
        if (i < period - 1) return null
        var h = Double.NEGATIVE_INFINITY
        var l = Double.POSITIVE_INFINITY
        for (j in i - period + 1..i) {
            h = max(h, highs[j])
            l = min(l, lows[j])
        }
        return (h + l) / 2.0
    }
    val tenkan = highs.indices.map { mid(9, it) }
    val kijun = highs.indices.map { mid(26, it) }
    return Ichimoku(tenkan, kijun)
}

data class IndicatorSummary(
    val close: Double,
    val sma20: Double?,
    val ema20: Double?,
    val rsi14: Double?,
    val macd: Double?,
    val macdSignal: Double?,
    val macdHist: Double?,
    val bbUpper: Double?,
    val bbMid: Double?,
    val bbLower: Double?,
    val atr14: Double?,
    val stochK: Double?,
    val stochD: Double?,
    val obv: Double,
    val tenkan: Double?,
    val kijun: Double?
) {
    fun toPrettyString(): String = buildString {
        appendLine("Close: $close")
        appendLine("SMA20: ${sma20?.let { String.format("%.4f", it) } ?: "-"}")
        appendLine("EMA20: ${ema20?.let { String.format("%.4f", it) } ?: "-"}")
        appendLine("RSI14: ${rsi14?.let { String.format("%.2f", it) } ?: "-"}")
        appendLine("MACD: ${macd?.let { String.format("%.4f", it) } ?: "-"}  Signal: ${macdSignal?.let { String.format("%.4f", it) } ?: "-"}  Hist: ${macdHist?.let { String.format("%.4f", it) } ?: "-"}")
        appendLine("BB: U=${bbUpper?.let { String.format("%.4f", it) } ?: "-"} M=${bbMid?.let { String.format("%.4f", it) } ?: "-"} L=${bbLower?.let { String.format("%.4f", it) } ?: "-"}")
        appendLine("ATR14: ${atr14?.let { String.format("%.4f", it) } ?: "-"}")
        appendLine("Stoch: %K=${stochK?.let { String.format("%.2f", it) } ?: "-"} %D=${stochD?.let { String.format("%.2f", it) } ?: "-"}")
        appendLine("OBV: ${String.format("%.0f", obv)}")
        appendLine("Ichimoku: Tenkan=${tenkan?.let { String.format("%.4f", it) } ?: "-"} Kijun=${kijun?.let { String.format("%.4f", it) } ?: "-"}")
    }
}

fun computeSummaryFromSeries(
    closes: List<Double>, highs: List<Double>, lows: List<Double>, volumes: List<Double>
): IndicatorSummary {
    val sma20 = sma(closes, 20).last()
    val ema20 = ema(closes, 20).last()
    val rsi14 = rsi(closes, 14).last()
    val macdAll = macd(closes)
    val bb = bollinger(closes)
    val atr14 = atr(highs, lows, closes, 14).last()
    val stoch = stochastic(highs, lows, closes)
    val obvVal = obv(closes, volumes).last()
    val ich = ichimoku(highs, lows)
    return IndicatorSummary(
        close = closes.last(),
        sma20 = sma20,
        ema20 = ema20,
        rsi14 = rsi14,
        macd = macdAll.macd.last(),
        macdSignal = macdAll.signal.last(),
        macdHist = macdAll.hist.last(),
        bbUpper = bb.upper.last(),
        bbMid = bb.mid.last(),
        bbLower = bb.lower.last(),
        atr14 = atr14,
        stochK = stoch.k.last(),
        stochD = stoch.d.last(),
        obv = obvVal,
        tenkan = ich.tenkan.last(),
        kijun = ich.kijun.last()
    )
}
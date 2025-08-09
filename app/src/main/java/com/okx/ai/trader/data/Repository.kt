package com.okx.ai.trader.data

import com.okx.ai.trader.ai.GeminiClient
import com.okx.ai.trader.indicators.IndicatorSummary
import com.okx.ai.trader.indicators.computeSummaryFromSeries

class MarketRepository {
    suspend fun fetchKlines(symbol: String, bar: String, limit: Int = 300): List<Candle> {
        return OkxApiClient.market.getCandles(symbol, bar, limit).let { response ->
            if (response.code != "0") error("OKX API error ${response.code}: ${response.msg}")
            response.data.asReversed().map { row ->
                Candle(
                    timestampMs = row[0].toLong(),
                    open = row[1].toDouble(),
                    high = row[2].toDouble(),
                    low = row[3].toDouble(),
                    close = row[4].toDouble(),
                    volume = row[5].toDouble()
                )
            }
        }
    }

    fun computeIndicators(klines: List<Candle>): IndicatorSummary {
        val closes = klines.map { it.close }
        val highs = klines.map { it.high }
        val lows = klines.map { it.low }
        val volumes = klines.map { it.volume }
        return computeSummaryFromSeries(closes, highs, lows, volumes)
    }

    suspend fun generateAiAnalysis(symbol: String, timeframe: String, summary: IndicatorSummary): String {
        return GeminiClient.analyze(symbol, timeframe, summary)
    }
}
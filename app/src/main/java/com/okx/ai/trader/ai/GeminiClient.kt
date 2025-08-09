package com.okx.ai.trader.ai

import com.okx.ai.trader.BuildConfig
import com.okx.ai.trader.indicators.IndicatorSummary
import com.squareup.moshi.Json
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.logging.HttpLoggingInterceptor

private const val GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta/"

data class TextPart(@Json(name = "text") val text: String)

data class Content(@Json(name = "role") val role: String, @Json(name = "parts") val parts: List<TextPart>)

data class GenerateRequest(@Json(name = "contents") val contents: List<Content>)

data class CandidatePart(@Json(name = "text") val text: String?)

data class CandidateContent(@Json(name = "parts") val parts: List<CandidatePart>?)

data class Candidate(@Json(name = "content") val content: CandidateContent?)

data class GenerateResponse(@Json(name = "candidates") val candidates: List<Candidate>?)

object GeminiClient {
    private val moshi: Moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()
    private val json = "application/json; charset=utf-8".toMediaType()

    private val httpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC })
            .build()
    }

    fun buildPrompt(symbol: String, timeframe: String, summary: IndicatorSummary): String {
        return buildString {
            appendLine("You are Gemini 2.5 Flash, an expert crypto trading assistant. Analyze OKX market data and indicators to suggest trading insights. Return a concise analysis with: bias (bullish/bearish/range), key levels, momentum, volatility, risk note, and 2-3 actionable trade ideas with entry/SL/TP.")
            appendLine()
            appendLine("Context:")
            appendLine("Symbol: $symbol")
            appendLine("Timeframe: $timeframe")
            appendLine("Indicators:")
            appendLine(summary.toPrettyString())
            appendLine()
            appendLine("Constraints:")
            appendLine("- DO NOT provide financial advice; these are educational insights only.")
            appendLine("- Keep it under 250 words.")
            appendLine("- Include a JSON block at the end with fields: {\"bias\":string, \"entry\":number, \"stop\":number, \"takeProfit\":[number,number]}")
        }
    }

    suspend fun analyze(symbol: String, timeframe: String, summary: IndicatorSummary): String {
        val apiKey = BuildConfig.GEMINI_API_KEY
        if (apiKey.isBlank()) return "Gemini API key missing. Set GEMINI_API_KEY in local.properties or CI env."
        val model = BuildConfig.GEMINI_MODEL

        val prompt = buildPrompt(symbol, timeframe, summary)
        val adapterReq = moshi.adapter(GenerateRequest::class.java)
        val req = GenerateRequest(
            contents = listOf(Content(role = "user", parts = listOf(TextPart(text = prompt))))
        )
        val body = adapterReq.toJson(req).toRequestBody(json)

        val url = "${GEMINI_BASE}models/${model}:generateContent?key=$apiKey"
        val request = Request.Builder().url(url).post(body).build()
        httpClient.newCall(request).execute().use { resp ->
            if (!resp.isSuccessful) return "Gemini API error: ${resp.code} ${resp.message}"
            val txt = resp.body?.string() ?: return "Gemini API empty response"
            val adapterResp = moshi.adapter(GenerateResponse::class.java)
            val parsed = adapterResp.fromJson(txt)
            val text = parsed?.candidates?.firstOrNull()?.content?.parts?.firstOrNull()?.text
            return text ?: "No content returned from Gemini"
        }
    }
}
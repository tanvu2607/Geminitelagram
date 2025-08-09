package com.okx.ai.trader.data

import com.squareup.moshi.Json
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.GET
import retrofit2.http.Query

private const val OKX_BASE = "https://www.okx.com/"

interface OkxMarketService {
    // OKX API: GET /api/v5/market/candles?instId=BTC-USDT-SWAP&bar=1H&limit=100
    @GET("api/v5/market/candles")
    suspend fun getCandles(
        @Query("instId") instId: String,
        @Query("bar") bar: String? = null,
        @Query("limit") limit: Int? = null
    ): OkxApiResponse<List<List<String>>>
}

data class OkxApiResponse<T>(
    @Json(name = "code") val code: String,
    @Json(name = "msg") val msg: String?,
    @Json(name = "data") val data: T
)

// Candle fields per OKX docs: [ts, o, h, l, c, vol, volCcy, volCcyQuote, confirm]
// We'll map to a Kotlin data class for convenience

data class Candle(
    val timestampMs: Long,
    val open: Double,
    val high: Double,
    val low: Double,
    val close: Double,
    val volume: Double
)

object OkxApiClient {
    private val moshi: Moshi = Moshi.Builder()
        .add(KotlinJsonAdapterFactory())
        .build()

    private val httpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .addInterceptor(HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BASIC
            })
            .build()
    }

    private val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(OKX_BASE)
            .client(httpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    val market: OkxMarketService by lazy { retrofit.create(OkxMarketService::class.java) }
}
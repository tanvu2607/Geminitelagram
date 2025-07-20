// DEPENDENCIES: provider: ^6.1.2, technical_indicators: ^1.1.2, intl: ^0.19.0

import 'package:flutter/material.dart';
import 'package:okx_trade_assistant/models/analysis_result.dart';
import 'package:okx_trade_assistant/services/ai_analyzer_service.dart';
import 'package:okx_trade_assistant/services/okx_api_service.dart';
import 'package:technical_indicators/technical_indicators.dart';

class TradingProvider with ChangeNotifier {
  bool _isLoading = false;
  AnalysisResult? _analysisResult;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  AnalysisResult? get analysisResult => _analysisResult;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeSymbol(String symbol, String timeframe) async {
    _isLoading = true;
    _errorMessage = null;
    _analysisResult = null;
    notifyListeners();

    try {
      final okxApiService = OkxApiService();
      final candles = await okxApiService.fetchCandles(symbol, timeframe);

      //Extract close prices for technical indicators
      final closePrices = candles.map((e) => e[4].toDouble()).toList();

      final rsi = calculateRSI(closePrices, 14);
      final macd = calculateMACD(closePrices, 12, 26, 9);
      final ema20 = calculateEMA(closePrices, 20);
      final ema50 = calculateEMA(closePrices, 50);
      final sma200 = calculateSMA(closePrices, 200);

      final tradingData = {
        'symbol': symbol,
        'timeframe': timeframe,
        'candles': candles,
        'rsi': rsi,
        'macd': macd,
        'ema20': ema20,
        'ema50': ema50,
        'sma200': sma200,
      };

      final aiAnalyzerService = AiAnalyzerService();
      final analysis = await aiAnalyzerService.getAnalysis(tradingData);
      _analysisResult = AnalysisResult.fromJson(analysis);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
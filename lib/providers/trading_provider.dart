// DEPENDENCIES: provider: ^6.1.2, technical_indicators: ^1.1.2, intl: ^0.19.0
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  final OkxApiService _okxApiService = OkxApiService();
  final AiAnalyzerService _aiAnalyzerService = AiAnalyzerService();

  Future<void> analyzeSymbol(String symbol, String timeframe) async {
    _isLoading = true;
    _errorMessage = null;
    _analysisResult = null;
    notifyListeners();

    try {
      final candles = await _okxApiService.fetchCandles(symbol, timeframe);
      final formattedCandles = candles.map((e) => [e[0], e[1].toDouble(), e[2].toDouble(), e[3].toDouble(), e[4].toDouble()]).toList();

      final rsi = calculateRsi(formattedCandles, 14);
      final macd = calculateMacd(formattedCandles, 12, 26, 9);
      final ema20 = calculateEma(formattedCandles, 20);
      final ema50 = calculateEma(formattedCandles, 50);
      final sma200 = calculateSma(formattedCandles, 200);

      final tradingData = {
        'symbol': symbol,
        'timeframe': timeframe,
        'rsi': rsi.map((e) => e!.toDouble()).toList(),
        'macd': macd.map((e) => e!.toDouble()).toList(),
        'ema20': ema20.map((e) => e!.toDouble()).toList(),
        'ema50': ema50.map((e) => e!.toDouble()).toList(),
        'sma200': sma200.map((e) => e!.toDouble()).toList(),
        'candles': formattedCandles,
      };

      final analysis = await _aiAnalyzerService.getAnalysis(tradingData);
      _analysisResult = AnalysisResult.fromJson(analysis);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

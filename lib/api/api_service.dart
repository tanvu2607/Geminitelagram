import 'dart:convert';
import 'package:ai_trading_assistant/models/analysis_result.dart';
import 'package:http/http.dart' as http;

class ApiService {
  Future<AnalysisResult> fetchAnalysis(String symbol, String timeframe) async {
    final url = Uri.parse('https://your-backend-api.com/analyze');
    final response = await http.post(url, body: {'symbol': symbol, 'timeframe': timeframe});

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return AnalysisResult.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to fetch analysis');
    }
  }
}
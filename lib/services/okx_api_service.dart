import 'dart:convert';
import 'package:http/http.dart' as http;

class OkxApiService {
  Future<List<dynamic>> fetchCandles(String symbol, String timeframe) async {
    final url = Uri.parse('https://www.okx.com/api/v5/market/candles');
    final response = await http.get(url, parameters: {
      'instId': symbol,
      'bar': timeframe,
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['data'];
    } else {
      throw Exception('Failed to load candles: ${response.statusCode}');
    }
  }
}
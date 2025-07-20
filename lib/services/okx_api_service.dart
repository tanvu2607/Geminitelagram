// DEPENDENCIES: http: ^1.2.1
import 'dart:convert';
import 'package:http/http.dart' as http;

class OkxApiService {
  Future<List<dynamic>> fetchCandles(String symbol, String timeframe) async {
    final url = Uri.parse('https://www.okx.com/api/v5/market/candles');
    final response = await http.get(url,
        headers: {
          'Content-Type': 'application/json',
        },
        params: {
          'instId': symbol,
          'bar': timeframe,
        });

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return jsonData['data'];
    } else {
      throw Exception('Failed to load OKX candles');
    }
  }
}

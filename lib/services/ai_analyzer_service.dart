import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAnalyzerService {
  final String geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Replace with your actual API key

  Future<Map<String, dynamic>> getAnalysis(Map<String, dynamic> tradingData) async {
    final url = Uri.parse('YOUR_GEMINI_API_ENDPOINT'); // Replace with your Gemini API endpoint
    final body = {
      'prompt': 'Analyze the following trading data and provide insights including buy/sell recommendations: $tradingData',
      'api_key': geminiApiKey,
    };
    final response = await http.post(url, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get analysis: ${response.statusCode}');
    }
  }
}
// DEPENDENCIES: http: ^1.2.1
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAnalyzerService {
  final String geminiApiKey = 'YOUR_GEMINI_API_KEY'; // Replace with your actual key

  Future<Map<String, dynamic>> getAnalysis(Map<String, dynamic> tradingData) async {
    final url = Uri.parse('YOUR_GEMINI_API_ENDPOINT'); // Replace with your Gemini API endpoint
    final prompt = '''Analyze the following trading data and provide insights:

${jsonEncode(tradingData)}

Provide a JSON response with keys such as 'summary', 'suggestions'.  Be concise and specific.''';

    final response = await http.post(url, body: {'prompt': prompt, 'key': geminiApiKey});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get analysis from Gemini API');
    }
  }
}

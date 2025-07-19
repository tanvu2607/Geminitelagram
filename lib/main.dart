// DEPENDENCIES: http: ^1.2.1
// DEPENDENCIES: technical_indicators: ^1.1.2
// DEPENDENCIES: google_generative_ai: ^0.4.0
// DEPENDENCIES: flutter_dotenv: ^5.1.0
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:technical_indicators/technical_indicators.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Trading Assistant',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'AI Trading Assistant'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _symbolController = TextEditingController();
  final _intervalController = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  Future<void> _analyzeData() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });
    String symbol = _symbolController.text;
    String interval = _intervalController.text;

    try {
      final binanceUrl = Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=50');
      final response = await http.get(binanceUrl);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        List<Candle> candles = [];
        for (var candleData in jsonData) {
          candles.add(Candle(
              open: candleData[1].toDouble(),
              high: candleData[2].toDouble(),
              low: candleData[3].toDouble(),
              close: candleData[4].toDouble(),
              volume: candleData[5].toDouble()));
        }
        // Calculate indicators (example RSI)
        final rsi = calculateRsi(candles, 14);
        final macd = calculateMacd(candles, 12, 26, 9);


        Map<String, dynamic> data = {
          'symbol': symbol,
          'interval': interval,
          'rsi': rsi.last.toDouble(),
          'macd': macd.last.toDouble()
        };

        final client = GenerativeAIClient(apiKey: dotenv.env['GEMINI_API_KEY']!);
        final response = await client.generateText(prompt: 'Analyze this trading data: ${jsonEncode(data)}');
        setState(() {
          _result = response.text;
        });
      } else {
        setState(() {
          _result = 'Failed to fetch data from Binance.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(labelText: 'Cặp giao dịch (e.g., BTCUSDT)'),
            ),
            TextField(
              controller: _intervalController,
              decoration: const InputDecoration(labelText: 'Khung thời gian (e.g., 1m, 1h, 1d)'),
            ),
            ElevatedButton(
              onPressed: _analyzeData,
              child: const Text('Phân Tích'),
            ),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_result),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _intervalController.dispose();
    super.dispose();
  }
}
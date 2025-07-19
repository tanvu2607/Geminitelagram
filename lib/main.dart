// DEPENDENCIES: http: ^1.2.1
// DEPENDENCIES: provider: ^6.0.5
// DEPENDENCIES: chart_flutter: ^0.14.0


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:chart_flutter/chart_flutter.dart';


class MarketData {
  final double price;
  final double volume;
  // Add other relevant market data fields as needed

  MarketData({required this.price, required this.volume});

  factory MarketData.fromJson(Map<String, dynamic> json) {
    return MarketData(
      price: json['price'].toDouble(),
      volume: json['volume'].toDouble(),
    );
  }
}

class GeminiAnalysis {
  final String suggestion;
  // Add other analysis fields

  GeminiAnalysis({required this.suggestion});

  factory GeminiAnalysis.fromJson(Map<String, dynamic> json){
    return GeminiAnalysis(suggestion: json['suggestion']);
  }
}


class MarketDataProvider with ChangeNotifier {
  MarketData? _marketData;
  GeminiAnalysis? _geminiAnalysis;
  List<MarketData> _historicalData = [];

  MarketData? get marketData => _marketData;
  GeminiAnalysis? get geminiAnalysis => _geminiAnalysis;
  List<MarketData> get historicalData => _historicalData;

  Future<void> fetchMarketData() async {
    final response = await http.get(Uri.parse('YOUR_MARKET_DATA_API_ENDPOINT')); // Replace with your API endpoint
    if (response.statusCode == 200) {
      _marketData = MarketData.fromJson(jsonDecode(response.body));
      notifyListeners();
    } else {
      // Handle error
      print('Error fetching market data');
    }
  }

  Future<void> fetchHistoricalData() async {
      final response = await http.get(Uri.parse('YOUR_HISTORICAL_DATA_API_ENDPOINT')); // Replace with your API endpoint
      if(response.statusCode == 200){
        final data = jsonDecode(response.body);
        _historicalData = (data as List).map((e) => MarketData.fromJson(e)).toList();
        notifyListeners();
      } else {
        print('Error fetching historical data');
      }
  }

  Future<void> sendToGemini() async {
    if (_marketData != null) {
      final body = jsonEncode({'price': _marketData!.price, 'volume': _marketData!.volume}); // Add other relevant data

      final response = await http.post(Uri.parse('YOUR_GEMINI_API_ENDPOINT'), // Replace with your Gemini API endpoint
          headers: {'Content-Type': 'application/json'},
          body: body);

      if (response.statusCode == 200) {
        _geminiAnalysis = GeminiAnalysis.fromJson(jsonDecode(response.body));
        notifyListeners();
      } else {
        // Handle error
        print('Error sending data to Gemini');
      }
    }
  }
}


void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => MarketDataProvider(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Analysis App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Gemini Analysis'),
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
  @override
  void initState() {
    super.initState();
    Provider.of<MarketDataProvider>(context, listen: false).fetchMarketData();
    Provider.of<MarketDataProvider>(context, listen: false).fetchHistoricalData();
  }

  @override
  Widget build(BuildContext context) {
    final marketDataProvider = Provider.of<MarketDataProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Price: ${marketDataProvider.marketData?.price ?? 'Loading...'}'),
            Text('Volume: ${marketDataProvider.marketData?.volume ?? 'Loading...'}'),
            ElevatedButton(onPressed: () async {
              await marketDataProvider.sendToGemini();
            }, child: Text('Send to Gemini')),
            if (marketDataProvider.geminiAnalysis != null)
              Text('Gemini Suggestion: ${marketDataProvider.geminiAnalysis!.suggestion}'),
            SizedBox(height: 20,),
            Expanded(
              child: LineChart(
                data: [
                  for(final item in marketDataProvider.historicalData)
                  ChartData(item.price.toDouble(), item.volume.toDouble()),
                ],
                width: double.infinity,
                height: 300,
                isInteractive: true,
              ),
            ),

          ],
        ),
      ),
    );
  }
}
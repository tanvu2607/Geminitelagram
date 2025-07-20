// DEPENDENCIES: provider: ^6.1.2, intl: ^0.19.0
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:okx_trade_assistant/providers/trading_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _symbolController = TextEditingController(text: 'BTC-USDT-SWAP');
  String selectedTimeframe = '4H';
  final List<String> timeframes = ['1H', '4H', '1D'];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TradingProvider>(context);
    final nf = NumberFormat.decimalPattern(Intl.systemLocale);
    return Scaffold(
      appBar: AppBar(
        title: const Text('OKX Future Assistant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
          [
            TextField(
              controller: _symbolController,
              decoration: const InputDecoration(hintText: 'Symbol (e.g., BTC-USDT-SWAP)'),
            ),
            DropdownButton<String>(value: selectedTimeframe, items: timeframes.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(), onChanged: (String? newValue) {
              setState(() {
                selectedTimeframe = newValue! ;
              });
            }),
            ElevatedButton(
              onPressed: () => provider.analyzeSymbol(_symbolController.text, selectedTimeframe),
              child: const Text('Phân Tích'),
            ),
            if (provider.isLoading)
              const CircularProgressIndicator()
            else if (provider.errorMessage != null)
              Text('Error: ${provider.errorMessage!}')
            else if (provider.analysisResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary: ${provider.analysisResult!.summary.overallSentiment}'),
                      for (final suggestion in provider.analysisResult!.suggestions)
                        Text('Suggestion: ${suggestion.action} at ${nf.format(suggestion.entryPrice)} TP: ${nf.format(suggestion.takeProfit)} SL: ${nf.format(suggestion.stopLoss)}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

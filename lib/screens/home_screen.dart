import 'package:flutter/material.dart';
import 'package:okx_trade_assistant/providers/trading_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _symbolController = TextEditingController(text: 'BTC-USDT-SWAP');
  String _selectedTimeframe = '4H';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OKX Future Assistant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<TradingProvider>(builder: (context, provider, child) {
          return Column(
            children: [
              TextField(
                controller: _symbolController,
                decoration: const InputDecoration(labelText: 'Symbol'),
              ),
              DropdownButton<String>(value: _selectedTimeframe,
                  items: ['1H', '4H', '1D'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
                  onChanged: (String? newValue) {
                setState(() {
                  _selectedTimeframe = newValue!; // ignore: avoid_print
                });
              }),
              ElevatedButton(
                  onPressed: () async {
                    await provider.analyzeSymbol(_symbolController.text, _selectedTimeframe);
                  },
                  child: const Text('Phân Tích')
              ),
              if (provider.isLoading)
                const CircularProgressIndicator()
              else if (provider.errorMessage != null)
                Text(provider.errorMessage!, style: const TextStyle(color: Colors.red))
              else if (provider.analysisResult != null)
                _buildAnalysisResult(provider.analysisResult!)
              else
                const Text('Chưa có dữ liệu')
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAnalysisResult(AnalysisResult result) {
    return Column(
      children: [
        Text('Overall Sentiment: ${result.summary.overallSentiment}'),
        ...result.suggestions.map((suggestion) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Action: ${suggestion.action}'),
                  Text('Entry Price: ${suggestion.entryPrice}'),
                  Text('Stop Loss: ${suggestion.stopLoss}'),
                  Text('Take Profit: ${suggestion.takeProfit}'),
                ],
              ),
            ),
          );
        }).toList()
      ],
    );
  }
}

// DEPENDENCIES: provider: ^6.1.2

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:okx_trade_assistant/providers/trading_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _symbolController = TextEditingController(text: 'BTC-USDT-SWAP');
  String _selectedTimeframe = '4H';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OKX Future Assistant'),
      ),
      body: Consumer<TradingProvider>(builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _symbolController,
                decoration: const InputDecoration(labelText: 'Symbol'),
              ),
              DropdownButton<String>( 
                value: _selectedTimeframe,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTimeframe = newValue!;
                  });
                },
                items: <String>['1H', '4H', '1D'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
              ),
              ElevatedButton(
                onPressed: () => provider.analyzeSymbol(_symbolController.text, _selectedTimeframe),
                child: const Text('Phân Tích'),
              ),
              if (provider.isLoading)
                const CircularProgressIndicator()
              else if (provider.errorMessage != null)
                Text('Error: ${provider.errorMessage}'),
              if (provider.analysisResult != null)
                Card(
                  child: Text('Analysis Result: ${provider.analysisResult.toString()}'),
                ),
            ],
          ),
        );
      }),
    );
  }
}

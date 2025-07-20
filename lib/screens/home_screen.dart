import 'package:ai_trading_assistant/api/api_service.dart';
import 'package:ai_trading_assistant/models/analysis_result.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _timeframeController = TextEditingController();
  AnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _symbolController.dispose();
    _timeframeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final apiService = ApiService();
        _analysisResult = await apiService.fetchAnalysis(_symbolController.text, _timeframeController.text);
        setState(() => _error = null);
      } catch (e) {
        setState(() => _error = e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trading Assistant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(labelText: 'Symbol'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a symbol' : null,
              ),
              TextFormField(
                controller: _timeframeController,
                decoration: const InputDecoration(labelText: 'Timeframe'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a timeframe' : null,
              ),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Analyze'),
              ),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_analysisResult != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Symbol: ${_analysisResult!.analysisSummary.symbol}'),
                        Text('RSI Analysis: ${_analysisResult!.analysisSummary.rsiAnalysis}'),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text('Decision: ${_analysisResult!.tradeSuggestion.decision}'),
                        Text('Reasoning: ${_analysisResult!.tradeSuggestion.reasoning}'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

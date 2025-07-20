class AnalysisResult {
  final AnalysisSummary summary;
  final List<TradeSuggestion> suggestions;

  AnalysisResult({required this.summary, required this.suggestions});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      summary: AnalysisSummary.fromJson(json['summary']),
      suggestions: List<TradeSuggestion>.from(
          json['suggestions'].map((x) => TradeSuggestion.fromJson(x))),
    );
  }
}

class AnalysisSummary {
  final String overallSentiment;
  AnalysisSummary({required this.overallSentiment});
  factory AnalysisSummary.fromJson(Map<String, dynamic> json) => AnalysisSummary(
        overallSentiment: json['overallSentiment'],
      );
}

class TradeSuggestion {
  final String action; //e.g., 'buy', 'sell', 'hold'
  final double entryPrice; //optional
  final double takeProfit;
  final double stopLoss;

  TradeSuggestion({
    required this.action,
    required this.takeProfit,
    required this.stopLoss,
    this.entryPrice = 0.0,
  });

  factory TradeSuggestion.fromJson(Map<String, dynamic> json) => TradeSuggestion(
        action: json['action'],
        entryPrice: json['entryPrice']?.toDouble() ?? 0.0,
        takeProfit: json['takeProfit']?.toDouble() ?? 0.0,
        stopLoss: json['stopLoss']?.toDouble() ?? 0.0,
      );
}

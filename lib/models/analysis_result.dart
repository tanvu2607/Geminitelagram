class AnalysisResult {
  final AnalysisSummary summary;
  final List<TradeSuggestion> suggestions;

  AnalysisResult({required this.summary, required this.suggestions});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      summary: AnalysisSummary.fromJson(json['summary']),
      suggestions: List<TradeSuggestion>.from(json['suggestions']
              .map((x) => TradeSuggestion.fromJson(x)))
          .toList(),
    );
  }
}

class AnalysisSummary {
  final String overallSentiment;

  AnalysisSummary({required this.overallSentiment});

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(overallSentiment: json['overallSentiment']);
  }
}

class TradeSuggestion {
  final String action;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;

  TradeSuggestion(
      {required this.action, required this.entryPrice, required this.stopLoss, required this.takeProfit});

  factory TradeSuggestion.fromJson(Map<String, dynamic> json) {
    return TradeSuggestion(
        action: json['action'],
        entryPrice: json['entryPrice'].toDouble(),
        stopLoss: json['stopLoss'].toDouble(),
        takeProfit: json['takeProfit'].toDouble());
  }
}
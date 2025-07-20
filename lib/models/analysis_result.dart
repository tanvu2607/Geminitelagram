class AnalysisResult {
  final AnalysisSummary summary;
  final List<TradeSuggestion> suggestions;

  AnalysisResult({required this.summary, required this.suggestions});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      summary: AnalysisSummary.fromJson(json['summary']),
      suggestions: List<TradeSuggestion>.from(json['suggestions']
              .map((x) => TradeSuggestion.fromJson(x)) ??
          []),
    );
  }
}

class AnalysisSummary {
  final String overallTrend;
  // Add other relevant fields
  AnalysisSummary({required this.overallTrend});

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) =>
      AnalysisSummary(overallTrend: json['overallTrend']);
}

class TradeSuggestion {
  final String action;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;
  // Add other relevant fields
  TradeSuggestion({
    required this.action,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
  });

  factory TradeSuggestion.fromJson(Map<String, dynamic> json) => TradeSuggestion(
        action: json['action'],
        entryPrice: json['entryPrice']?.toDouble(),
        stopLoss: json['stopLoss']?.toDouble(),
        takeProfit: json['takeProfit']?.toDouble(),
      );
}
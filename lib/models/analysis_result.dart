class AnalysisResult {
  final AnalysisSummary analysisSummary;
  final TradeSuggestion tradeSuggestion;

  AnalysisResult({required this.analysisSummary, required this.tradeSuggestion});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      analysisSummary: AnalysisSummary.fromJson(json['analysis_summary']),
      tradeSuggestion: TradeSuggestion.fromJson(json['trade_suggestion']),
    );
  }
}

class AnalysisSummary {
  final String symbol;
  final String rsiAnalysis;

  AnalysisSummary({required this.symbol, required this.rsiAnalysis});

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      symbol: json['symbol'],
      rsiAnalysis: json['rsi_analysis'],
    );
  }
}

class TradeSuggestion {
  final String decision;
  final String reasoning;

  TradeSuggestion({required this.decision, required this.reasoning});

  factory TradeSuggestion.fromJson(Map<String, dynamic> json) {
    return TradeSuggestion(
      decision: json['decision'],
      reasoning: json['reasoning'],
    );
  }
}
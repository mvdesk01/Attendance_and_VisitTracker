import '../../../domain/enteties/decision.dart';

class DecisionState {
  final bool isLoading;
  final List<Decision> decisions;
  final Decision? selectedDecision;
  final String? error;

  const DecisionState({
    this.isLoading = false,
    this.decisions = const [],
    this.selectedDecision,
    this.error,
  });

  DecisionState copyWith({
    bool? isLoading,
    List<Decision>? decisions,
    Decision? selectedDecision,
    String? error,
  }) {
    return DecisionState(
      isLoading: isLoading ?? this.isLoading,
      decisions: decisions ?? this.decisions,
      selectedDecision: selectedDecision ?? this.selectedDecision,
      error: error,
    );
  }
}

///test

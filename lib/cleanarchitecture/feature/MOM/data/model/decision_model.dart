import '../../domain/enteties/decision.dart';

class DecisionModel extends Decision {
  const DecisionModel({
    required super.decisionCode,
    required super.decisionName,
  });

  factory DecisionModel.fromJson(Map<String, dynamic> json) {
    return DecisionModel(
      decisionCode: json["DecisionCode"] ?? "",
      decisionName: json["DecisionName"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "DecisionCode": decisionCode,
      "DecisionName": decisionName,
    };
  }

  factory DecisionModel.fromEntity(Decision decision) {
    return DecisionModel(
      decisionCode: decision.decisionCode,
      decisionName: decision.decisionName,
    );
  }
}

import '../../domain/enteties/meetingpoints.dart';

///test
class DiscussionPointRequestModel extends DiscussionPoint {
  const DiscussionPointRequestModel({
    required super.point,
    required super.discussedWith,
    required super.decisionCode,
    required super.decision,
    required super.responsibilityCodes,
    required super.responsibilityNames,
    required super.targetDate,
    required super.entryBy,
    required super.flag,
    required super.last,
  });

  factory DiscussionPointRequestModel.fromEntity(DiscussionPoint point) {
    return DiscussionPointRequestModel(
      point: point.point,
      discussedWith: point.discussedWith,
      decisionCode: point.decisionCode,
      decision: point.decision,
      responsibilityCodes: point.responsibilityCodes,
      responsibilityNames: point.responsibilityNames,
      targetDate: point.targetDate,
      entryBy: point.entryBy,
      flag: point.flag,
      last: point.last,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Points": point,
      "DiscussedWith": discussedWith,
      "DecisionCode": decisionCode,
      "Decision": decision,
      "Responsibility": responsibilityCodes,
      "TargetDate": targetDate,
      "EntryBy": entryBy,
      "Flag": flag,
      "Last": last,
    };
  }
}

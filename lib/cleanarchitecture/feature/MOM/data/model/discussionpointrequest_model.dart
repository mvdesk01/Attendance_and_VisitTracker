import '../../domain/enteties/meetingpoints.dart';

///test
class DiscussionPointRequestModel extends DiscussionPoint {
  const DiscussionPointRequestModel({
    required super.point,
    required super.discussedWith,
    required super.decisionCode,
    required super.responsibilityCodes,
    required super.responsibilityNames,
    required super.targetDate,
    required super.entryBy,
    required super.flag,
  });

  factory DiscussionPointRequestModel.fromEntity(DiscussionPoint point) {
    return DiscussionPointRequestModel(
      point: point.point,
      discussedWith: point.discussedWith,
      decisionCode: point.decisionCode,
      responsibilityCodes: point.responsibilityCodes,
      responsibilityNames: point.responsibilityNames,
      targetDate: point.targetDate,
      entryBy: point.entryBy,
      flag: point.flag,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "Points": point,
      "DiscussedWith": discussedWith,
      "Decision": decisionCode,
      "Responsibility": responsibilityCodes,
      "TargetDate": targetDate,
      "EntryBy": entryBy,
      "Flag": flag,
    };
  }
}

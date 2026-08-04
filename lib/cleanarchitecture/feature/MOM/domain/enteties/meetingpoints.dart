class DiscussionPoint {
  final String point;
  final String discussedWith;
  final String decisionCode;

  /// comma separated codes
  final String responsibilityCodes;

  /// comma separated names
  final String responsibilityNames;

  final String targetDate;
  final String entryBy;
  final String flag;

  const DiscussionPoint({
    required this.point,
    required this.discussedWith,
    required this.decisionCode,
    required this.responsibilityCodes,
    required this.responsibilityNames,
    required this.targetDate,
    required this.entryBy,
    required this.flag,
  });
}

///test

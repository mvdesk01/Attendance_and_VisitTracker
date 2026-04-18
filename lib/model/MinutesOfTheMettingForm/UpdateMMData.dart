class UpdateMMData {
  String srNo;
  String pointsOrIssues;
  String discussedWith;
  String decisionTaken;
  String responsibility;
  String targetDate;
  String statusOrRemark;
  String? nextDate;
  String visitSrNo;

  UpdateMMData({
    required this.srNo,
    required this.pointsOrIssues,
    required this.discussedWith,
    required this.decisionTaken,
    required this.responsibility,
    required this.targetDate,
    required this.statusOrRemark,
    required this.nextDate,
    required this.visitSrNo,
  });

  factory UpdateMMData.fromJson(Map<String, dynamic> json) {
    return UpdateMMData(
      srNo: json['srNo'] ?? '',
      pointsOrIssues: json['pointsOrIssues'] ?? '',
      discussedWith: json['discussedWith'] ?? '',
      decisionTaken: json['decisionTaken'] ?? '',
      responsibility: json['responsibility'] ?? '',
      targetDate: json['targetDate'] ?? '',
      statusOrRemark: json['statusOrRemark'] ?? '',
      nextDate: json['nextDate'] ?? '',
      visitSrNo: json['visitSrNo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srNo': srNo,
      'pointsOrIssues': pointsOrIssues,
      'discussedWith': discussedWith,
      'decisionTaken': decisionTaken,
      'responsibility': responsibility,
      'targetDate': targetDate,
      'statusOrRemark': statusOrRemark,
      'nextDate': nextDate,
      'visitSrNo': visitSrNo,
    };
  }
}

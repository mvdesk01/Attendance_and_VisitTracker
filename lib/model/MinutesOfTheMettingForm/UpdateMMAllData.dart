class UpdateMMAllData {
  String srNo;
  String date;
  String time;
  String subject;
  String memberPresent;
  String memberAbsent;
  String allRecordsIds;
  String visitSrNo;
  String custCode;

  UpdateMMAllData({
    required this.srNo,
    required this.date,
    required this.time,
    required this.subject,
    required this.memberPresent,
    required this.memberAbsent,
    required this.allRecordsIds,
    required this.visitSrNo,
    required this.custCode,
  });

  factory UpdateMMAllData.fromJson(Map<String, dynamic> json) {
    return UpdateMMAllData(
        srNo: json['srNo'] ?? '',
        date: json['date'] ?? '',
        time: json['time'] ?? '',
        subject: json['subject'] ?? '',
        memberPresent: json['memberPresent'] ?? '',
        memberAbsent: json['memberAbsent'] ?? '',
        allRecordsIds: json['allRecordsIds'] ?? '',
        visitSrNo: json['visitSrNo'] ?? '',
        custCode: json['custCode'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'srNo': srNo,
      'date': date,
      'time': time,
      'subject': subject,
      'memberPresent': memberPresent,
      'memberAbsent': memberAbsent,
      'allRecordsIds': allRecordsIds,
      'visitSrNo': visitSrNo,
      'custCode': custCode
    };
  }
}

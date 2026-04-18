class LeaveCancelRequest {
  final String status;
  final String staffcode;
  final String name;
  final String startDate;
  final String endDate;
  final String leaveType;
  final String days;
  late final String reason;
  final String transactionid;

  LeaveCancelRequest({
    required this.status,
    required this.staffcode,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.days,
    required this.reason,
    required this.transactionid,
  });

  factory LeaveCancelRequest.fromJson(Map<String, dynamic> json) {
    return LeaveCancelRequest(
      status: json['status'] as String,
      staffcode: json['staffcode'] as String,
      name: json['name'] as String,
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      leaveType: json['leaveType'] as String,
      days: json['days'] as String,
      reason: json['reason'] as String,
      transactionid: json['transactionid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'staffcode': staffcode,
      'name': name,
      'startDate': startDate,
      'endDate': endDate,
      'leaveType': leaveType,
      'days': days,
      'reason': reason,
      'transactionid': transactionid,
    };
  }
}

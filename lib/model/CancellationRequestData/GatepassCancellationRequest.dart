class GatepassCancelRequest {
  final String status;
  final String staffcode;
  final String name;
  final String date;
  final String fromtime;
  final String totime;
  final String type;
  late final String reason;
  final String transactionId;

  GatepassCancelRequest({
    required this.status,
    required this.staffcode,
    required this.name,
    required this.date,
    required this.fromtime,
    required this.totime,
    required this.type,
    required this.reason,
    required this.transactionId,
  });

  factory GatepassCancelRequest.fromJson(Map<String, dynamic> json) {
    return GatepassCancelRequest(
      status: json['status'] as String,
      staffcode: json['staffcode'] as String,
      name: json['name'] as String,
      date: json['date'] as String,
      fromtime: json['fromtime'] as String,
      totime: json['totime'] as String,
      type: json['type'] as String,
      reason: json['reason'] as String,
      transactionId: json['transactionId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'staffcode': staffcode,
      'name': name,
      'date': date,
      'fromtime': fromtime,
      'totime': totime,
      'type': type,
      'reason': reason,
      'transactionId': transactionId,
    };
  }
}

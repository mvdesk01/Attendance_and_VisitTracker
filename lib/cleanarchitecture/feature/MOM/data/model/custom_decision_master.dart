class DecisionMasterRequest {
  final String decisionCode;
  final String decisionName;
  final String status;
  final String entryBy;

  const DecisionMasterRequest({
    required this.decisionCode,
    required this.decisionName,
    required this.status,
    required this.entryBy,
  });

  factory DecisionMasterRequest.fromEntity(
      String decisionName,
      String entryBy,
      ) {
    return DecisionMasterRequest(
      decisionCode: "0",
      decisionName: decisionName,
      status: "Y",
      entryBy: entryBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "DecisionCode": decisionCode,
      "DecisionName": decisionName,
      "Status": status,
      "EntryBy": entryBy,
    };
  }
}

class DecisionMasterResponse {
  final String outMsg;

  const DecisionMasterResponse({
    required this.outMsg,
  });

  factory DecisionMasterResponse.fromJson(Map<String, dynamic> json) {
    return DecisionMasterResponse(
      outMsg: json['OutMsg']?.toString() ?? '',
    );
  }
}
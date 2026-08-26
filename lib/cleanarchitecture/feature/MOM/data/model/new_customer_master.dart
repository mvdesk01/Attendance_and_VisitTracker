class CustomerMasterRequest {
  final String customername;
  final String contactperson;
  final String address;
  final String mobileno;
  final String emailid;
  final String entryby;
  final String flag;

  const CustomerMasterRequest(
      {required this.customername,
      required this.contactperson,
      required this.address,
      required this.mobileno,
      required this.emailid,
      required this.entryby,
      required this.flag});

  Map<String, dynamic> toJson() {
    return {
      "CustomerName": customername,
      "ContactPerson": contactperson,
      "Address": address,
      "MobileNo": mobileno,
      "EmailID": emailid,
      "EntryBy": entryby,
      "Flag": flag,
    };
  }
}

class CustomerMasterResponse {
  final String outMsg;

  const CustomerMasterResponse({
    required this.outMsg,
  });

  factory CustomerMasterResponse.fromJson(Map<String, dynamic> json) {
    return CustomerMasterResponse(
      outMsg: json["OutMsg"]?.toString() ?? "",
    );
  }
}

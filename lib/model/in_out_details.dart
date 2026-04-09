class InOutDetail {
  String? staffCode;
  String? transactionTime;
  String? inOut;
  String? address;

  InOutDetail({
    this.staffCode,
    this.transactionTime,
    this.inOut,
    this.address,
  });

  InOutDetail.fromJson(Map<String, dynamic> json) {
    staffCode = json['staffCode'];
    transactionTime = json['transactionTime'];
    inOut = json['inOut'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    return {
      'staffCode': staffCode,
      'transactionTime': transactionTime,
      'inOut': inOut,
      'address': address,
    };
  }
}


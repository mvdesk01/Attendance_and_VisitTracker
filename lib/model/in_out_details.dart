class InOutDetail {
  String? staffCode;
  String? transactionTime;
  String? inOut;
  String? address;

  InOutDetail({this.staffCode, this.transactionTime, this.inOut, this.address});

  InOutDetail.fromJson(Map<String, dynamic> json) {
    staffCode = json['StaffCode'];
    transactionTime = json['TransactionTime'];
    inOut = json['InOut'];
    address = json['Address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['StaffCode'] = this.staffCode;
    data['TransactionTime'] = this.transactionTime;
    data['InOut'] = this.inOut;
    data['Address'] = this.address;
    return data;
  }
}

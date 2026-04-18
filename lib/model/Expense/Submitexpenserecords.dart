import 'dart:convert';


class ExpenseModel {
  String todayDate;
  String staffCode;
  String staffName;
  String visitLocation;
  String visitPurpose;
  String flagValue;
  String advanceTaken;
  String calculateExpense;
  String balanceAmount;
  String expenditureDate;
  String amount;
  String expenditureDetails;
  String document;

  ExpenseModel({
    required this.todayDate,
    required this.staffCode,
    required this.staffName,
    required this.visitLocation,
    required this.visitPurpose,
    required this.flagValue,
    required this.advanceTaken,
    required this.calculateExpense,
    required this.balanceAmount,
    required this.expenditureDate,
    required this.amount,
    required this.expenditureDetails,
    required this.document,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      todayDate: json['todayDate'] ?? '',
      staffCode: json['staffCode'] ?? '',
      staffName: json['staffName'] ?? '',
      visitLocation: json['visitLocation'] ?? '',
      visitPurpose: json['visitPurpose'] ?? '',
      flagValue: json['flagValue'] ?? '',
      advanceTaken: json['advanceTaken'] ?? '',
      calculateExpense: json['calculateExpense'] ?? '',
      balanceAmount: json['balanceAmount'] ?? '',
      expenditureDate: json['expenditureDate'] ?? '',
      amount: json['amount'] ?? '',
      expenditureDetails: json['expenditureDetails'] ?? '',
      document: json['document'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'todayDate': todayDate,
      'staffCode': staffCode,
      'staffName': staffName,
      'visitLocation': visitLocation,
      'visitPurpose': visitPurpose,
      'flagValue': flagValue,
      'advanceTaken': advanceTaken,
      'calculateExpense': calculateExpense,
      'balanceAmount': balanceAmount,
      'expenditureDate': expenditureDate,
      'amount': amount,
      'expenditureDetails': expenditureDetails,
      'document': document,
    };
  }
}


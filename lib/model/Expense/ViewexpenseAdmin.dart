class ViewExpenseModel {
  ExpenditureDetails? expenditureDetails;
  FinancialDetails? financialDetails;

  ViewExpenseModel({
    this.expenditureDetails,
    this.financialDetails,
  });

  factory ViewExpenseModel.fromJson(Map<String, dynamic> json) {
    return ViewExpenseModel(
      expenditureDetails: json['expenditureDetails'] != null
          ? ExpenditureDetails.fromJson(json['expenditureDetails'])
          : null,
      financialDetails: json['financialDetails'] != null
          ? FinancialDetails.fromJson(json['financialDetails'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenditureDetails': expenditureDetails?.toJson(),
      'financialDetails': financialDetails?.toJson(),
    };
  }
}

class ExpenditureDetails {
  int? id;
  String? todayDate;
  String? staffCode;
  String? staffName;
  String? visitLocation;
  String? visitPurpose;
  String? flagValue;
  num? advanceTaken;
  num? calculatedExpense;
  num? balanceAmount;

  ExpenditureDetails({
    this.id,
    this.todayDate,
    this.staffCode,
    this.staffName,
    this.visitLocation,
    this.visitPurpose,
    this.flagValue,
    this.advanceTaken,
    this.calculatedExpense,
    this.balanceAmount,
  });

  factory ExpenditureDetails.fromJson(Map<String, dynamic> json) {
    return ExpenditureDetails(
      id: json['id'],
      todayDate: json['todayDate'],
      staffCode: json['staffCode'],
      staffName: json['staffName'],
      visitLocation: json['visitLocation'],
      visitPurpose: json['visitPurpose'],
      flagValue: json['flagValue'],
      advanceTaken: json['advanceTaken'] as num?,
      calculatedExpense: json['calculatedExpense'] as num?,
      balanceAmount: json['balanceAmount'] as num?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todayDate': todayDate,
      'staffCode': staffCode,
      'staffName': staffName,
      'visitLocation': visitLocation,
      'visitPurpose': visitPurpose,
      'flagValue': flagValue,
      'advanceTaken': advanceTaken,
      'calculatedExpense': calculatedExpense,
      'balanceAmount': balanceAmount,
    };
  }
}

class FinancialDetails {
  int? srNo;
  int? expenditureId;
  String? expenditureDate;
  String? expenditureDetails;
  num? amount;
  String? document;

  FinancialDetails({
    this.srNo,
    this.expenditureId,
    this.expenditureDate,
    this.expenditureDetails,
    this.amount,
    this.document,
  });

  factory FinancialDetails.fromJson(Map<String, dynamic> json) {
    return FinancialDetails(
      srNo: json['srNo'],
      expenditureId: json['expenditureId'],
      expenditureDate: json['expenditureDate'],
      expenditureDetails: json['expenditureDetails'],
      amount: json['amount'] as num?,
      document: json['document'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'srNo': srNo,
      'expenditureId': expenditureId,
      'expenditureDate': expenditureDate,
      'expenditureDetails': expenditureDetails,
      'amount': amount,
      'document': document,
    };
  }
}

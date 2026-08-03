import 'package:attendance_system_ios/architecture/features/expense_management/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  ExpenseModel({
    required super.todayDate,
    required super.staffCode,
    required super.staffName,
    required super.visitLocation,
    required super.visitPurpose,
    required super.flagValue,
    required super.advanceTaken,
    required super.calculateExpense,
    required super.balanceAmount,
    required super.expenditureDate,
    required super.amount,
    required super.expenditureDetails,
    required super.document,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      todayDate: json['todayDate'],
      staffCode: json['staffCode'],
      staffName: json['staffName'],
      visitLocation: json['visitLocation'],
      visitPurpose: json['visitPurpose'],
      flagValue: json['flagValue'],
      advanceTaken: json['advanceTaken'],
      calculateExpense: json['calculateExpense'],
      balanceAmount: json['balanceAmount'],
      expenditureDate: json['expenditureDate'],
      amount: json['amount'],
      expenditureDetails: json['expenditureDetails'],
      document: json['document'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "todayDate": todayDate,
      "staffCode": staffCode,
      "staffName": staffName,
      "visitLocation": visitLocation,
      "visitPurpose": visitPurpose,
      "flagValue": flagValue,
      "advanceTaken": advanceTaken,
      "calculateExpense": calculateExpense,
      "balanceAmount": balanceAmount,
      "expenditureDate": expenditureDate,
      "amount": amount,
      "expenditureDetails": expenditureDetails,
      "document": document,
    };
  }
}

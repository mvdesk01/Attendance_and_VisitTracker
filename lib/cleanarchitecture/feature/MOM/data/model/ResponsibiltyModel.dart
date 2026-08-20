import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';

///test
class Responsibiltymodel extends Responsibility {
  const Responsibiltymodel({required super.userCode, required super.userName});

  factory Responsibiltymodel.fromJson(Map<String, dynamic> json) {
    return Responsibiltymodel(
        userCode: json['UserCode'] ?? '', userName: json['UserName'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {"UserCode": userCode, "UserName": userName};
  }

  factory Responsibiltymodel.fromEntity(Responsibility responsibility) {
    return Responsibiltymodel(
      userCode: responsibility.userCode,
      userName: responsibility.userName,
    );
  }
}

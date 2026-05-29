import 'package:flutter_test/flutter_test.dart';

void main() {

  test('should return Present when true', () {

    String result = AttendanceUtils.getStatus(true);

    expect(result, "Present");
  });

  test('should return Absent when false', () {

    String result = AttendanceUtils.getStatus(false);

    expect(result, "Absent");
  });
}

class AttendanceUtils {

  static String getStatus(bool present) {
    return present ? "Present" : "Absent";
  }
}
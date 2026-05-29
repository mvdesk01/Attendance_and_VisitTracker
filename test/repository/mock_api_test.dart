//Mock API response.

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class LoginRepository {

  Future<String> login() async {
    return "Success";
  }
  Future<bool> markAttendance() async{
    return true;
  }

}


class MockLoginRepository extends Mock implements LoginRepository {}


void main() {

  late MockLoginRepository repository;

  setUp(() {
    repository = MockLoginRepository();
  });

  test('Login API success', () async {

    when(() => repository.login())
        .thenAnswer((_) async => "Success");

    final result =
    await repository.login();

    expect(result, "Success");
  });

  test('Attendance API returns success',
          () async {

        when(() => repository.markAttendance())
            .thenAnswer((_) async => true);

        final result = await repository.markAttendance();

        expect(result, true);
      });

}


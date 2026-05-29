import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/bloc/main_event.dart';
import 'package:attendance_system_ios/bloc/main_state.dart';
import 'package:attendance_system_ios/model/GatePass/StaffDetailsResponse.dart';
import 'package:attendance_system_ios/model/Login/LoginResponse.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../repository/mock_webservice.dart';


void main() {
  late MockWebService mockWebService;
  late MainBloc mainBloc;

  setUp(() {
    mockWebService = MockWebService();

    mainBloc = MainBloc(
      webService: mockWebService,
    );
  });

  blocTest<MainBloc, MainState>(
    'emits [LoginLoadingState, LoginLoadedState] when login succeeds',

    build: () {
      when(() => mockWebService.userLogin(
        "admin",
        "1234",
      )).thenAnswer(
            (_) async => LoginResponse(),
      );

      return mainBloc;
    },

    act: (bloc) => bloc.add(
      LoginEvents(
        username: "cd03059",
        password: "Admin@123\$",
      ),
    ),

    expect: () => [
      isA<LoginLoadingState>(),
      isA<LoginLoadedState>(),
    ],

    verify: (_) {
      verify(() => mockWebService.userLogin(
        "cd03059",
        "Admin@123\$",
      )).called(1);
    },
  );

  blocTest<MainBloc, MainState>(
    'emits LoginErrorState on exception',
    build: () {
      when(() => mockWebService.userLogin(
            "admin",
            "1234",
          )).thenThrow(Exception("Login Failed"));

      return mainBloc;
    },
    act: (bloc) => bloc.add(
      LoginEvents(
        username: "admin",
        password: "1234",
      ),
    ),
    expect: () => [
      isA<LoginLoadingState>(),
      isA<LoginErrorState>(),
    ],
  );

  // blocTest<MainBloc, MainState>('Get staff details success',
  //
  //   build: () {
  //
  //     when(() => mockWebService.getStaffDetails(
  //       "EMP001",
  //       "token",
  //     )).thenAnswer(
  //           (_) async => StaffDetailsResponse(),
  //     );
  //
  //     return mainBloc;
  //   },
  //
  //   act: (bloc) => bloc.add(
  //     GetStaffDetailsEvents(
  //       StaffCode: "EMP001",
  //       token: "token",
  //     ),
  //   ),
  //
  //   expect: () => [
  //     isA<GetStaffDetailsLoadingState>(),
  //     isA<GetStaffDetailsLoadedState>(),
  //   ],
  // );
}
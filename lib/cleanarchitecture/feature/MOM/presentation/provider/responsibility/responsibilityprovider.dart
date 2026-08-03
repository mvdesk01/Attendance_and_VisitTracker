import 'package:attendance_system_ios/cleanarchitecture/core/DI/providers_di.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/presentation/provider/responsibility/responsibilitystate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'responsibilityprovider.g.dart';

@riverpod
class ResponsibilityNotifier extends _$ResponsibilityNotifier {
  final storage = FlutterSecureStorage();
  String? staffName = "";
  String? staffCode = "";

  @override
  Responsibilitystate build() {
    return const Responsibilitystate();
  }

  Future<void> loadResponsibility({
    bool forceRefresh = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    staffCode = await storage.read(key: 'Staff_Code');
    staffName = await storage.read(key: 'Staff_Name');

    print("staffCode: $staffCode");
    print("Loading customers...");

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final responsibility =
          await ref.read(getResponsibilityusecaseProvider).call(
                userName: staffCode ?? "",
                forceRefresh: forceRefresh,
              );
      stopwatch.stop();

      print("Customer API took ${stopwatch.elapsedMilliseconds} ms");

      final selectedresponsibility =
          await ref.read(getselectedResponsibilityuseCaseProvider).call();

      state = state.copyWith(
        isLoading: false,
        responsibility: responsibility,
        selectedResponsibility: selectedresponsibility,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> selectCustomer(Responsibility responsibility) async {
    await ref
        .read(saveSelectedResponsibilityUseCaseProvider)
        .call(responsibility);

    state = state.copyWith(
      selectedResponsibility: responsibility,
    );
  }

  Future<void> refreshCustomers() async {
    await loadResponsibility(forceRefresh: true);
  }

  Future<void> loadstaffname() async {
    staffCode = await storage.read(key: 'Staff_Code');
    staffName = await storage.read(key: 'Staff_Name');
    print("staffcodemom: $staffCode");
  }
}

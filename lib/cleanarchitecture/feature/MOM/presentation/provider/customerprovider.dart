import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/DI/providers_di.dart';
import '../../domain/enteties/customer.dart';
import 'customerstate.dart';
import 'meetingHistory/meetinghistoryprovider.dart';

part 'customerprovider.g.dart';

@riverpod
class CustomerNotifier extends _$CustomerNotifier {
  final storage = FlutterSecureStorage();
  String? staffName = "";
  String? staffCode = "";

  @override
  CustomerState build() {
    return const CustomerState();
  }

  Future<void> loadCustomers({
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
      final customers = await ref.read(getCustomersUseCaseProvider).call(
            userName: staffCode ?? "",
            forceRefresh: forceRefresh,
          );
      stopwatch.stop();

      print("Customer API took ${stopwatch.elapsedMilliseconds} ms");

      final selectedCustomer =
          await ref.read(getSelectedCustomerUseCaseProvider).call();

      state = state.copyWith(
        isLoading: false,
        customers: customers,
        selectedCustomer: selectedCustomer,
      );
      if (selectedCustomer != null) {
        await ref
            .read(meetingHistoryNotifierProvider.notifier)
            .loadMeetingHistory(
              customerCode: selectedCustomer.customerCode,
              meetingDate: "",
            );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> selectCustomer(Customer customer) async {
    await ref.read(saveSelectedCustomerUseCaseProvider).call(customer);

    state = state.copyWith(
      selectedCustomer: customer,
    );
  }

  Future<void> refreshCustomers() async {
    await loadCustomers(forceRefresh: true);
  }

  Future<void> loadstaffname() async {
    staffCode = await storage.read(key: 'Staff_Code');
    staffName = await storage.read(key: 'Staff_Name');
    print("staffcodemom: $staffCode");
  }
}

///test

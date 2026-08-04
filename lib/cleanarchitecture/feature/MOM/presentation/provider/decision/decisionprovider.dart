import 'package:attendance_system_ios/cleanarchitecture/core/DI/providers_di.dart';
import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/decision.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'decisionstate.dart';

part 'decisionprovider.g.dart';

@riverpod
class DecisionNotifier extends _$DecisionNotifier {
  final storage = FlutterSecureStorage();
  String? staffName = "";
  String? staffCode = "";

  @override
  DecisionState build() {
    return const DecisionState();
  }

  Future<void> loadDecisions({
    bool forceRefresh = false,
  }) async {
    print("Inside loadDecisions");
    final stopwatch = Stopwatch()..start();
    staffCode = await storage.read(key: 'Staff_Code');
    staffName = await storage.read(key: 'Staff_Name');

    print("staffCode: $staffCode");
    print("Loading decision...");

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final decision = await ref.read(getdecisionusecaseProvider).call(
            userName: staffCode ?? "",
            forceRefresh: forceRefresh,
          );
      stopwatch.stop();

      print("Decision API took ${stopwatch.elapsedMilliseconds} ms");

      final selectedDecision =
          await ref.read(getselectedDecisionuseCaseProvider).call();

      state = state.copyWith(
        isLoading: false,
        decisions: decision,
        selectedDecision: selectedDecision,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> selectDecision(Decision decision) async {
    await ref.read(saveselectedDecisionUseCaseProvider).call(decision);

    state = state.copyWith(
      selectedDecision: decision,
    );
  }

  Future<void> refreshDecisions() async {
    await loadDecisions(forceRefresh: true);
  }

  Future<void> loadstaffname() async {
    staffCode = await storage.read(key: 'Staff_Code');
    staffName = await storage.read(key: 'Staff_Name');
    print("staffcodemom: $staffCode");
  }
}

///test

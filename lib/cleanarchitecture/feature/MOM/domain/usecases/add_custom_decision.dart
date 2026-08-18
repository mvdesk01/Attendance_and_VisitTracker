import '../repositories/mom_repositories.dart';

// class AddCustomDecisionUseCase {
//   final MomRepository repository;
//
//   AddCustomDecisionUseCase(this.repository);
//
//   Future<String> call({
//     required String decisionName,
//     required String entryBy,
//   }) async {
//     final request = DecisionMasterRequest(
//       decisionCode: "0",
//       decisionName: decisionName,
//       status: "Y",
//       entryBy: "",
//     );
//
//     return await repository.addCustomDecision(decisionName: decisionName, entryBy: entryBy);
//   }
// }

class AddCustomDecisionUseCase {
  final MomRepository repository;

  AddCustomDecisionUseCase(this.repository);

  Future<String> call({
    required String decisionName,
    required String entryBy,
  }) async {
    return await repository.addCustomDecision(
      decisionName: decisionName,
      entryBy: entryBy,
    );
  }
}

import '../../../database/mom_dbhelper.dart';

class MomDraftService {
  static Future<void> saveDraft({
    required String customerCode,
    required String customerName,
    required Map<String, dynamic> draftData,
  }) async {
    await MomDraftDBHelper.saveDraft(
      customerCode: customerCode,
      customerName: customerName,
      draftData: draftData,
    );
  }

  static Future<Map<String, dynamic>?> getDraft({
    required String customerCode,
  }) async {
    return await MomDraftDBHelper.getDraft(
      customerCode: customerCode,
    );
  }

  static Future<void> deleteDraft({
    required String customerCode,
  }) async {
    await MomDraftDBHelper.deleteDraft(
      customerCode: customerCode,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllDrafts() async {
    return await MomDraftDBHelper.getAllDrafts();
  }
}

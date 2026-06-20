import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MenuRightsService {
  MenuRightsService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _storageKey = "USER_MENU_RIGHTS";
  static List<dynamic> _rights = [];
  static final Set<int> _defaultMenus = {};
  static String? plantCode;

  /// FETCH USER RIGHTS -> SAVE
  static Future<void> syncRights({ required String staffCode, required String token,}) async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://114.143.140.28:8020/api/UserMenuRights/GetUserRights/$staffCode",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "accept": "*/*",
        },
      );

      if (response.statusCode == 200) {
        final List rights =
        jsonDecode(response.body);

        await setRights(rights);
      }
    } catch (e) {
      print("Menu Rights Error: $e");
    }
  }

static Future<void> syncDefaultMenus({required String token,}) async {
  try {
    final response = await http.get(
      Uri.parse(
        "http://114.143.140.28:8020/api/UserMenuRights/GetAllMenus",
      ),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      _defaultMenus.clear();

      for (final menu in data["data"]) {
        if (menu["isDefault"] == true) {
          _defaultMenus.add(
            menu["menuId"],
          );
        }
      }
    }
  } catch (e) {
    print(e);
  }
}

  /// SAVE TO MEMORY + STORAGE
  static Future<void> setRights(List<dynamic> rights,) async {
    plantCode = await _storage.read(key: 'Plant_Code');
    _rights = rights;

    await _storage.write(
      key: _storageKey,
      value: jsonEncode(rights),
    );
  }

  /// LOAD FROM STORAGE
  static Future<void> loadRightsFromStorage() async {
    try {
      final data = await _storage.read(key: _storageKey,);

      if (data != null && data.isNotEmpty) {
        _rights = jsonDecode(data);
      }
    } catch (e) {
      print("Load Rights Error: $e");
    }
  }

  static Future<void> clearRights() async {
    _rights.clear();

    await _storage.delete(
      key: _storageKey,
    );
  }

static bool _hasAccess(int menuId) {
  // Default menu available to everyone
  if (_defaultMenus.contains(menuId) && plantCode != '016') {
    return true;
  }

  try {
    final menu = _rights.firstWhere((e) => e["menuId"] == menuId,);
    return menu["isAllowed"] == true;
  } catch (_) {
    return false;
  }
}

  /// MENU RIGHTS
  static bool isGatePassAllowed() => _hasAccess(1);

  static bool isTourAllowed() => _hasAccess(2);

  static bool isDOffAllowed() => _hasAccess(3);

  static bool isCOffAllowed() => _hasAccess(4);

  static bool isLeaveAllowed() => _hasAccess(5);

  static bool isExpenseAllowed() => _hasAccess(6);

  static bool isPunchInOutAllowed() => _hasAccess(7);

  static bool isVisitManagementAllowed() => _hasAccess(8);

  static bool isProfileAllowed() => _hasAccess(9);

  static bool isAdminRightsAllowed() => _hasAccess(10);

  static bool isEmployeeExpenseReportAllowed() => _hasAccess(11);

  static bool isEmployeeInOutReportAllowed() => _hasAccess(12);

  static bool isEmployeeVisitReportAllowed() => _hasAccess(13);

  static bool isEmployeeProfileAllowed() => _hasAccess(14);

  static bool isMenuRightsAllowed() => _hasAccess(15);

  static bool isSubscriptionAllowed() => _hasAccess(16);

  /// DEBUG
  static List<dynamic> get rights => _rights;
}
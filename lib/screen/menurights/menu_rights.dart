import 'dart:async';
import 'dart:convert';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:attendance_system_ios/util/Constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';
import '../../service/menu_rights_service.dart';

class MenuRightsScreen extends StatefulWidget {
  const MenuRightsScreen({super.key});

  @override
  State<MenuRightsScreen> createState() => _MenuRightsScreenState();
}

class _MenuRightsScreenState extends State<MenuRightsScreen> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  late MainBloc mainBloc;
  String? authToken;
  String? staffCode;
  bool isLoading = false;
  bool rightsAlreadyExist = false;
  TextEditingController searchController = TextEditingController();

  List<Message> searchedUsers = [];
  Message? selectedUser;

  Timer? _debounce;
  bool showSuggestion = false;

  List<MenuRightModel> functionalities = [];

  bool get isAdminSelected {
    final adminMenu = functionalities.where((e) => e.menuId == 10);
    if (adminMenu.isEmpty) return false;
    return adminMenu.first.isSelected;
  }

  List<MenuRightModel> get subMenus {
    return functionalities
        .where((e) => e.menuId >= 11 && e.menuId <= 16)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    authToken = await storage.read(key: 'Auth_Token');
    staffCode = await storage.read(key: "Staff_Code");

    await getAllMenus();
  }

  Future<void> getAllMenus() async {
    try {
      setState(() => isLoading = true);

      final response = await http.get(
        Uri.parse(Constant.getAllMenus),
        headers: {
          "Authorization": "Bearer $authToken",
          "accept": "*/*",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        functionalities = (data["data"] as List)
            .map((e) => MenuRightModel.fromJson(e))
            .toList();
        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error loading menus: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> getUserRights(String userId) async {
    try {
      setState(() => isLoading = true);

      final response = await http.get(
        Uri.parse("${Constant.getUserRights}$userId"),
        headers: {
          "Authorization": "Bearer $authToken",
          "accept": "*/*",
        },
      );

      if (response.statusCode == 200) {
        List rights = jsonDecode(response.body);
        rightsAlreadyExist = rights.isNotEmpty;

        // Reset all first
        for (var menu in functionalities) {
          menu.isSelected = false;
        }

        for (var right in rights) {
          int menuId = right["menuId"];
          int index = functionalities.indexWhere((e) => e.menuId == menuId);
          if (index != -1) {
            functionalities[index].isSelected = right["isAllowed"] ?? false;
          }
        }
        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching user rights: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 600), () {
      String sanitizedText = text.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '');

      if (sanitizedText.isEmpty) {
        setState(() {
          searchedUsers.clear();
          showSuggestion = false;
        });
      } else {
        if (authToken != null) {
          mainBloc.add(SearchbyStaffcodeEvents(
            staffcode: sanitizedText,
            token: authToken!,
          ));
        }
      }
    });
  }

  Future<void> saveRights() async {
    if (selectedUser == null) {
      Fluttertoast.showToast(msg: "Please select employee");
      return;
    }

    try {
      setState(() => isLoading = true);

      String userId = selectedUser!.staffCode!;
      String? createdBy = await storage.read(key: "username");

      List body = functionalities.map((menu) {
        return {
          "menuId": menu.menuId,
          "userId": userId,
          "isAllowed": menu.isSelected,
          "createdBy": createdBy,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(rightsAlreadyExist ? Constant.updateUserRights : Constant.addUserRights),
        headers: {
          "Authorization": "Bearer $authToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Fluttertoast.showToast(msg: data["message"] ?? "Rights updated successfully");
        await getUserRights(userId);
        await MenuRightsService.syncRights(
          staffCode: staffCode!,
          token: authToken!,
        );
        await MenuRightsService.loadRightsFromStorage();
      } else {
        Fluttertoast.showToast(msg: "Failed to save rights: ${response.statusCode}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving rights: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Menu Rights", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocListener<MainBloc, MainState>(
        listener: (context, state) {
          if (state is SearchbyStaffcodeLoadingPage) {
            setState(() => isLoading = true);
          } else if (state is SearchbyStaffcodeLoadedPage) {
            setState(() {
              isLoading = false;
              searchedUsers = state.userResponse?.data
                      .map((e) => Message(
                            staffCode: e.staffCode,
                            displayName: e.displayName,
                            mobileNo: e.mobileNo,
                            emailId: e.emailId,
                          ))
                      .toList() ??
                  [];
              showSuggestion = true;
            });
          } else if (state is SearchbyStaffcodeErrorPage) {
            setState(() {
              isLoading = false;
              searchedUsers.clear();
            });
          }
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSearchBar(),
                  if (showSuggestion && searchedUsers.isNotEmpty && selectedUser == null)
                    _buildSuggestionsList(),
                  if (selectedUser != null) _buildSelectedUserCard(),
                  const SizedBox(height: 10),
                  _buildRightsHeader(),
                  Expanded(
                    child: functionalities.isEmpty && !isLoading
                        ? const Center(child: Text("No menus available"))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: functionalities.where((e) => e.menuId <= 10).length,
                            itemBuilder: (context, index) {
                              final mainMenus = functionalities.where((e) => e.menuId <= 10).toList();
                              return _buildMenuItem(mainMenus[index], index);
                            },
                          ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      bottomSheet: selectedUser == null
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isLoading ? null : saveRights,
                  child: const Text("SAVE RIGHTS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: "Search Staff Code / Name",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        suffixIcon: selectedUser != null || searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    selectedUser = null;
                    searchedUsers.clear();
                    showSuggestion = false;
                    for (var menu in functionalities) {
                      menu.isSelected = false;
                    }
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onSearchTextChanged,
    );
  }

  Widget _buildSuggestionsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: searchedUsers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = searchedUsers[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
            title: Text(user.displayName ?? "No Name", style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(user.staffCode ?? ""),
            onTap: () async {
              setState(() {
                selectedUser = user;
                searchController.text = "${user.displayName} (${user.staffCode})";
                searchedUsers.clear();
                showSuggestion = false;
              });
              await getUserRights(user.staffCode!);
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedUserCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedUser!.displayName ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text("Staff Code: ${selectedUser!.staffCode ?? ""}",
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            if (selectedUser!.emailId != null || selectedUser!.mobileNo != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  if (selectedUser!.mobileNo != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(selectedUser!.mobileNo!),
                        ],
                      ),
                    ),
                  if (selectedUser!.emailId != null)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(child: Text(selectedUser!.emailId!, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRightsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: const [
          SizedBox(width: 30, child: Text("Sr.", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Functionality", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 60, child: Text("Rights", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildMenuItem(MenuRightModel item, int index) {
    bool isHeader = item.menuId == 10;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              SizedBox(width: 30, child: Text("${index + 1}")),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                      fontSize: isHeader ? 15 : 14,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Checkbox(
                  activeColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  value: item.isSelected,
                  onChanged: selectedUser == null
                      ? null
                      : (value) {
                          setState(() {
                            item.isSelected = value ?? false;
                            if (isHeader && !item.isSelected) {
                              for (var sub in subMenus) {
                                sub.isSelected = false;
                              }
                            }
                          });
                        },
                ),
              ),
            ],
          ),
        ),
        if (isHeader && isAdminSelected)
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              children: subMenus.map((subMenu) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(subMenu.name, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ),
                      ),
                      SizedBox(
                        width: 60,
                        child: Checkbox(
                          activeColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          value: subMenu.isSelected,
                          onChanged: selectedUser == null
                              ? null
                              : (value) {
                                  setState(() => subMenu.isSelected = value ?? false);
                                },
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class MenuRightModel {
  final int menuId;
  final String name;
  bool isSelected;

  MenuRightModel({
    required this.menuId,
    required this.name,
    this.isSelected = false,
  });

  factory MenuRightModel.fromJson(Map<String, dynamic> json) {
    return MenuRightModel(
      menuId: json['menuId'] ?? 0,
      name: json['menuName'] ?? "",
    );
  }
}

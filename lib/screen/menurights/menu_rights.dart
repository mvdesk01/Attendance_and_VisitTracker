import 'dart:async';
import 'dart:convert';

import 'package:attendance_system_ios/bloc/main_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../bloc/main_event.dart';
import '../../bloc/main_state.dart';
import '../../model/UsersList/GetAllusersListResponse.dart';

class MenuRightsScreen extends StatefulWidget {
  const MenuRightsScreen({super.key});

  @override
  State<MenuRightsScreen> createState() => _MenuRightsScreenState();
}

class _MenuRightsScreenState extends State<MenuRightsScreen> {
  String? selectedEmployee;

  final List<Map<String, String>> employees = [
    {"name": "Shreya Shankar", "code": "Cd03080"},
    {"name": "Manish Vishwakarma", "code": "cd03159"},
    {"name": "Amit Sonawane", "code": "cd00490"},
    {"name": "Sushmita Powar", "code": "cd03184"},
  ];

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  late MainBloc mainBloc;
  String? Auth_Token;
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
        .where((e) => e.menuId >= 11 && e.menuId <= 14)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    getData();
    getAllMenus();
  }

  Future<void> getData() async {
    Auth_Token =
    await storage.read(
      key: 'Auth_Token',
    );

    await getAllMenus();
  }

  Future<void> getAllMenus() async {
    try {
      setState(() {
        isLoading = true;
      });

      String? token = await storage.read(key: "Auth_Token");

      final response = await http.get(
        Uri.parse(
          "http://114.143.140.28:8020/api/UserMenuRights/GetAllMenus",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "accept": "*/*",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        functionalities =
            (data["data"] as List)
                .map((e) => MenuRightModel.fromJson(e))
                .toList();

        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> getUserRights(String userId) async {
    try {
      setState(() {
        isLoading = true;
      });

      String? token = await storage.read(key: "Auth_Token");

      final response = await http.get(
        Uri.parse(
          "http://114.143.140.28:8020/api/UserMenuRights/GetUserRights/$userId",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "accept": "*/*",
        },
      );

      if (response.statusCode == 200) {
        List rights = jsonDecode(response.body);

        rightsAlreadyExist = rights.isNotEmpty;

        for (var menu in functionalities) {
          menu.isSelected = false;
        }

        for (var right in rights) {
          int menuId = right["menuId"];

          int index = functionalities.indexWhere(
                (e) => e.menuId == menuId,
          );

          if (index != -1) {
            functionalities[index].isSelected =
                right["isAllowed"] ?? false;
          }
        }

        setState(() {});
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onSearchTextChanged(String text) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(
      const Duration(milliseconds: 500),
          () {

        String sanitizedText =
        text.trim().replaceAll(
          RegExp(r'[^a-zA-Z0-9 ]'),
          '',
        );

        if (sanitizedText.isEmpty) {
          setState(() {
            searchedUsers.clear();
            showSuggestion = false;
          });
        } else {
          mainBloc.add(
            SearchbyStaffcodeEvents(
              staffcode: sanitizedText,
              token: Auth_Token!,
            ),
          );
        }
      },
    );
  }

  Future<void> saveRights() async {
    if (selectedUser == null) {
      Fluttertoast.showToast(
        msg: "Please select employee",
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      String userId =
      selectedUser!.staffCode!;

      String? token = await storage.read(
        key: "Auth_Token",
      );

      String? createdBy = await storage.read(
        key: "username",
      );

      List body =
      functionalities.map((menu) {
        return {
          "menuId": menu.menuId,
          "userId": userId,
          "isAllowed": menu.isSelected,
          "createdBy": createdBy,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(
          rightsAlreadyExist
              ? "http://114.143.140.28:8020/api/UserMenuRights/UpdateUserRights"
              : "http://114.143.140.28:8020/api/UserMenuRights/AddUserRights",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Fluttertoast.showToast(
          msg: data["message"],
        );

        await getUserRights(userId);
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: e.toString(),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    mainBloc = BlocProvider.of<MainBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Rights"),
        centerTitle: true,
      ),
      body: BlocListener<MainBloc, MainState>(
    listener: (context, state) {

      if (state is SearchbyStaffcodeLoadingPage) {

        setState(() {
          isLoading = true;
        });

      }

      else if (state is SearchbyStaffcodeLoadedPage) {

        setState(() {

          isLoading = false;

          searchedUsers =
              state.userResponse?.data
                  .map(
                    (e) => Message(
                  staffCode: e.staffCode,
                  displayName: e.displayName,
                  mobileNo: e.mobileNo,
                  emailId: e.emailId,
                ),
              )
                  .toList() ??
                  [];

          showSuggestion = true;
        });
      }

      else if (state is SearchbyStaffcodeErrorPage) {

        setState(() {
          isLoading = false;
          searchedUsers.clear();
        });
      }
    },
    child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search Staff Code / Name",
                prefixIcon: const Icon(Icons.search),

                suffixIcon: selectedUser != null
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {

                    searchController.clear();

                    selectedUser = null;

                    searchedUsers.clear();

                    showSuggestion = false;

                    for (var menu in functionalities) {
                      menu.isSelected = false;
                    }

                    setState(() {});
                  },
                )
                    : null,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: onSearchTextChanged,
            ),

            /// Suggestions

            if (showSuggestion &&
                searchedUsers.isNotEmpty &&
                selectedUser == null)

              Container(
                constraints: const BoxConstraints(
                  maxHeight: 250,
                ),
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchedUsers.length,
                  itemBuilder: (context, index) {

                    final user = searchedUsers[index];

                    return ListTile(
                      title: Text(
                        user.displayName ?? "",
                      ),
                      subtitle: Text(
                        user.staffCode ?? "",
                      ),

                      onTap: () async {

                        selectedUser = user;

                        searchController.text =
                        "${user.displayName} (${user.staffCode})";

                        searchedUsers.clear();

                        showSuggestion = false;

                        setState(() {});

                        await getUserRights(
                          user.staffCode!,
                        );
                      },
                    );
                  },
                ),
              ),

            /// Selected Employee Card

            if (selectedUser != null)

              Card(
                margin: const EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [

                      Row(
                        children: [
                          const Icon(Icons.person),
                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              selectedUser!.displayName ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Text(
                            selectedUser!.staffCode ?? "",
                          ),
                        ],
                      ),

                      if (selectedUser!.mobileNo != null)
                        Row(
                          children: [
                            Text(
                              selectedUser!.mobileNo!,
                            ),
                          ],
                        ),

                      if (selectedUser!.emailId != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedUser!.emailId!,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            Container(
              color: Colors.grey.shade200,
              padding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 8,
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      "Sr.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Functionality",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      "Rights",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: functionalities
                    .where((e) => e.menuId <= 10)
                    .length,
                itemBuilder: (context, index) {

                  final mainMenus =
                  functionalities
                      .where((e) => e.menuId <= 10)
                      .toList();

                  final item = mainMenus[index];

                  return buildMenuItem(item, index);
                },
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedUser == null
                    ? null
                    : saveRights,
                child: const Text(
                  "SAVE RIGHTS",
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget buildMenuItem(
      MenuRightModel item,
      int index,
      ) {
    return Column(
      children: [

        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [

              SizedBox(
                width: 40,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  child: Text(
                    "${index + 1}",
                  ),
                ),
              ),

              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontWeight:
                    item.menuId == 10
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),

              SizedBox(
                width: 70,
                child: Checkbox(
                  value: item.isSelected,
                  onChanged: selectedUser == null
                      ? null
                      : (value) {

                    setState(() {

                      item.isSelected =
                          value ?? false;

                      if (item.menuId == 10 &&
                          !item.isSelected) {

                        for (var sub
                        in subMenus) {

                          sub.isSelected =
                          false;
                        }
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),

        if (item.menuId == 10 &&
            isAdminSelected)

          Container(
            margin:
            const EdgeInsets.only(
              left: 40,
            ),
            child: Column(
              children:
              subMenus.map((subMenu) {

                return Container(
                  decoration:
                  BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors
                            .grey
                            .shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [

                      Expanded(
                        child: Padding(
                          padding:
                          const EdgeInsets
                              .symmetric(
                            vertical:
                            10,
                          ),
                          child: Text(
                            subMenu.name,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 70,
                        child: Checkbox(
                          value: subMenu
                              .isSelected,
                          onChanged:
                          selectedUser ==
                              null
                              ? null
                              : (value) {

                            setState(() {
                              subMenu.isSelected =
                                  value ??
                                      false;
                            });
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
  bool isExpanded;

  MenuRightModel({
    required this.menuId,
    required this.name,
    this.isSelected = false,
    this.isExpanded = false,
  });

  factory MenuRightModel.fromJson(Map<String, dynamic> json) {
    return MenuRightModel(
      menuId: json['menuId'],
      name: json['menuName'],
    );
  }
}

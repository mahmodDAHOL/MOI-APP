import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/colors.dart';
import '../../../utils/helper.dart';
import 'shared_preferences_controller.dart';

class HomeController extends GetxController {
  RxString app = 'home'.obs;
  RxInt myIndex = 0.obs;

  RxString selectedChartType = 'Bar'.obs;

  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final session = Get.find<Session>();
  String? domain;
  String? currentUserEmail;

  @override
  Future<void> onInit() async {
    super.onInit();
    _loadUserData();
    final prefs = await sharedPreferencesController.prefs;
    domain = prefs.getString("domain");
  }

  Future<void> _loadUserData() async {
    final prefs = await sharedPreferencesController.prefs;
    currentUserEmail = prefs.getString("login_email");
  }

  Future<Map<String, dynamic>?> fetchDesktopPageElements(String app) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");

    return await getDesktopPage(domain!, app);
  }

  Future<Map<String, dynamic>?> getWorkspaceSidebarItems() async {
    final prefs = await sharedPreferencesController.prefs;
    Session session = Get.find<Session>();
    final String? domain = prefs.getString("domain");

    final desktopPageUrl = Uri.parse(
      "$domain/api/method/frappe.desk.desktop.get_workspace_sidebar_items",
    );
    final workspaceSidebarResponse = await session.get(desktopPageUrl);
    Map<String, dynamic>? workspaceSidebarItems = jsonDecode(
      workspaceSidebarResponse.body,
    );
    return workspaceSidebarItems;
  }

  BottomNavigationBar get bottomNavigationBar => BottomNavigationBar(
    selectedItemColor: tPrimaryColor,
    onTap: (index) {
      myIndex.value = index;
    },
    currentIndex: myIndex.value,
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.area_chart), label: "Charts"),
      BottomNavigationBarItem(
        icon: Icon(Icons.shortcut_outlined),
        label: "Shortcuts",
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.card_membership),
        label: "Cards",
      ),
    ],
  );

  Future<void> launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<Map<String, dynamic>?> getDashboardCharts(String dashboardName) async {
    final postData = {'dashboard_name': dashboardName};

    final url = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard.dashboard.get_permitted_charts",
    );
    final response = await session.post(url, body: postData);

    return jsonDecode(response.body);
  }
  Future<Map<String, dynamic>?> getDashboardCards(String dashboardName) async {
    final postData = {'dashboard_name': dashboardName};

    final url = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard.dashboard.get_permitted_cards",
    );
    final response = await session.post(url, body: postData);

    return jsonDecode(response.body);

    
  }
}

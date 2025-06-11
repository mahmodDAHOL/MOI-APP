import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
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

  Future<ChartInfo> getChartInfo(String chartName) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.form.load.getdoc",
    );

    final reqBody = {
      'doctype': 'Dashboard Chart',
      'name': chartName,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final response = await session.post(reportViewUrl, body: reqBody);
    final data = jsonDecode(response.body);

    Map<String, dynamic> chartParams =
        data['docs'] != null ? data['docs'][0] : {};

    final url = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard_chart.dashboard_chart.get",
    );

    Map<String, dynamic> body = {
      'chart_name': 'Department Wise Openings',
      'filters': chartParams['filters_json'],
      'refresh': 1,
      'time_interval': "",
      'timespan': "",
      'from_date': "",
      'to_date': "",
      'heatmap_year': "",
    };

    final encodedBody = buildQueryString(body);

    final headers = {
      ...session.headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };

    final res = await http.post(url, headers: headers, body: encodedBody);
    final resData = jsonDecode(res.body);
    Map<String, dynamic> chartData;
    if (resData["message"] != null) {
      chartData = resData["message"];
    } else {
      chartData = {};
    }
    return ChartInfo(chartParams: chartParams, chartData: chartData);
  }

  Future<Map<String, dynamic>> getChartData(
    Map<String, dynamic> chartParams,
  ) async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    final reportViewUrl = Uri.parse(
      "$domain/api/method/frappe.desk.doctype.dashboard_chart.dashboard_chart.get",
    );
    String docJson = jsonEncode(chartParams);
    String reqBody = Uri.encodeComponent(docJson);
    final headers = {...session.headers};

    http.Response response = await http.post(
      reportViewUrl,
      headers: headers,
      body: reqBody,
    );
    Map<String, dynamic> data = jsonDecode(response.body);
    Map<String, dynamic> doctypeData;
    if (data['docs'] != null) {
      doctypeData = data['docs'][0];
    } else {
      doctypeData = {};
    }
    return doctypeData;
  }
}

class ChartInfo {
  final Map<String, dynamic> chartParams;
  final Map<String, dynamic> chartData;

  ChartInfo({required this.chartParams, required this.chartData});
}

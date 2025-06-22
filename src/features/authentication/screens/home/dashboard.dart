import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/helper.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/shared_preferences_controller.dart';
import '../login/login_screen.dart';
import 'charts.dart';
import 'dynamic_list.dart';

class Dashboard extends StatelessWidget {
  String dashboardName;
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final HomeController homeController = Get.put(HomeController());
  final session = Get.find<Session>();

  Dashboard({super.key, required this.dashboardName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 200,
                child: Text(
                  dashboardName,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () async {
                  final prefs = await sharedPreferencesController.prefs;
                  DateTime now = DateTime.now();
                  prefs.setString('expirationDate', now.toString());
                  await prefs.setString('loggedin', 'false');
                  session.headers['X-Frappe-CSRF-Token'] = 'None';
                  String headersencoded = json.encode(session.headers);
                  prefs.setString('headers', headersencoded);
                  Get.off(LoginScreen());
                },
              ),
              SizedBox(width: 8),
            ],
          ),
        ),
        body: Center(
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CardRowBuilder(
                  future: homeController.getDashboardCards(dashboardName),
                  sectionKey: null,
                  itemBuilder: (context, index, item) {
                    return getCardItem(item);
                  },
                ),
              ),
              Expanded(
                child: DynamicListBuilder(
                  future: homeController.getDashboardCharts(dashboardName),
                  sectionKey: null,
                  itemBuilder: (context, index, item) {
                    item["chart_name"] = item["chart"];
                    return getChartItem(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

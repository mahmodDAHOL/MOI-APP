import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/home_controller.dart';
import 'package:moi_app/src/features/authentication/screens/list_view_screen/list_view_screen.dart';
import 'package:moi_app/src/features/authentication/screens/login/login_screen.dart';

import '../../../../utils/helper.dart';
import '../../controllers/shared_preferences_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final HomeController homeController = Get.put(HomeController());
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final session = Get.find<Session>();
  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [
      Text("No Charts Exist"),
      _buildFutureBuilder(),
      Text("No Cards Exist"),
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.home, size: 28),
              SizedBox(width: 8),
              Text("Home", style: TextStyle(fontSize: 20)),
              Spacer(),

              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: () async {
                  final prefs = await sharedPreferencesController.prefs;
                  DateTime now = DateTime.now();
                  prefs.setString('expirationDate', now.toString());
                  await prefs.setString('loggedin', 'false');
                  // Store CSRF token in session headers and SharedPreferences
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
        bottomNavigationBar: Obx(() {
          return homeController.bottomNavigationBar;
        }),
        body: Obx(() {
          return Center(child: widgetList[homeController.myIndex.value]);
        }),
      ),
    );
  }

  Widget _buildFutureBuilder() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: homeController.fetchDesktopPageElements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!['message'] == null) {
          return Center(child: Text('No data available.'));
        }

        final items = snapshot.data!['message']['shortcuts']['items'];
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(items[index]['link_to'].toString()),
              onTap: () {
                Get.to(
                  () => ListViewScreen(
                    doctype: items[index]['link_to'].toString(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

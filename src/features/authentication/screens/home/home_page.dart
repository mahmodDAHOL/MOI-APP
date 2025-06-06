import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/home_controller.dart';
import 'package:moi_app/src/features/authentication/screens/list_view_screen/list_view_screen.dart';
import 'package:moi_app/src/features/authentication/screens/login/login_screen.dart';
import 'package:moi_app/src/utils/helper.dart';

import '../../../../common_widgets/form/collapsable_list_widget.dart';
import '../../controllers/shared_preferences_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key, required this.app});
  final HomeController homeController = Get.put(HomeController());
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final session = Get.find<Session>();

  String app;

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [
      Text("No Charts Exist"),
      _buildDesktopPageFutureBuilder(app),
      Text("No Cards Exist"),
    ];

    return Obx(
      () => SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                // Icon(Icons.home, size: 28),
                // SizedBox(width: 8),
                Text(homeController.app.value, style: TextStyle(fontSize: 20)),
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
          drawer: _buildDrawer(context),
          bottomNavigationBar: Obx(() {
            return homeController.bottomNavigationBar;
          }),
          body: Obx(() {
            return Center(child: widgetList[homeController.myIndex.value]);
          }),
        ),
      ),
    );
  }

  // 🧭 Sidebar Drawer
  Widget _buildDrawer(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: homeController.getWorkspaceSidebarItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!['message'] == null) {
          return Center(child: Text('No data available.'));
        }

        List data = snapshot.data!['message']['pages'];
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text(
                  'Navigation',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              ..._buildMenuItems(context, data),
            ],
          ),
        );
      },
    );
  }

  // 🔘 Reusable Menu Item
  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String? doctype,
    String? icon,
    bool subItem,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.only(left: subItem ? 30 : 10),
      title: Row(
        children: [
          if (icon == "" || icon == null) Icon(Icons.folder),
          Icon(erpnextToFlutterIcons[icon]),
          SizedBox(width: 5),
          Text(title),
        ],
      ),
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        Get.to(() => HomePage(app: title), preventDuplicates: false);
      },
    );
  }

  // 📦 Future Builder for Dynamic Content
  Widget _buildDesktopPageFutureBuilder(String app) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: homeController.fetchDesktopPageElements(app),
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
            if (items[index]['type'] == 'doctype') {
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
            } else {
              return ListTile(
                title: Text(items[index]['label'].toString()),
                onTap: () {},
              );
            }
          },
        );
      },
    );
  }

  List<Widget> _buildMenuItems(BuildContext context, List data) {
    List<Widget> itemsList = [];
    final Map<String, List<Widget>> children = {};
    for (var entry in data) {
      String parent = entry['parent_page'] ?? '';
      String name = entry['name'] ?? '';
      if (parent.isNotEmpty && parent != name) {
        children
            .putIfAbsent(parent, () => [])
            .add(_buildMenuItem(context, name, '', entry['icon'], true));
      }
    }
    for (var entry in data) {
      String name = entry['name'];
      if (children.containsKey(name)) {
        Widget item = CollapsibleWidget(
          header: name,
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children[name] ?? [],
          ),
        );
        itemsList.add(item);
      }
      if (entry['parent_page'].isEmpty && !children.containsKey(name)) {
        Widget item = _buildMenuItem(context, name, '', entry['icon'], false);
        itemsList.add(item);
      }
    }
    return itemsList;
  }
}

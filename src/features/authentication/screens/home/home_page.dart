import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/home_controller.dart';
import 'package:moi_app/src/features/authentication/screens/list_view_screen/list_view_screen.dart';
import 'package:moi_app/src/features/authentication/screens/login/login_screen.dart';
import 'package:moi_app/src/utils/helper.dart';

import '../../../../common_widgets/form/collapsable_list_widget.dart';
import '../../../../constants/colors.dart';
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
      _buildShortcutsPageFutureBuilder(app),
      _buildCartsPageFutureBuilder(app),
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 200,
                child: Text(
                  app,
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
        drawer: _buildDrawer(context),
        bottomNavigationBar: Obx(() {
          return homeController.bottomNavigationBar;
        }),
        body: Obx(() {
          return Center(child: widgetList[homeController.myIndex.value]);
        }),
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
        Get.off(() => HomePage(app: title), preventDuplicates: false);
      },
    );
  }

  // 📦 Future Builder for Dynamic Content
  Widget _buildShortcutsPageFutureBuilder(String app) {
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
            final item = items[index];
            final primaryColor = tPrimaryColor;

            switch (item['type']) {
              case 'DocType':
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    tileColor: Colors.white,
                    leading: Icon(Icons.description, color: Colors.grey[600]),
                    title: Text(
                      item['link_to'].toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    onTap: () {
                      Get.to(
                        () =>
                            ListViewScreen(doctype: item['link_to'].toString()),
                      );
                    },
                  ),
                );
              case 'URL':
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    tileColor: Colors.white,
                    leading: Icon(Icons.link, color: Colors.grey[600]),
                    title: Text(
                      item['label'].toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                    onTap: () {
                      homeController.launchUrl(Uri.parse(item['url']));
                    },
                  ),
                );
              case 'Page':
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    tileColor: Colors.white,
                    leading: Icon(Icons.pages, color: Colors.grey[600]),
                    title: Text(
                      item['label'].toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: primaryColor,
                      ),
                    ),
                    onTap: () {},
                  ),
                );
              default:
                String type = item['type'];
                String type2 = item['type'];
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

  _buildCartsPageFutureBuilder(String app) {
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

        final items = snapshot.data!['message']['cards']['items'];
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final primaryColor = tPrimaryColor;
            return _buildSingleCard(item);
          },
        );
      },
    );
  }

  Card _buildSingleCard(Map<String, dynamic> item) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title
            Text(
              item['label'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: tPrimaryColor, // Themed primary color
              ),
            ),

            const SizedBox(height: 12),

            // Divider for separation
            const Divider(height: 1, thickness: 1, color: Colors.grey),

            const SizedBox(height: 12),

            // Scrollable list of links
            SizedBox(
              height: 180,
              child: ListView.separated(
                itemCount: item['links'].length,
                itemBuilder: (context, index) {
                  final link = item['links'][index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Center(
                      child: Text(
                        // "${link['label']} ${link['onboard']} ${link['link_type']}",
                        link['label'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    onTap: () {
                      if (link['is_query_report'] == 1) {
                      } else {
                        link;
                        Get.to(
                          () => ListViewScreen(
                            doctype: link['link_to'].toString(),
                          ),
                        );
                      }
                    },
                  );
                },
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      thickness: 0.5,
                      indent: 30,
                      endIndent: 0,
                      color: Colors.grey,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

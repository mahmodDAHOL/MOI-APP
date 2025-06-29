import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/home/dashboard.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../constants/colors.dart';
import '../../controllers/home_controller.dart';
import '../list_view_screen/list_view_screen.dart';
import 'charts.dart';
import 'dynamic_list.dart';
import 'report_screen.dart';

Widget buildShortcutsPageFutureBuilder(String app) {
  final HomeController homeController = Get.put(HomeController());

  return DynamicListBuilder(
    future: homeController.fetchDesktopPageElements(app),
    sectionKey: 'shortcuts',
    itemBuilder: (context, index, item) {
      final primaryColor = tPrimaryColor;

      switch (item['type']) {
        case 'DocType':
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  () => ListViewScreen(doctype: item['link_to'].toString()),
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              onTap: () async {
                String? url = item['url'];
                if (url != null && url.isNotEmpty) {
                  Uri parsedUrl = Uri.parse(item['url']);
                  if (await canLaunchUrl(parsedUrl)) {
                    await launchUrl(parsedUrl);
                  }
                }
              },
            ),
          );
        // case 'Page':
        //   return Card(
        //     elevation: 2,
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //     child: ListTile(
        //       tileColor: Colors.white,
        //       leading: Icon(Icons.pages, color: Colors.grey[600]),
        //       title: Text(
        //         item['label'].toString(),
        //         textAlign: TextAlign.center,
        //         style: TextStyle(
        //           fontSize: 16,
        //           fontWeight: FontWeight.w500,
        //           color: primaryColor,
        //         ),
        //       ),
        //       onTap: () {},
        //     ),
        //   );
        case 'Dashboard':
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.dashboard, color: Colors.grey[600]),
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
                Get.to(() {
                  return Dashboard(dashboardName: item["link_to"]);
                });
              },
            ),
          );

        case 'Report':
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.report, color: Colors.grey[600]),
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
                Get.to(() {
                  return ReportScreen(reportName: item['link_to']);
                });
              },
            ),
          );

        default:
          return Container();
      }
    },
  );
}

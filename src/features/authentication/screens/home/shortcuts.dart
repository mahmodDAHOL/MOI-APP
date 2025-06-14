import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../../controllers/home_controller.dart';
import '../list_view_screen/list_view_screen.dart';
import 'dynamic_list.dart';

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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          return Container();
      }
    },
  );
}

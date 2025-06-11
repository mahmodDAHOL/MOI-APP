import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../constants/colors.dart';
import '../../controllers/home_controller.dart';
import '../list_view_screen/list_view_screen.dart';
import 'dynamic_list.dart';

Widget buildCartsPageFutureBuilder(String app) {
  final HomeController homeController = Get.put(HomeController());

  return DynamicListBuilder(
    future: homeController.fetchDesktopPageElements(app),
    sectionKey: 'cards',
    itemBuilder: (context, index, item) {
      return _buildSingleCard(item);
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
                        () =>
                            ListViewScreen(doctype: link['link_to'].toString()),
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

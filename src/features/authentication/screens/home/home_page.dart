import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/home_controller.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final HomeController homeController = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [
      Text("Charts"),
      _buildFutureBuilder(),
      Text("Cards"),
    ];

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Home")),
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
            return ListTile(title: Text(items[index]['link_to'].toString()));
          },
        );
      },
    );
  }
}

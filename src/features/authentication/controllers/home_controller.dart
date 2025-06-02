import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../constants/colors.dart';
import '../../../utils/helper.dart';
import 'shared_preferences_controller.dart';

class HomeController extends GetxController {
  RxInt myIndex = 0.obs;
  final sharedPreferencesController = Get.put(SharedPreferencesController());

  Future<Map<String, dynamic>?> fetchDesktopPageElements() async {
    final prefs = await sharedPreferencesController.prefs;
    final String? domain = prefs.getString("domain");
    return await getDesktopPage(domain!);
  }

  BottomNavigationBar get bottomNavigationBar => BottomNavigationBar(
    selectedItemColor:tPrimaryColor,
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
}

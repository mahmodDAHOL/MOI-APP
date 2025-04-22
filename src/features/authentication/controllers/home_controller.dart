import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/helper.dart';

class HomeController extends GetxController {
  RxInt myIndex = 0.obs;

  Future<Map<String, dynamic>?> fetchDesktopPageElements() async {
    return await getDesktopPage('https://mooii.erpnext.com');
  }

  BottomNavigationBar get bottomNavigationBar => BottomNavigationBar(
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

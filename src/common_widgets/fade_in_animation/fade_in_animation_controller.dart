import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/home/home_page.dart';

import '../../features/authentication/screens/login/login_screen.dart';
import '../../utils/helper.dart';

class FadeInAnimationController extends GetxController {
  static FadeInAnimationController get find => Get.find();
  Session session = Get.find();

  RxBool animate = false.obs;

  Future startSplashAnimation() async {
    await Future.delayed(Duration(milliseconds: 500));
    animate.value = true;
    await Future.delayed(Duration(milliseconds: 3000));
    animate.value = false;
    await Future.delayed(Duration(milliseconds: 2000));
    String expirationDateStr =
        session.headers['Cookie']!.split(";").map((e) => e.trim()).toList()[1];
    DateTime? expirationDate = parseCustomDate(expirationDateStr);

    if (expirationDate == null) {
      print("Invalid date format.");
      return;
    }
    DateTime now = DateTime.now();
    if (!expirationDate.isBefore(now)) {
      Get.offAll(() => HomePage());
    } else {
      Get.offAll(() => LoginScreen());
    }
    
  }

  Future startAnimation() async {
    await Future.delayed(Duration(milliseconds: 500));
    animate.value = true;
  }
}

import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/home/home_page.dart';

import '../../features/authentication/controllers/login_controller.dart';
import '../../features/authentication/screens/login/login_screen.dart';
import '../../utils/helper.dart';

class FadeInAnimationController extends GetxController {
  static FadeInAnimationController get find => Get.find();
  LoginController loginController = Get.put(LoginController());

  Session session = Get.find();

  RxBool animate = false.obs;

  Future startSplashAnimation() async {
    await Future.delayed(Duration(milliseconds: 500));
    animate.value = true;
    await Future.delayed(Duration(milliseconds: 3000));
    animate.value = false;
    await Future.delayed(Duration(milliseconds: 2000));
    DateTime? expirationDate = await loginController.getExpirationDate();

    if (expirationDate == null) {
      Get.offAll(() => LoginScreen());
    } else {
      DateTime now = DateTime.now();
      if (!expirationDate.isBefore(now)) {
        Get.offAll(() => HomePage());
      } else {
        Get.offAll(() => LoginScreen());
      }
    }
  }

  Future startAnimation() async {
    await Future.delayed(Duration(milliseconds: 500));
    animate.value = true;
  }
}


import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/welcome/welcome.dart';

import '../screens/on_boarding_screen/on_boarding_screen.dart';

class SplashScreenController extends GetxController{
  static SplashScreenController get find => Get.find();

  RxBool animate = false.obs;

  Future startAnimation() async {
    await Future.delayed(Duration(milliseconds: 500));
    animate.value = true;
    await Future.delayed(Duration(milliseconds: 5000));
    Get.to(OnBoardingScreen());
  }
}
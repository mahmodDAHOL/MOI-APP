import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/common_widgets/fade_in_animation/fade_in_animation_model.dart';

import 'fade_in_animation_controller.dart';

class TFadeInAnimation extends StatelessWidget {
  TFadeInAnimation({
    super.key,
    required this.durationInMs,
    required this.child,
    this.animate,
  });

  final controller = Get.put(FadeInAnimationController());
  final int durationInMs;
  final TAnimateposition? animate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
        duration: Duration(milliseconds: durationInMs),
        top: controller.animate.value ? animate!.topAfter : animate!.topBefor,
        right:
            controller.animate.value
                ? animate!.rightAfter
                : animate!.rightBefor,
        bottom:
            controller.animate.value
                ? animate!.bottomAfter
                : animate!.bottomBefor,
        left:
            controller.animate.value ? animate!.leftAfter : animate!.leftBefor,
        child: AnimatedOpacity(
          duration: Duration(milliseconds: durationInMs),
          opacity: controller.animate.value ? 1 : 0,
          child: child,
        ),
      ),
    );
  }
}

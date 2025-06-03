import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/constants/image_strings.dart';
import 'package:moi_app/src/constants/sizes.dart';
import 'package:moi_app/src/constants/text_strings.dart';

import '../../../../common_widgets/fade_in_animation/animation_design.dart';
import '../../../../common_widgets/fade_in_animation/fade_in_animation_controller.dart';
import '../../../../common_widgets/fade_in_animation/fade_in_animation_model.dart';
import '../../../../constants/colors.dart';

class SplashScreen extends StatelessWidget {
  final controller = Get.put(FadeInAnimationController());

  @override
  Widget build(BuildContext context) {
    FadeInAnimationController.find.startSplashAnimation();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            TFadeInAnimation(
              durationInMs: 800,
              animate: TAnimateposition(
                topAfter: tDefaultSize,
                topBefor: -30,
                leftBefor: -30,
                leftAfter: tDefaultSize,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tAppName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    tAppTagLine,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
            TFadeInAnimation(
              durationInMs: 800,
              animate: TAnimateposition(bottomBefor: 0, bottomAfter: 100),
              child: Image(image: AssetImage(tSplashImage)),
            ),

            TFadeInAnimation(
              durationInMs: 1200,
              animate: TAnimateposition(
                bottomBefor: 0,
                bottomAfter: 60,
                rightBefor: 0,
                rightAfter: tDefaultSize,
              ),
              child: Container(
                width: tSplashContainerSize,
                height: tSplashContainerSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: tPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

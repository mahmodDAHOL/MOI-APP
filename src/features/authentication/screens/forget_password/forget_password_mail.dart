import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/common_widgets/form/form_header_widget.dart';
import 'package:moi_app/src/constants/image_strings.dart';
import 'package:moi_app/src/constants/sizes.dart';
import 'package:moi_app/src/features/authentication/controllers/forget_password_controller.dart';

import '../../../../constants/text_strings.dart';

class ForgetPasswordMailScreen extends StatelessWidget {
  ForgetPasswordMailScreen({super.key});
  ForgetPasswordController forgetPasswordController = Get.put(
    ForgetPasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(tDefaultSize),
            child: Column(
              children: [
                FormHeaderWidget(
                  image: tForgetPasswordImage,
                  title: tLoginTitle,
                  subTitle: tLoginSubTitle,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  textAlign: TextAlign.center,
                  heightBetween: 30,
                ),
                SizedBox(height: tFormHeight),
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: forgetPasswordController.emailController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_outlined),
                          labelText: "E-mail",
                          hintText: "E-Mail",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tFormHeight),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      forgetPasswordController.forgetPassword();
                    },
                    child: Text("Next"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

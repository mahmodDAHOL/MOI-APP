import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/controllers/login_controller.dart';

import '../../../../constants/sizes.dart';

class LoginForm extends StatelessWidget {
  LoginForm({super.key});
  LoginController loginController = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: tFormHeight - 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: loginController.emailController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_outline_outlined),
                labelText: "E-mail",
                hintText: "E-Mail",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: tFormHeight - 20),
            TextFormField(
              controller: loginController.passwordController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.fingerprint),
                labelText: "Password",
                hintText: "Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.remove_red_eye_sharp),
                ),
              ),
            ),
            const SizedBox(height: tFormHeight - 20),
          ],
        ),
      ),
    );
  }
}
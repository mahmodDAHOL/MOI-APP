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
            // TextFormField(
            //   controller: loginController.domainController,
            //   decoration: InputDecoration(
            //     prefixIcon: Icon(Icons.person_outline_outlined),
            //     labelText: "Domian",
            //     hintText: "https://example.com",
            //     border: OutlineInputBorder(),
            //   ),
            // ),
            // const SizedBox(height: tFormHeight - 20),
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
            PasswordField(),
            const SizedBox(height: tFormHeight - 20),
          ],
        ),
      ),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscurePassword = true;
  LoginController loginController = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: loginController.passwordController,
      obscureText: _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline),
        labelText: "Password",
        hintText: "Enter your password",
        border: OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword
              ? Icons.visibility_off
              : Icons.visibility),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }
}
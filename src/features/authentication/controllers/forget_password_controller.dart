import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../screens/forget_password_otp/otp_screen.dart';
import 'shared_preferences_controller.dart';

class ForgetPasswordController extends GetxController {
  TextEditingController emailController = TextEditingController();
  final sharedPreferencesController = Get.put(SharedPreferencesController());

  void forgetPassword() async {
    if (emailController.text.isNotEmpty) {
      var reqBody = {
        'cmd': 'frappe.core.doctype.user.user.reset_password',
        'user': emailController.text,
      };
      final prefs = await sharedPreferencesController.prefs;
      final String? domain = prefs.getString("domain");

      var response = await http.post(
        Uri.parse(domain!),
        body: jsonEncode(reqBody),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['_server_messages'].contains(
          "Password reset instructions have been sent to your email",
        )) {
          Get.to(() => OtpScreen(email: emailController.text));
        }
      } else {
        print("something went wrong");
      }
    }
  }
}

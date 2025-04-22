import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../screens/forget_password_otp/otp_screen.dart';

class ForgetPasswordController extends GetxController {
  TextEditingController emailController = TextEditingController();

  void forgetPassword() async {
    if (emailController.text.isNotEmpty) {
      var reqBody = {
        'cmd': 'frappe.core.doctype.user.user.reset_password',
        'user': emailController.text,
      };
      var response = await http.post(
        Uri.parse("https://mooii.erpnext.com/"),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:137.0) Gecko/20100101 Firefox/137.0',
          'Accept': 'application/json, */*; q=0.01',
          'Accept-Language': 'en-US,en;q=0.5',
          'Referer': 'https://mooii.erpnext.com/',
          "Content-Type": "application/json",
          'X-Frappe-CSRF-Token': 'None',
          'X-Frappe-CMD': 'frappe.core.doctype.user.user.reset_password',
          'X-Requested-With': 'XMLHttpRequest',
          'Origin': 'https://mooii.erpnext.com',
          'Connection': 'keep-alive',
          'Sec-Fetch-Dest': 'empty',
          'Sec-Fetch-Mode': 'cors',
          'Sec-Fetch-Site': 'same-origin',
          'Priority': 'u=0',
        },
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

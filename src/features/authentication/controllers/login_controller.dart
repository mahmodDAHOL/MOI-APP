import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../screens/home/home_page.dart';

class LoginController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void loginUser() async {
    if (emailController.text.isNotEmpty & passwordController.text.isNotEmpty) {
      var reqBody = {
        "usr": emailController.text,
        "pwd": passwordController.text,
      };
      var response = await http.post(
        Uri.parse("https://mooii.erpnext.com/api/method/login"),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:137.0) Gecko/20100101 Firefox/137.0',
          "Content-Type": "application/json",
        },
        body: jsonEncode(reqBody),
      );
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['message'] == 'Logged In') {
        var fullName = jsonResponse['full_name'];
        Get.to(() => HomePage(fullName: fullName));
      } else {
        print("something went wrong");
      }
    }
  }
}

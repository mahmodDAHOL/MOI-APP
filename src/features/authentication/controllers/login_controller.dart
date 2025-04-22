import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/login/login_screen.dart';
import '../../../utils/helper.dart';
import '../screens/home/home_page.dart';

class LoginController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final session = Get.put(Session());
  final String domain = 'https://mooii.erpnext.com';
  void loginUser() async {
    if (emailController.text.isNotEmpty & passwordController.text.isNotEmpty) {
      if (!await login(
        session,
        domain,
        emailController.text,
        passwordController.text,
      )) {
        return;
      }

      final dashboardUrl = Uri.parse("$domain/desk");
      final dashboardResponse = await session.get(dashboardUrl);

      if (dashboardResponse.statusCode == 200) {
        final htmlContent = dashboardResponse.body;

        final csrfToken = extractCsrfToken(htmlContent);
        if (csrfToken == null) {
          print("CSRF token not found in the HTML.");
          return null;
        }
        session.headers['X-Frappe-CSRF-Token'] = csrfToken;

        Get.to(() => HomePage());
      }
    }
  }
}

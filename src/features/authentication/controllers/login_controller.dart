import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/helper.dart';
import '../screens/home/home_page.dart';
import 'shared_preferences_controller.dart';

class LoginController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final session = Get.find<Session>();
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final String domain = 'https://mooii.erpnext.com';



  void loginUser() async {
    final prefs = await sharedPreferencesController.prefs;
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
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
          return;
        }

        // Store CSRF token in session headers and SharedPreferences
        session.headers['X-Frappe-CSRF-Token'] = csrfToken;
        await prefs.setString('csrf_token', csrfToken); // Save CSRF token
        String expirationDateStr =
            session.headers['Cookie']!
                .split(";")
                .map((e) => e.trim())
                .toList()[1];
        await prefs.setString(
          'expirationDate',
          expirationDateStr,
        ); // Save CSRF token

        Get.to(() => HomePage());
      } else {
        print(
          "Failed to fetch dashboard page. Status code: ${dashboardResponse.statusCode}",
        );
      }
    } else {
      print("Email and password cannot be empty.");
    }
  }

  // Function to load saved session token (optional)
    Future<DateTime?> getExpirationDate() async {
    final prefs = await sharedPreferencesController.prefs;
    final expirationDateStr = prefs.getString('expirationDate');
    if(expirationDateStr == null){
      return null;
    }else{
      DateTime? expirationDate = parseCustomDate(expirationDateStr);
      return expirationDate;
    }
  }
}

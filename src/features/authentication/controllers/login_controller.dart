import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/helper.dart';
import '../screens/home/home_page.dart';
import 'shared_preferences_controller.dart';

class LoginController extends GetxController {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController domainController = TextEditingController();
  // final session = Get.find<Session>();
  final session = Get.put(Session());
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final isLoading = false.obs;

  Future<bool> urlExists(String url) async =>
      (await (HttpClient()
          .getUrl(Uri.parse(url))
          .then((req) => req.close()))).statusCode ==
      HttpStatus.ok;

  void loginUser(BuildContext context) async {
    isLoading.value = true;
    final prefs = await sharedPreferencesController.prefs;
    String domain = 'http://moi-mis.gov.sy';
    // String domain = domainController.text;
    // final exists = await urlExists(domain);
    // if (exists) {
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      final loginUrl = Uri.parse("$domain/api/method/login");
      try {
        final loginResponse = await session.post(
          loginUrl,
          body: {"usr": emailController.text, "pwd": passwordController.text},
        );
        if (loginResponse.statusCode == 200) {
          final dashboardUrl = Uri.parse("$domain/desk");
          session.headers['X-Frappe-CSRF-Token'] = 'None';
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
            String headersencoded = json.encode(session.headers);
            prefs.setString('headers', headersencoded);
            await prefs.setString('csrf_token', csrfToken);
            await prefs.setString('login_email', emailController.text);
            String expirationDateStr =
                session.headers['Cookie']!
                    .split(";")
                    .map((e) => e.trim())
                    .toList()[1];
            await prefs.setString('expirationDate', expirationDateStr);
            await prefs.setString('loggedin', 'true');
            await prefs.setString('domain', domain);
            isLoading.value = false;
            Get.off(() => HomePage(app: 'Home'));
          } else {
            String message = "Failed to fetch dashboard page. Status code: ${dashboardResponse.statusCode}";
            showAutoDismissDialog(context, message);
          }
        } else {
          String message = jsonDecode(loginResponse.body)['message'];
          showAutoDismissDialog(context, message);
        }
      } catch (e) {
        isLoading.value = false;
        showAutoDismissDialog(context, e.toString());
      }
    } else {
      print("Email and password cannot be empty.");
    }
    // } else {
    //   print("domain is not exist.");
    // }
  }

  // Function to load saved session token (optional)
  Future<DateTime?> getExpirationDate() async {
    final prefs = await sharedPreferencesController.prefs;
    final expirationDateStr = prefs.getString('expirationDate');
    if (expirationDateStr == null) {
      return null;
    } else {
      DateTime? expirationDate = parseCustomDate(expirationDateStr);
      return expirationDate;
    }
  }
}

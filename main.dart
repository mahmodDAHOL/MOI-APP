import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/home/home_page.dart';
import 'package:moi_app/src/utils/theme/theme.dart';

import 'src/features/authentication/controllers/shared_preferences_controller.dart';
import 'src/utils/helper.dart';

void main() async {
  Session session = Session();
  final sharedPreferencesController = Get.put(SharedPreferencesController());
  final prefs = await sharedPreferencesController.prefs;
  String? headersencoded = prefs.getString('headers');
  if (headersencoded != null) {
    // Decode the headers and convert to Map<String, String>
    Map<String, dynamic> tempHeaders = json.decode(headersencoded);
    Map<String, String> headersdecoded = Map<String, String>.from(tempHeaders);

    session.setHeader(headersdecoded);
  }
  Get.put(session);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return App();
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.leftToRightWithFade,
      transitionDuration: const Duration(milliseconds: 500),
      home: HomePage(app:'Home'),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/login/login_screen.dart';

import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';

class OtpScreen extends StatelessWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            padding: EdgeInsets.all(tDefaultSize),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage(
                    'assets/images/forget_password/message_sent.png',
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  "$tOtpMessage $email",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),

                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => LoginScreen());
                    },
                    child: Text("Back To Login"),
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

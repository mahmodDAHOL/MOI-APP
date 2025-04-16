import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../constants/sizes.dart';
import '../../../../constants/text_strings.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

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
                Text(
                  tOtpTitle,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 80,
                  ),
                ),
                Text(
                  tOtpSubTitle,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 40),
                Text(
                  "$tOtpMessage mahmod@gmail.com",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                SizedBox(height: 20),
                OtpTextField(
                  numberOfFields: 6,
                  fillColor: Colors.black.withValues(alpha: 0.1),
                  filled: true,
                  onSubmit: (code) {
                    print(code);
                  },
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: () {}, child: Text("Next")),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

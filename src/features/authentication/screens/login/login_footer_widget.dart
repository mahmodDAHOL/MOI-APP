import 'package:flutter/material.dart';

import '../forget_password/forget_password_options/forget_password_modal_bottom_sheet.dart';

class LoginFooterWidget extends StatelessWidget {
  const LoginFooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                ForgetPasswordScreen.buildShowModalBottomSheet(context);
              },
              child: Text("Forget Password?"),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () {}, child: Text("LOGIN")),
          ),
        ],
      ),
    );
  }
}

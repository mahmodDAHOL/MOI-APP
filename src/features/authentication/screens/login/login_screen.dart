import 'package:flutter/material.dart';
import 'package:moi_app/src/constants/sizes.dart';

import 'login_form_widget.dart';
import 'login_header_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(tDefualtSize),
            child: Column(
              children: [LoginHeaderWidget(size: size), LoginForm()],
            ),
          ),
        ),
      ),
    );
  }
}

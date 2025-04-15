import 'package:flutter/material.dart';
import 'package:moi_app/src/common_widgets/form/form_header_widget.dart';
import 'package:moi_app/src/constants/image_strings.dart';
import 'package:moi_app/src/constants/sizes.dart';

import '../../../../constants/text_strings.dart';

class ForgetPasswordMailScreen extends StatelessWidget {
  const ForgetPasswordMailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(tDefualtSize),
            child: Column(
              children: [
                FormHeaderWidget(
                  image: tForgetPasswordImage,
                  title: tLoginTitle,
                  subTitle: tLoginSubTitle,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  textAlign: TextAlign.center,
                  heightBetween: 30,
                ),
                SizedBox(height: tFormHeight),
                Form(
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.person_outline_outlined),
                          labelText: "E-mail",
                          hintText: "E-Mail",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: tFormHeight),
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

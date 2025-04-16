import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/features/authentication/screens/forget_password/forget_password_mail.dart';

import '../../../../../constants/sizes.dart';
import '../../../../../constants/text_strings.dart';
import 'forget_password_btn_widget.dart';

class ForgetPasswordScreen {
  static Future<dynamic> buildShowModalBottomSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(tDefaultSize),
          child: Column(
            children: [
              Text(
                tForgetPasswordTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                tForgetPasswordSubTitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 30),
              ForgetPasswordBtnWidget(
                onTab: () {
                  Navigator.pop(context);
                  Get.to(() => ForgetPasswordMailScreen());
                },
                title: 'E-Mail',
                subTitle: tResetViaEmail,
                btnIcon: Icons.mail_outline_outlined,
              ),
              SizedBox(height: 20),
              ForgetPasswordBtnWidget(
                btnIcon: Icons.mobile_friendly_rounded,
                title: 'Phone No',
                subTitle: tResetViaPhone,
                onTab: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

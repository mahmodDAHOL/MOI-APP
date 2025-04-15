import 'package:flutter/material.dart';

import '../../../../constants/image_strings.dart';

class LoginHeaderWidget extends StatelessWidget {
  const LoginHeaderWidget({super.key, required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image(
          image: AssetImage(tWelcomeScreenImage),
          height: size.height * 0.2,
        ),
        Text(
          "Welcome back..",
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Text(
          "Make it Work, Make it right, Make it fast",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../constants/sizes.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: tFormHeight - 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_outline_outlined),
                labelText: "E-mail",
                hintText: "E-Mail",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: tFormHeight - 20),
            TextFormField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.fingerprint),
                labelText: "Password",
                hintText: "Password",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.remove_red_eye_sharp),
                ),
              ),
            ),
            const SizedBox(height: tFormHeight - 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text("Forget Password?"),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {}, child: Text("LOGIN")),
            ),
          ],
        ),
      ),
    );
  }
}

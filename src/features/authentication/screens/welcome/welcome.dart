import 'package:flutter/material.dart';
import 'package:moi_app/src/constants/colors.dart';
import 'package:moi_app/src/constants/image_strings.dart';
import 'package:moi_app/src/constants/text_strings.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context); 
    var height = mediaQuery.size.height;
    var brightness = mediaQuery.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? tSecondaryColor : tPrimaryColor,
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image(image: AssetImage(tWelcomeScreenImage), height: height* 0.6,),
            Column(
              children: [
                Text(tWelcomeTitle, style: Theme.of(context).textTheme.headlineLarge,),
                Text(tWelcomeSubTitle, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center,),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: (){},
                  
                  child: Text("LOGIN"))
            ],),

          ],
        ),
      ));
  }
}

import 'package:flutter/material.dart';

class FormHeaderWidget extends StatelessWidget {
  const FormHeaderWidget({
    super.key,
    this.imageColor,
    this.heightBetween,
    this.textAlign,
    required this.image,
    required this.title,
    required this.subTitle,
    this.imageHeight = 0.2,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String image, title, subTitle;
  final Color? imageColor;
  final double? heightBetween;
  final double imageHeight;
  final TextAlign? textAlign;

  final CrossAxisAlignment crossAxisAlignment;
  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.headlineLarge);
  }
}

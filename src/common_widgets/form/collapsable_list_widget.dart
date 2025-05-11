import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollapsibleWidget extends StatelessWidget {
  final String header;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleWidget({
    super.key,
    required this.header,
    required this.child,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    // Reactive state
    final isExpanded = RxBool(initiallyExpanded);

    return Obx(() => Column(
          children: [
            GestureDetector(
              onTap: () => isExpanded.toggle(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                  Expanded(child: Text(
                      header,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),),
                  Icon(
                    isExpanded.value ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 24,
                  ),
                ]),
              ),
            ),
            AnimatedCrossFade(
              firstChild: Container(height: 0.0),
              secondChild: child,
              crossFadeState: isExpanded.value
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ));
  }
}
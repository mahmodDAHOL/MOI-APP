import 'package:flutter/material.dart';
import 'package:moi_app/src/constants/colors.dart';

class DashboardCardWidget extends StatelessWidget {
  final Map<String, dynamic> cardData;

  const DashboardCardWidget({super.key, required this.cardData});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cardData['name'] ?? 'No Name',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16,color: tPrimaryColor),
            ),
            SizedBox(height: 8),
            Text(
              "${cardData['value']}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

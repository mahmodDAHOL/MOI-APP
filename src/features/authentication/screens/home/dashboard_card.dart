import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/constants/colors.dart';
import 'package:shimmer/shimmer.dart';

import '../../controllers/card_controller.dart';
import '../../models/dashbaord_card_model.dart';

class DashboardCardWidget extends StatelessWidget {
  final Map<String, dynamic> cardData;

  DashboardCardWidget({super.key, required this.cardData});

  @override
  Widget build(BuildContext context) {
    String datatype = '';
    Color? color;
    if (cardData['indicator'] != null) {
      String colorName = cardData['indicator'].toLowerCase();
      datatype = cardData['datatype'];
      color = namedColors[colorName];
    }
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
              cardData['name'] ?? cardData['label'] ?? 'No Name',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              datatype == "Percent"
                  ? "${cardData['value']} %"
                  : cardData['value'].toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color ?? tPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, Color> namedColors = {
    'red': Colors.red,
    'blue': Colors.blue,
    'green': Colors.green,
  };
}

Widget getCardItem(Map item) {
  final CardController cardController = Get.put(CardController());

  return FutureBuilder<DashboardCard>(
    future: cardController.getDashboardCardParams(item['card']?? item['number_card_name']),
    builder: (context, cardMetaSnapshot) {
      if (cardMetaSnapshot.connectionState == ConnectionState.waiting) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simulated title
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      width: 100,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      }
      if (cardMetaSnapshot.hasError) {
        return Center(
          child: Text("Card Meta Error: ${cardMetaSnapshot.error}"),
        );
      }

      DashboardCard cardMeta = cardMetaSnapshot.data!;

      return FutureBuilder<Map<String, dynamic>>(
        future: cardController.getCardData(cardMeta),
        builder: (context, cardDataSnapshot) {
          if (cardDataSnapshot.connectionState == ConnectionState.waiting) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Simulated title
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Container(
                          width: 100,
                          height: 16,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          }
          if (cardDataSnapshot.hasError) {
            return Center(
              child: Text("card Data Error: ${cardDataSnapshot.error}"),
            );
          }

          Map<String, dynamic> cardData = cardDataSnapshot.data!;

          return DashboardCardWidget(cardData: cardData);
        },
      );
    },
  );
}

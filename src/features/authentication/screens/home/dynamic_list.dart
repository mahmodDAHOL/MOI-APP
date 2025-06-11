import 'package:flutter/material.dart';

class DynamicListBuilder extends StatelessWidget {
  const DynamicListBuilder({
    Key? key,
    required this.future,
    required this.sectionKey,
    required this.itemBuilder,
  }) : super(key: key);

  final Future<Map<String, dynamic>?> future;
  final String sectionKey;
  final Widget Function(BuildContext, int, Map<String, dynamic>) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data?['message'] == null) {
          return const Center(child: Text('No Data Available.'));
        }

        final List items = snapshot.data!['message'][sectionKey]['items'];

        return ListView.builder(
          itemCount: items.length,
          itemBuilder:
              (context, index) => itemBuilder(context, index, items[index]),
        );
      },
    );
  }
}

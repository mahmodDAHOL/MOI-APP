// Multi Select widget
// This widget is reusable
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/authentication/controllers/report_controller.dart';

class MultiSelectField extends StatefulWidget {
  final Map<String, dynamic> field;

  const MultiSelectField({Key? key, required this.field}) : super(key: key);

  @override
  _MultiSelectFieldState createState() => _MultiSelectFieldState();
}

class _MultiSelectFieldState extends State<MultiSelectField> {
  List<String> _selectedItems = [];
  ReportController reportController = Get.put(ReportController());

  Future<List<String>?> _showMultiSelect(BuildContext context) async {
    final List<String>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          items:
              (widget.field['options'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toList(),
        );
      },
    );

    if (results != null) {
      setState(() {
        _selectedItems = results;
      });
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () {
              _showMultiSelect(context).then((results) {
                reportController.filters[widget.field['fieldname']] = results;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Text(widget.field['fieldname']),
            ),
          ),
          const Divider(height: 30),
          Wrap(
            children:
                _selectedItems.map((item) => Chip(label: Text(item))).toList(),
          ),
        ],
      ),
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> items;

  const MultiSelectDialog({Key? key, required this.items}) : super(key: key);

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  final List<String> _selected = [];

  void _toggleSelection(String item, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selected.add(item);
      } else {
        _selected.remove(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Select Items"),
      content: SingleChildScrollView(
        child: ListBody(
          children:
              widget.items
                  .map(
                    (item) => CheckboxListTile(
                      title: Text(item),
                      value: _selected.contains(item),
                      onChanged: (bool? val) {
                        _toggleSelection(item, val ?? false);
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: Navigator.of(context).pop, child: Text("Cancel")),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: Text("Done"),
        ),
      ],
    );
  }
}

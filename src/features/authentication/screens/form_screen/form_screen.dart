import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moi_app/src/common_widgets/form/collapsable_list_widget.dart';

import '../../../../common_widgets/form/table.dart';
import '../../../../utils/helper.dart';
import '../../controllers/form_controller.dart';
import '../../models/field_type_model.dart';
import '../../models/form_field_model.dart';

class DynamicForm extends StatelessWidget {
  final String doctype;
  final bool fullForm;
  final FormController controller = Get.put(FormController());

  DynamicForm({super.key, required this.doctype, required this.fullForm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dynamic Form")),
      body: FutureBuilder<Map<String, List<FormFieldData>>>(
        future: controller.getFormLayout(doctype, fullForm),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}\n\n${snapshot.stackTrace}"),
            );
          } else if (snapshot.hasData) {
            Map<String, List<FormFieldData>> tabs = snapshot.data!;
            if (fullForm) {
              return ListView(
                children: [
                  ...tabs.entries.map((tabEntry) {
                    return CollapsibleWidget(
                      header: tabEntry.key,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: tabEntry.value.length,
                        itemBuilder: (context, fieldIndex) {
                          return _buildFieldWidget(
                            tabEntry.value[fieldIndex],
                            controller,
                            context,
                          );
                        },
                      ),
                    );
                  }),
                ],
              );
            } else {
              return CollapsibleWidget(
                header: tabs.keys.first,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: tabs.values.single.length + 1,
                  itemBuilder: (context, fieldIndex) {
                    if (fieldIndex < tabs.values.single.length) {
                      FormFieldData field = tabs.values.single[fieldIndex];
                      return _buildFieldWidget(field, controller, context);
                    } else {
                      return TextButton(
                        onPressed: () {
                          Get.to(DynamicForm(doctype: doctype, fullForm: true));
                        },
                        child: Text("Edit full form"),
                      );
                    }
                  },
                ),
              ); // fullForm is false
            }
          } else {
            return Center(child: Text("No fields found"));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            controller.isSubmitting.value
                ? null
                : () => controller.submitForm(doctype, context),
        child:
            controller.isSubmitting.value
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : const Icon(Icons.save),
      ),
    );
  }

  Widget _buildFieldWidget(
    FormFieldData field,
    FormController controller,
    BuildContext context,
  ) {

    switch (field.type) {
      case FieldType.text:
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(labelText: field.label),
              controller: TextEditingController(
                text: field.defaultValue?.toString() ?? controller.formValues[field.fieldName],
              ),
              onChanged: (value) {
                controller.formValues[field.fieldName] = value.toString();
              },
            ),
          );

      case FieldType.select:
        return Obx(() {
          return ListTile(
            title: Text(field.label ?? field.fieldName),
            subtitle: Text(
              controller.formValues[field.fieldName]?.toString() ??
                  field.defaultValue ??
                  "Select Option",
            ),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView(children: getSelectOptions(field));
                },
              );
            },
          );
        });

      case FieldType.link:
        return Obx(() {
          return ListTile(
            title: Text(field.label ?? field.fieldName),
            subtitle: Text(
              controller.formValues[field.fieldName]?.toString() ??
                  field.defaultValue ??
                  "Select Option",
            ),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        title: Text(
                          "Select an option",
                          textAlign: TextAlign.center,
                        ),
                        onTap: () {},
                      ),
                      ...field.options!.map((option) {
                        return ListTile(
                          title: Text(option),
                          onTap: () {
                            controller.formValues[field.fieldName] =
                                option.toString();
                            Get.back();
                          },
                        );
                      }),
                      ListTile(
                        title: Row(
                          children: [
                            Icon(Icons.add, size: 20),
                            Text("Create a new ${field.label}"),
                          ],
                        ),
                        onTap: () {
                          Get.to(
                            DynamicForm(doctype: field.label!, fullForm: false),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        });

      case FieldType.date:
        return Obx(() {
          final selectedDate =
              controller.formValues[field.fieldName] != null
                  ? DateTime.tryParse(controller.formValues[field.fieldName]!)
                  : null;

          return ListTile(
            title: Text(field.label ?? field.fieldName),
            subtitle: Text(
              selectedDate != null
                  ? "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}"
                  : field.defaultValue ?? "Select Date",
            ),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final initialDate = selectedDate ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                controller.formValues[field.fieldName] = picked.toString();
              }
            },
          );
        });

      case FieldType.check:
        return Obx(() {
          final bool isChecked =
              toBool(controller.formValues[field.fieldName]) == true ||
              (toBool(field.defaultValue) == true &&
                  controller.formValues[field.fieldName] == null);

          return ListTile(
            title: Text(field.label ?? field.fieldName),
            trailing: Checkbox(
              value: isChecked,
              onChanged: (value) {
                controller.formValues[field.fieldName] = value.toString();
              },
            ),
          );
        });

      case FieldType.table:
        List<FormFieldData>? tableFields = field.data;
        return TableWithAddButton(
          doctype: field.options!,
          tableFields: tableFields!,
          field: field,
        );

      default:
        return Text(
          "${field.fieldName} ${field.type} ",
          style: TextStyle(color: Colors.red),
        );
    }
  }

  List<Widget> getSelectOptions(field) {
    return (field.options ?? []).map<Widget>((option) {
      return ListTile(
        title: Text(option),
        onTap: () {
          controller.formValues[field.fieldName] = option.toString();
          Get.back();
        },
      );
    }).toList();
  }
}

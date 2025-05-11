import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common_widgets/form/table.dart';
import '../../controllers/form_controller.dart';
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
      body: FutureBuilder<List<List<FormFieldData>>>(
        future: controller.getFormLayout(doctype, fullForm),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount:
                  snapshot.data![0].length + 1, // Add 1 for the extra widget
              itemBuilder: (context, index) {
                List<List<FormFieldData>> listOfDocs = snapshot.data!;
                if (index < snapshot.data![0].length) {
                  final field = snapshot.data![0][index];

                  return _buildFieldWidget(listOfDocs, field, controller, context);
                } else if (!fullForm) {
                  return TextButton(
                    onPressed: () {
                      Get.to(DynamicForm(doctype: doctype, fullForm: true));
                    },
                    child: Text("Edit full form"),
                  );
                }
              },
            );
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
    List<List<FormFieldData>> listOfDocs,
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
                  "Select Option",
            ),
            trailing: Icon(Icons.arrow_drop_down),
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return ListView(
                    children:
                        (field.options ?? []).map((option) {
                          return ListTile(
                            title: Text(option),
                            onTap: () {
                              controller.formValues[field.fieldName] =
                                  option.toString();
                              Get.back();
                            },
                          );
                        }).toList(),
                  );
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
          return ListTile(
            title: Text(field.label ?? field.fieldName),
            subtitle: Text(
              controller.formValues[field.fieldName]?.toString() ??
                  "Select Date",
            ),
            trailing: Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    controller.formValues[field.fieldName] ?? DateTime.now(),
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
          return ListTile(
            title: Text(field.label ?? field.fieldName),
            trailing: Checkbox(
              value:
                  controller.formValues[field.fieldName] == 1 ||
                  controller.formValues[field.fieldName] == true,
              onChanged: (value) {
                controller.formValues[field.fieldName] = value.toString();
              },
            ),
          );
        });
      case FieldType.tabBreak:
        return ListTile(
          title: Text(
            field.label ?? field.fieldName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          tileColor: Colors.grey[200], // Background color for section header
        );
      case FieldType.table:
        List<FormFieldData> tableFields = listOfDocs[field.tableIndex+1]; //+1 for skip first item (parent doctype)
        return TableWithAddButton(
          doctype: field.options!,
          tableFields: tableFields,
          field:field
        );


      default:
        return Text(field.fieldName, style: TextStyle(color: Colors.red));
      // return SizedBox(height: 1,);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common_widgets/form/collapsable_list_widget.dart';
import '../../../../common_widgets/form/table.dart';
import '../../../../common_widgets/rich_text_field.dart';
import '../../../../utils/helper.dart';
import '../../controllers/form_controller.dart';
import '../../models/field_type_model.dart';
import '../../models/form_field_model.dart';

class DynamicForm extends StatefulWidget {
  final String doctype;
  final bool fullForm;
  final bool forEditing;

  DynamicForm({
    super.key,
    required this.doctype,
    required this.fullForm,
    required this.forEditing,
  });

  @override
  State<DynamicForm> createState() => _DynamicFormState();
}

class _DynamicFormState extends State<DynamicForm> {
  final FormController controller = Get.put(FormController());
  bool refresh = false;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: AppBar(title: Text(widget.doctype)),
        body: RefreshIndicator(
          onRefresh: () async {
            // Trigger a fresh load with skipCache = true
            await controller.getFormLayout(
              widget.doctype,
              widget.fullForm,
              widget.forEditing,
              skipCache: true,
            );
            setState(() {
              refresh = !refresh;
            });
          },
          child: FutureBuilder<Map<String, List<FormFieldData>>>(
            future: controller.getFormLayout(
              widget.doctype,
              widget.fullForm,
              widget.forEditing,
              skipCache: false, // Use cache by default
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Center(child: CircularProgressIndicator())],
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error: ${snapshot.error}\n\n${snapshot.stackTrace}",
                  ),
                );
              } else if (snapshot.hasData) {
                Map<String, List<FormFieldData>> tabs = snapshot.data!;
                if (widget.fullForm) {
                  return getFullFormWidget(tabs);
                } else {
                  return getMainFormWidget(tabs);
                }
              } else {
                return Center(child: Text("No fields found"));
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed:
              controller.isSubmitting.value
                  ? null
                  : () => controller.submitForm(
                    widget.doctype,
                    widget.forEditing,
                    context,
                  ),
          child:
              controller.isSubmitting.value
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : const Icon(Icons.save),
        ),
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
        // return Obx(
        // () =>
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(labelText: field.label),
            controller: TextEditingController(
              text:
                  controller.formValues[field.fieldName]?.toString() ??
                  field.defaultValue?.toString() ??
                  "",
            ),
            onChanged: (value) {
              controller.formValues[field.fieldName] = value.toString();
            },
          ),
          // ),
        );
      case FieldType.textEditor:
        return RichTextField(labelText: field.label, fieldName:field.fieldName);

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
                            Expanded(
                              child: Text(
                                "Create a new ${field.label}",
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Get.to(
                            () => DynamicForm(
                              doctype: field.label!,
                              fullForm: false,
                              forEditing: false,
                            ),
                            preventDuplicates: false,
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
              toBool(controller.formValues[field.fieldName].toString()) ==
                  true ||
              (toBool(field.defaultValue.toString()) == true &&
                  controller.formValues[field.fieldName] == null);

          return ListTile(
            title: Text(field.label ?? field.fieldName),
            trailing: Checkbox(
              value: isChecked,
              onChanged: (value) {
                controller.formValues[field.fieldName] = toIntBool(value);
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
        return SizedBox(height: 1);
      // return Text(
      //   "${field.fieldName} ${field.type} ",
      //   style: TextStyle(color: Colors.red),
      // );
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

  Widget getMainFormWidget(Map<String, dynamic> tabs) {
    return ListView.builder(
      shrinkWrap: false,
      itemCount: tabs.values.single.length + 1,
      itemBuilder: (context, fieldIndex) {
        if (fieldIndex < tabs.values.single.length) {
          FormFieldData field = tabs.values.single[fieldIndex];
          return _buildFieldWidget(field, controller, context);
        } else {
          return TextButton(
            onPressed: () {
              Get.off(
                () => DynamicForm(
                  doctype: widget.doctype,
                  fullForm: true,
                  forEditing: widget.forEditing,
                ),
                preventDuplicates: false,
              );
            },
            child: Text("Edit full form"),
          );
        }
      },
    );
  }

  Widget getFullFormWidget(Map<String, List<FormFieldData>> tabs) {
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
  }
}

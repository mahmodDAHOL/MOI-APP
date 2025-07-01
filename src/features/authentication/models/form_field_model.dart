// 🧱 Field metadata class
import 'package:moi_app/src/features/authentication/models/doctype_model.dart';

import 'field_type_model.dart';

class FormFieldData {
  final String fieldName;
  final FieldType type;
  final String? label;
  dynamic options;
  final dynamic defaultValue;
  final dynamic data;
  final dynamic tableIndex;
  final TableDoctypeData? tableDoctypeData;

  FormFieldData({
    required this.fieldName,
    required this.type,
    this.label,
    this.options,
    this.defaultValue,
    this.data,
    this.tableIndex,
    this.tableDoctypeData,
  });

  // 👇 Add this copyWith method
  FormFieldData copyWith({
    String? fieldName,
    FieldType? type,
    String? label,
    dynamic options,
    dynamic defaultValue,
    dynamic data,
    dynamic tableIndex,
    TableDoctypeData? tableDoctypeData,
  }) {
    return FormFieldData(
      fieldName: fieldName ?? this.fieldName,
      type: type ?? this.type,
      label: label ?? this.label,
      options: options ?? this.options,
      defaultValue: defaultValue ?? this.defaultValue,
      data: data ?? this.data,
      tableIndex: tableIndex ?? this.tableIndex,
      tableDoctypeData: tableDoctypeData ?? this.tableDoctypeData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldName': fieldName,
      'type': fieldTypeToString(type),
      'label': label,
      'options': options,
      'defaultValue': defaultValue,
      'data': data,
      'tableIndex': tableIndex,
      'tableDoctypeData': tableDoctypeData?.toJson() ?? {},
    };
  }

  factory FormFieldData.fromJson(Map<String, dynamic> json) {
    return FormFieldData(
      fieldName: json['fieldName'] ?? "",
      type: stringToFieldType(json['type']),
      label: json['label'],
      options: json['options'],
      defaultValue: json['defaultValue'],
      data:
          json['data'] is List
              ? (json['data'] as List)
                  .map(
                    (item) =>
                        FormFieldData.fromJson(item as Map<String, dynamic>),
                  )
                  .toList()
              : json['data'], // fallback if not a list
      tableIndex: json['tableIndex'],
      tableDoctypeData: TableDoctypeData.fromJson(json['tableDoctypeData']),
    );
  }
}

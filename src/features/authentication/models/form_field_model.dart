// 🧱 Field metadata class
import 'package:moi_app/src/features/authentication/models/doctype_model.dart';

import 'field_type_model.dart';

class FormFieldData {
  final String fieldName;
  final FieldType type;
  final String? label;
  final dynamic options;
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
    // ✅ Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'type': fieldTypeToString(type),
      'label': label,
      'options': options,
      'defaultValue': defaultValue,
      'data': data,
      'tableIndex': tableIndex,
      'tableDoctypeData': tableDoctypeData?.toMap() ?? {},
    };
  }
    factory FormFieldData.fromJson(Map<String, dynamic> json) {
    return FormFieldData(
      fieldName: json['fieldName'],
      type: tringToFieldType(json['type']),
      label: json['label'],
      options: json['options'],
      defaultValue: json['defaultValue'],
      data: json['data'],
      tableIndex: json['tableIndex'],
      tableDoctypeData: TableDoctypeData.fromJson(json['tableDoctypeData']),
    );
  }
}
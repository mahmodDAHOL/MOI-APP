// 🧱 Field metadata class
import 'package:moi_app/src/features/authentication/models/doctype_model.dart';

import '../controllers/form_controller.dart';

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
}
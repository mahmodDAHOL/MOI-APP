enum FieldType { text, date, datetime, select, check, link, tabBreak, table, image, unknown }

// Convert enum to String
String fieldTypeToString(FieldType type) {
  return type.toString().split('.').last;
}


// Convert String to enum
FieldType stringToFieldType(String? typeName) {
    switch (typeName?.capitalize()) {
      case 'Date':
        return FieldType.date;
      case 'Datetime':
        return FieldType.datetime;
      case 'Select':
        return FieldType.select;
      case 'Link':
        return FieldType.link;
      case 'Check':
        return FieldType.check;
      case 'Text':
      case 'Small Text':
      case 'Text Editor':
      case 'Float':
      case 'Int':
      case 'Currency':
      case 'Data':
        return FieldType.text;
      case 'Tab Break':
        return FieldType.tabBreak;
      case 'Table':
        return FieldType.table;
      case 'Attach Image':
        return FieldType.image;
      default:
        return FieldType.unknown;
    }
}

extension StringExtensions on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

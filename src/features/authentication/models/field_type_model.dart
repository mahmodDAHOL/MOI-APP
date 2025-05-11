enum FieldType { text, date, select, check, link, tabBreak, table, unknown }

// Convert enum to String
String fieldTypeToString(FieldType type) {
  return type.toString().split('.').last;
}

// Convert String to enum
FieldType tringToFieldType(String? typeName) {
  switch (typeName) {
    case 'text':
      return FieldType.text;
    case 'date':
      return FieldType.date;
    case 'select':
      return FieldType.select;
    case 'check':
      return FieldType.check;
    case 'link':
      return FieldType.link;
    case 'tabBreak':
      return FieldType.tabBreak;
    case 'table':
      return FieldType.table;
    default:
      return FieldType.unknown;
  }
}
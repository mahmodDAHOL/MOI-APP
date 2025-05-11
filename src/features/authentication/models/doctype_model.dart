class TableDoctypeData {
  final int docstatus;
  final String doctype;
  final String name;
  final String owner;
  final String parent;
  final String parentfield;
  final String parenttype;
  final int idx;

  TableDoctypeData({
    required this.docstatus,
    required this.doctype,
    required this.name,
    required this.owner,
    required this.parent,
    required this.parentfield,
    required this.parenttype,
    required this.idx,
  });

  // ✅ Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'docstatus': docstatus,
      'doctype': doctype,
      'name': name,
      'owner': owner,
      'parent': parent,
      'parentfield': parentfield,
      'parenttype': parenttype,
      'idx': idx,
    };
  }

  factory TableDoctypeData.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) {
      return TableDoctypeData(
        docstatus: 0,
        doctype: "",
        name: "",
        owner: "",
        parent: "",
        parentfield: "",
        parenttype: "",
        idx: 0,
      );
    } else {
      return TableDoctypeData(
        docstatus: json['docstatus'],
        doctype: json['doctype'],
        name: json['name'],
        owner: json['owner'],
        parent: json['parent'],
        parentfield: json['parentfield'],
        parenttype: json['parenttype'],
        idx: json['idx'],
      );
    }
  }
}

class DashboardCard {
  final String name;
  final int docstatus;
  final int idx;
  final int isStandard;
  final String module;
  final String label;
  final String function;
  final String reportFunction	;
  final String aggregateFunctionBasedOn;
  final String documentType;
  final int showPreeentageStats;
  final String statsTimeInterval;
  final int isPublic;
  final String type; // This determines chart type: 'Bar', 'Line', 'Donut', etc.
  final String filtersJson;
  final String dynamicFiltersJson;
  final String doctype;
  final String method;

  DashboardCard({
    required this.name,
    required this.docstatus,
    required this.idx,
    required this.module,
    required this.label,
    required this.function,
    required this.reportFunction	,
    required this.aggregateFunctionBasedOn,
    required this.documentType,
    required this.statsTimeInterval,
    required this.showPreeentageStats,
    required this.isPublic,
    required this.isStandard,
    required this.type,
    required this.filtersJson,
    required this.dynamicFiltersJson,
    required this.doctype,
    required this.method,
  });

  // Factory method to create object from JSON map
  factory DashboardCard.fromJson(Map<String, dynamic> json) {
    return DashboardCard(
      name: json['name'] ?? '',
      docstatus: json['docstatus'] ?? 0,
      idx: json['idx'] ?? 0,
      module: json['module'] ?? '',
      label: json['label'] ?? '',
      function: json['function'] ?? '',
      reportFunction: json['report_function	'] ?? '',
      aggregateFunctionBasedOn: json['aggregate_function_based_on'] ?? '',
      documentType: json['document_type'] ?? '',
      statsTimeInterval: json['stats_time_interval'] ?? '',
      showPreeentageStats: json['show_percentage_stats'] ?? 0,
      isPublic: json['is_public'] ?? 0,
      isStandard: json['is_standard'] ?? 1,
      type: json['type'] ?? 'Bar', // default chart type
      filtersJson: json['filters_json'] ?? '[]',
      dynamicFiltersJson: json['dynamic_filters_json'] ?? '[]',
      doctype: json['doctype'] ?? '',
      method: json['method'] ?? '',
    );
  }
    Map<String, dynamic> toJson() {
    return {
      'name':name ,
      'docstatus':docstatus ,
      'idx': idx,
      'module':module ,
      'label':label ,
      'function':function ,
      'report_function':reportFunction ,
      'aggregate_function_based_on':aggregateFunctionBasedOn ,
      'document_type':documentType ,
      'stats_time_interval':statsTimeInterval ,
      'numberesow_precentage_statsOfGroups': showPreeentageStats,
      'is_public':isPublic ,
      'is_standard': isStandard,
      'type': type, // default chart type
      'filters_json': filtersJson,
      'dynamic_filters_json': dynamicFiltersJson,
      'doctype':doctype ,
      'method':method ,
    };
  }
  factory DashboardCard.fromMap(Map<String, dynamic> map) {
    return DashboardCard(
      name: map['name'] ?? '',
      docstatus: map['docstatus'] ?? 0,
      idx: map['idx'] ?? 0,
      module: map['module'] ?? '',
      label: map['label'] ?? '',
      function: map['function'] ?? '',
      reportFunction: map['report_function'] ?? '',
      aggregateFunctionBasedOn: map['aggregate_function_based_on'] ?? '',
      documentType: map['document_type'] ?? '',
      statsTimeInterval: map['stats_time_interval'] ?? '',
      showPreeentageStats: map['numberesow_precentage_statsOfGroups'] ?? 0,
      isPublic: map['is_public'] ?? 0,
      isStandard: map['is_standard'] ?? 1,
      type: map['type'] ?? 'Bar',
      filtersJson: map['filters_json'] ?? '[]',
      dynamicFiltersJson: map['dynamic_filters_json'] ?? '[]',
      doctype: map['doctype'] ?? '',
      method: map['method'] ?? '',
    );
  }
}

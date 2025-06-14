class DashboardChart {
  final String chartName;
  final String chartType;
  final int useReportChart;
  final String source;
  final String documentType;
  final String parentDocumentType;
  final String basedOn;
  final String valueBasedOn;
  final String groupByType;
  final String groupByBasedOn;
  final int numberOfGroups;
  final int isPublic;
  final String timespan;
  final String timeInterval;
  final String customOptions;
  final String reportName;
  final int timeseries;
  final String type; // This determines chart type: 'Bar', 'Line', 'Donut', etc.
  final String currency;
  final String filtersJson;
  final String dynamicFiltersJson;
  String color;
  final String doctype;
  final List yAxis;
  final List roles;

  DashboardChart({
    required this.chartName,
    required this.chartType,
    required this.useReportChart,
    required this.source,
    required this.documentType,
    required this.parentDocumentType,
    required this.basedOn,
    required this.valueBasedOn,
    required this.groupByType,
    required this.groupByBasedOn,
    required this.numberOfGroups,
    required this.isPublic,
    required this.timespan,
    required this.timeInterval,
    required this.customOptions,
    required this.reportName	,
    required this.timeseries,
    required this.type,
    required this.currency,
    required this.filtersJson,
    required this.dynamicFiltersJson,
    required this.color,
    required this.doctype,
    required this.yAxis,
    required this.roles,
  });

  // Factory method to create object from JSON map
  factory DashboardChart.fromJson(Map<String, dynamic> json) {
    return DashboardChart(
      chartName: json['chart_name'] ?? '',
      chartType: json['chart_type'] ?? '',
      useReportChart: json['use_report_chart'] ?? 0,
      source: json['source'] ?? '',
      documentType: json['document_type'] ?? '',
      parentDocumentType: json['parent_document_type'] ?? '',
      basedOn: json['based_on'] ?? '',
      valueBasedOn: json['value_based_on'] ?? '',
      groupByType: json['group_by_type'] ?? '',
      groupByBasedOn: json['group_by_based_on'] ?? '',
      numberOfGroups: json['number_of_groups'] ?? 0,
      isPublic: json['is_public'] ?? 0,
      timespan: json['timespan'] ?? '',
      timeInterval: json['time_interval'] ?? '',
      customOptions: json['custom_options'] ?? '',
      reportName: json['report_name'] ?? '',
      timeseries: json['timeseries'] ?? 0,
      type: json['type'] ?? 'Bar', // default chart type
      currency: json['currency'] ?? '',
      filtersJson: json['filters_json'] ?? '[]',
      dynamicFiltersJson: json['dynamic_filters_json'] ?? '[]',
      color: json['color'] ?? '#000000',
      doctype: json['doctype'] ?? '',
      yAxis: json['y_axis'] ?? [],
      roles: json['roles'] ?? [],
    );
  }
  factory DashboardChart.fromMap(Map<String, dynamic> map) {
    return DashboardChart(
      chartName: map['chart_name'] ?? '',
      chartType: map['chart_type'] ?? '',
      useReportChart: map['use_report_chart'] ?? 0,
      source: map['source'] ?? '',
      documentType: map['document_type'] ?? '',
      parentDocumentType: map['parent_document_type'] ?? '',
      basedOn: map['based_on'] ?? '',
      valueBasedOn: map['value_based_on'] ?? '',
      groupByType: map['group_by_type'] ?? '',
      groupByBasedOn: map['group_by_based_on'] ?? '',
      numberOfGroups: map['number_of_groups'] ?? 0,
      isPublic: map['is_public'] ?? 0,
      timespan: map['timespan'] ?? '',
      timeInterval: map['time_interval'] ?? '',
      customOptions: map['custom_options'] ?? '',
      reportName: map['report_name'] ?? '',
      timeseries: map['timeseries'] ?? 0,
      type: map['type'] ?? 'Bar',
      currency: map['currency'] ?? '',
      filtersJson: map['filters_json'] ?? '[]',
      dynamicFiltersJson: map['dynamic_filters_json'] ?? '[]',
      color: map['color'] ?? '#000000',
      doctype: map['doctype'] ?? '',
      yAxis: map['y_axis'] ?? [],
      roles: map['roles'] ?? [],
    );
  }
}

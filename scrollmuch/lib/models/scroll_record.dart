class ScrollRecord {
  final String date;
  final double meters;

  ScrollRecord({
    required this.date,
    required this.meters,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'meters': meters,
      };

  factory ScrollRecord.fromJson(Map<String, dynamic> json) => ScrollRecord(
        date: json['date'] as String,
        meters: json['meters'] as double,
      );
}

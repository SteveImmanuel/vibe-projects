/// Scroll distance accumulated for a single app today.
class AppScroll {
  final String package;
  final String label;
  final double meters;

  const AppScroll({
    required this.package,
    required this.label,
    required this.meters,
  });

  factory AppScroll.fromMap(Map<String, dynamic> map) => AppScroll(
        package: map['package'] as String,
        label: map['label'] as String,
        meters: (map['meters'] as num).toDouble(),
      );
}

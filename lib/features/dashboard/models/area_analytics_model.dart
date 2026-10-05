class AreaCountItem {
  final String area;
  final int count;

  const AreaCountItem({
    required this.area,
    required this.count,
  });

  factory AreaCountItem.fromJson(Map<String, dynamic> json) {
    return AreaCountItem(
      area: json['area']?.toString() ?? 'Unknown Area',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'count': count,
    };
  }
}

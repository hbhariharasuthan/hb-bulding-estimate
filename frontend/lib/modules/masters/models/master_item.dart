class MasterItem {
  MasterItem({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final int id;
  final String name;
  final bool isActive;

  factory MasterItem.fromJson(Map<String, dynamic> json) => MasterItem(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        isActive: json['is_active'] == true,
      );
}

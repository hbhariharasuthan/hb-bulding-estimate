class MaterialStandardItem {
  MaterialStandardItem({
    required this.standardId,
    required this.materialId,
    required this.materialName,
    required this.propertyId,
    required this.propertyName,
    required this.value,
    required this.unitId,
    required this.unitName,
    required this.isDefault,
    required this.isActive,
  });

  final int standardId;
  final int materialId;
  final String materialName;
  final int propertyId;
  final String propertyName;
  final double? value;
  final int unitId;
  final String unitName;
  final bool isDefault;
  final bool isActive;

  factory MaterialStandardItem.fromJson(Map<String, dynamic> json) =>
      MaterialStandardItem(
        standardId: json['standard_id'] as int,
        materialId: json['material_id'] as int,
        materialName: json['material_name']?.toString() ?? '',
        propertyId: json['property_id'] as int,
        propertyName: json['property_name']?.toString() ?? '',
        value: (json['value'] as num?)?.toDouble(),
        unitId: json['unit_id'] as int,
        unitName: json['unit_name']?.toString() ?? '',
        isDefault: json['default'] == true,
        isActive: json['is_active'] == true,
      );
}

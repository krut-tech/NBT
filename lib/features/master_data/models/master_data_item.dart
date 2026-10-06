class MasterDataItem {
  final String id;
  final String category;
  final String name;
  final String? code;
  final bool isActive;
  final int displayOrder;

  MasterDataItem({
    required this.id,
    required this.category,
    required this.name,
    this.code,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory MasterDataItem.fromJson(Map<String, dynamic> json) {
    return MasterDataItem(
      id: json['id'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'name': name,
      'code': code,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

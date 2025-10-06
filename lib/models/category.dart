import 'dart:convert';

class CategoryModel {
  final String id;
  final String name;

  /// 'global' untuk kategori bawaan; selain itu adalah userId pemilik.
  final String ownerId;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  CategoryModel copyWith({String? id, String? name, String? ownerId}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
    id: j['id'] as String,
    name: j['name'] as String,
    ownerId: j['ownerId'] as String? ?? 'global',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'ownerId': ownerId};

  /// Helper opsional kalau kamu perlu simpan ke String (mis. SharedPreferences)
  String toJsonString() => jsonEncode(toJson());
  factory CategoryModel.fromJsonString(String s) =>
      CategoryModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

import 'package:uuid/uuid.dart';

class Secret {
  final String id;
  final String title;
  final String description;
  final String encryptedData;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Secret({
    String? id,
    required this.title,
    this.description = '',
    required this.encryptedData,
    this.category = 'general',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'encryptedData': encryptedData,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Secret.fromJson(Map<String, dynamic> json) => Secret(
        id: json['id'],
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        encryptedData: json['encryptedData'] ?? '',
        category: json['category'] ?? 'general',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      );
}

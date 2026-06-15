import 'package:uuid/uuid.dart';

class Heir {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final int shareCount;
  final bool notified;
  final DateTime addedAt;

  Heir({
    String? id,
    required this.name,
    required this.email,
    this.phone,
    this.shareCount = 1,
    this.notified = false,
    DateTime? addedAt,
  })  : id = id ?? const Uuid().v4(),
        addedAt = addedAt ?? DateTime.now();

  Heir copyWith({
    String? name,
    String? email,
    String? phone,
    int? shareCount,
    bool? notified,
  }) =>
      Heir(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        shareCount: shareCount ?? this.shareCount,
        notified: notified ?? this.notified,
        addedAt: addedAt,
      );
}

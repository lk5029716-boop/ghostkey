import 'dart:convert';

import 'package:flutter/material.dart';

@immutable
class LocalAuthEntity {
  final int generatedID;

  // id can be null if a code has been scanned locally but it's yet to be
  // synced with the remote server.
  final String? id;
  final String encryptedData;
  final String header;

  // createdAt and updateAt will be equal to local time of creation or updation
  // till remote sync is completed.
  final int createdAt;
  final int updatedAt;

  // shouldSync indicates that the entry was locally created or updated. The
  // app should try to sync it to the server during next sync
  final bool shouldSync;

  // manualOrder is set by drag-to-reorder; lower = earlier in the list.
  // Defaults to 0; codes without manual ordering fall back to createdAt.
  final int manualOrder;

  const LocalAuthEntity(
    this.generatedID,
    this.id,
    this.encryptedData,
    this.header,
    this.createdAt,
    this.updatedAt,
    this.shouldSync, {
    this.manualOrder = 0,
  });

  LocalAuthEntity copyWith({
    int? generatedID,
    String? id,
    String? encryptedData,
    String? header,
    int? createdAt,
    int? updatedAt,
    bool? shouldSync,
    int? manualOrder,
  }) {
    return LocalAuthEntity(
      generatedID ?? this.generatedID,
      id ?? this.id,
      encryptedData ?? this.encryptedData,
      header ?? this.header,
      createdAt ?? this.createdAt,
      updatedAt ?? this.updatedAt,
      shouldSync ?? this.shouldSync,
      manualOrder: manualOrder ?? this.manualOrder,
    );
  }

  Map<String, dynamic> toMap({bool forInsert = false}) {
    return {
      // For new rows, omit _generatedID so SQLite AUTOINCREMENT picks
      // the next id. If we pass 0 explicitly, SQLite stores 0 as the
      // value, and the second insert collides on the PRIMARY KEY,
      // triggering REPLACE (which silently destroys the first row).
      if (!forInsert) '_generatedID': generatedID,
      'id': id,
      'encryptedData': encryptedData,
      'header': header,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // sqlite doesn't support bool type. map true to 1 and false to 0
      'shouldSync': shouldSync ? 1 : 0,
      'manual_order': manualOrder,
    };
  }

  factory LocalAuthEntity.fromMap(Map<String, dynamic> map) {
    return LocalAuthEntity(
      map['_generatedID']!,
      map['id'],
      map['encryptedData']!,
      map['header']!,
      map['createdAt']!,
      map['updatedAt']!,
      (map['shouldSync']! == 0) ? false : true,
      manualOrder: map['manual_order'] as int? ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalAuthEntity.fromJson(String source) =>
      LocalAuthEntity.fromMap(json.decode(source));
}

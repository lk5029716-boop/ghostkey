import 'package:flutter/material.dart';
import 'vault_data.dart';

enum HomeTileType { login, note, apiKey, recoveryCodes, totp, seed }

class HomeTile {
  final String id;
  final HomeTileType type;
  const HomeTile({required this.id, required this.type});

  Map<String, dynamic> toJson() => {'id': id, 'type': type.name};

  factory HomeTile.fromJson(Map<String, dynamic> json) => HomeTile(
        id: json['id'] as String,
        type: HomeTileType.values.byName(json['type'] as String),
      );
}

class TileTypeInfo {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const TileTypeInfo(this.label, this.icon, this.color, this.bg);
}

const Map<HomeTileType, TileTypeInfo> kTileInfo = {
  HomeTileType.login: TileTypeInfo(
      'Create a login', Icons.login, Color(0xFF4285F4), Color(0xFFBBDEFB)),
  HomeTileType.note: TileTypeInfo(
      'Create a note', Icons.note, Color(0xFF6A1B9A), Color(0xFFE1BEE7)),
  HomeTileType.apiKey: TileTypeInfo(
      'Add API key', Icons.vpn_key, Color(0xFF00796B), Color(0xFFB2DFDB)),
  HomeTileType.recoveryCodes: TileTypeInfo(
      'Recovery codes', Icons.grid_view, Color(0xFF7B1FA2), Color(0xFFE1BEE7)),
  HomeTileType.totp: TileTypeInfo(
      'Add 2FA code', Icons.shield, Color(0xFF1D4FA6), Color(0xFFBBDEFB)),
  HomeTileType.seed: TileTypeInfo(
      'Seed phrase', Icons.spa, Color(0xFF0D631B), Color(0xFFC8E6C9)),
};

/// Map a HomeTileType to its corresponding VaultCategory.
VaultCategory tileTypeToCategory(HomeTileType type) {
  switch (type) {
    case HomeTileType.login:
      return VaultCategory.password;
    case HomeTileType.note:
      return VaultCategory.notes;
    case HomeTileType.apiKey:
      return VaultCategory.apiKeys;
    case HomeTileType.recoveryCodes:
      return VaultCategory.codes;
    case HomeTileType.totp:
      return VaultCategory.totp;
    case HomeTileType.seed:
      return VaultCategory.seeds;
  }
}

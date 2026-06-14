import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://YOUR_PROJECT.supabase.co',
      anonKey: 'YOUR_ANON_KEY',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getSecrets() async {
    final response = await client.from('secrets').select();
    return response;
  }

  static Future<void> addSecret(String title, String value) async {
    await client.from('secrets').insert({'title': title, 'value': value});
  }
}
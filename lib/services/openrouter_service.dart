import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple wrapper for the OpenRouter API.
///
/// Usage:
/// ```dart
/// final client = OpenRouterClient(apiKey: 'YOUR_OPENROUTER_API_KEY');
/// final response = await client.chat(
///   model: 'openrouter/owl-alpha',
///   messages: [
///     {'role': 'user', 'content': 'Hello, world!'},
///   ],
/// );
/// print(response);
/// ```
class OpenRouterClient {
  final String apiKey;
  final String _baseUrl = 'https://openrouter.ai/api/v1';

  OpenRouterClient({required this.apiKey});

  /// Sends a chat completion request to the specified model.
  ///
  /// `model` should be the model identifier as listed on OpenRouter,
  /// e.g. `openrouter/owl-alpha`.
  ///
  /// `messages` is a list of maps with `role` (`'system'`, `'user'`, `'assistant'`)
  /// and `content` strings, following the OpenAI chat format.
  ///
  /// Returns the decoded JSON response from the API.
  Future<Map<String, dynamic>> chat({
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');
    final body = jsonEncode({
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        // OpenRouter recommends specifying the source.
        'X-Title': 'GhostKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API error: ${response.statusCode} ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

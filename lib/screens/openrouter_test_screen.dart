import 'package:flutter/material.dart';
import '../services/openrouter_service.dart';

/// Simple UI to test the OpenRouter Owl‑Alpha model.
///
/// This screen is **not** part of the production UI – it is just a
/// convenience for developers. It requires an OpenRouter API key. Set the
/// `OPENROUTER_API_KEY` environment variable on your device or replace the
/// placeholder string in the code before running.
class OpenRouterTestScreen extends StatefulWidget {
  const OpenRouterTestScreen({super.key});

  @override
  State<OpenRouterTestScreen> createState() => _OpenRouterTestScreenState();
}

class _OpenRouterTestScreenState extends State<OpenRouterTestScreen> {
  final _controller = TextEditingController();
  String? _response;
  bool _loading = false;
  String? _error;

  Future<void> _send() async {
    setState(() {
      _loading = true;
      _error = null;
      _response = null;
    });
    try {
      // TODO: replace with a real key or pull from secure storage.
      const apiKey = String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: 'YOUR_OPENROUTER_API_KEY');
      final client = OpenRouterClient(apiKey: apiKey);
      final result = await client.chat(
        model: 'openrouter/owl-alpha',
        messages: [
          {'role': 'user', 'content': _controller.text},
        ],
      );
      setState(() => _response = result['choices']?.first['message']?['content']?.toString() ?? 'No content');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('OpenRouter Owl‑Alpha Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _send,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send'),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              Text(_error!),
            ] else if (_response != null) ...[
              const Text('Response:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(_response!),
            ],
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';

/// BIP39 English wordlist + validation engine.
///
/// - Loads the official 2048-word English wordlist from bundled asset
/// - O(1) word-to-index and index-to-word lookups
/// - Real-time prefix matching for autocomplete (first 3-4 letters)
/// - Full BIP39 checksum validation (SHA256-based)
class Bip39Validator {
  static const int _wordCount12 = 12;
  static const int _wordCount24 = 24;

  static const List<int> validWordCounts = [_wordCount12, _wordCount24];

  static List<String>? _words;
  static Map<String, int>? _wordToIndex;

  /// Load the wordlist from bundled asset. Call once at app init.
  static Future<void> loadWordlist() async {
    if (_words != null) return; // already loaded

    final raw = await rootBundle.loadString('assets/bip39_english.txt');
    _words = const LineSplitter().convert(raw)
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();

    if (_words!.length != 2048) {
      throw StateError('BIP39 wordlist has ${_words!.length} words, expected 2048');
    }

    _wordToIndex = <String, int>{};
    for (int i = 0; i < _words!.length; i++) {
      _wordToIndex![_words![i]] = i;
    }
  }

  /// Check if a word exists in the BIP39 wordlist.
  static bool isValidWord(String word) {
    return _wordToIndex?[word.toLowerCase().trim()] != null;
  }

  /// Get word by index (0-2047).
  static String? wordAt(int index) {
    if (index < 0 || index >= 2048) return null;
    return _words?[index];
  }

  /// Get a word's index (0-2047), or -1 if not found.
  static int indexOf(String word) {
    return _wordToIndex?[word.toLowerCase().trim()] ?? -1;
  }

  /// Return all words that start with [prefix]. Used for autocomplete.
  /// Because BIP39 guarantees first 4 letters are unique, a 3-4 char
  /// prefix narrows to at most a handful of candidates.
  static List<String> wordsStartingWith(String prefix) {
    if (_words == null) return [];
    final p = prefix.toLowerCase().trim();
    if (p.isEmpty) return [];
    return _words!.where((w) => w.startsWith(p)).toList();
  }

  /// Validate a complete seed phrase.
  /// Returns a [Bip39ValidationResult] with details.
  static Bip39ValidationResult validate(List<String> words) {
    if (_words == null) {
      return Bip39ValidationResult(
        isValid: false,
        error: 'Wordlist not loaded. Call Bip39Validator.loadWordlist() first.',
      );
    }

    if (!validWordCounts.contains(words.length)) {
      return Bip39ValidationResult(
        isValid: false,
        error: 'Invalid word count: ${words.length}. Expected 12 or 24.',
      );
    }

    // Check every word exists in the wordlist
    final List<int> indices = [];
    for (int i = 0; i < words.length; i++) {
      final idx = indexOf(words[i]);
      if (idx == -1) {
        return Bip39ValidationResult(
          isValid: false,
          error: 'Word #${i + 1} "${words[i]}" is not a valid BIP39 word.',
          invalidWordIndex: i,
          invalidWord: words[i],
        );
      }
      indices.add(idx);
    }

    // BIP39 checksum verification
    // Each word = 11 bits. Total bits = words.length * 11
    // CS bits = words.length / 3 (4 for 12 words, 8 for 24 words)
    // ENT bits = totalBits - csBits
    final int totalBits = words.length * 11;
    final int csBits = words.length ~/ 3;
    final int entBits = totalBits - csBits;

    // Build the full bit string from word indices
    // Each word index is 11 bits, big-endian
    final bitString = StringBuffer();
    for (final idx in indices) {
      bitString.write(idx.toRadixString(2).padLeft(11, '0'));
    }
    final bits = bitString.toString();

    // Extract entropy bits and checksum bits
    final entropyBits = bits.substring(0, entBits);
    final checksumBits = bits.substring(entBits);

    // Convert entropy bits to bytes
    final entropyBytes = _bitsToBytes(entropyBits);

    // Compute SHA256 of entropy
    final hash = sha256.convert(entropyBytes);
    final hashBits = _bytesToBytes(hash.bytes);

    // Expected checksum = first csBits of hash
    final expectedChecksum = hashBits.substring(0, csBits);

    if (checksumBits != expectedChecksum) {
      return Bip39ValidationResult(
        isValid: false,
        error: 'Checksum verification failed. This recovery phrase may contain typos.',
      );
    }

    return Bip39ValidationResult(isValid: true);
  }

  /// Convert a binary string to a Uint8List.
  static Uint8List _bitsToBytes(String bits) {
    final bytes = Uint8List(bits.length ~/ 8);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(bits.substring(i * 8, i * 8 + 8), radix: 2);
    }
    return bytes;
  }

  /// Convert bytes to a binary string.
  static String _bytesToBytes(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(2).padLeft(8, '0')).join();
  }

  /// Get the loaded wordlist (for autocomplete, etc.)
  static List<String>? get words => _words;

  /// Check if the wordlist has been loaded
  static bool get isLoaded => _words != null;
}

class Bip39ValidationResult {
  final bool isValid;
  final String? error;
  final int? invalidWordIndex;
  final String? invalidWord;

  const Bip39ValidationResult({
    required this.isValid,
    this.error,
    this.invalidWordIndex,
    this.invalidWord,
  });
}

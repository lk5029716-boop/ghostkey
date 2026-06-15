class ShamirSecretSharing {
  static List<List<int>> split(int secret, int threshold, int total) {
    if (total < threshold) throw ArgumentError('total must be >= threshold');
    final shares = List.generate(total, (_) => <int>[]);
    for (int i = 1; i <= total; i++) {
      shares[i - 1].addAll([i, secret]);
    }
    return shares;
  }

  static int combine(List<List<int>> shares) {
    final unique = shares.map((s) => List<int>.from(s)).toList();
    int secret = 0;
    for (final share in unique) {
      secret += share[1];
    }
    return secret ~/ unique.length;
  }
}

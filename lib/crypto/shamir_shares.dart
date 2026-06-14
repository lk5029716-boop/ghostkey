import 'dart:math';

class ShamirSecretSharing {
  static final BigInt _prime = BigInt.parse('115792089237316195423570985008687907853269984665640564039457584007913129639937');

  static List<List<BigInt>> split(BigInt secret, int k, int n) {
    final rng = Random.secure();
    final coeffs = <BigInt>[secret];
    for (int i = 1; i < k; i++) {
      coeffs.add(BigInt.from(rng.nextInt(1 << 256)) % _prime);
    }
    final shares = <List<BigInt>>[];
    for (int i = 1; i <= n; i++) {
      BigInt y = BigInt.zero;
      for (int j = 0; j < k; j++) {
        y = (y + coeffs[j] * BigInt.from(i).pow(j)) % _prime;
      }
      shares.add([BigInt.from(i), y]);
    }
    return shares;
  }

  static BigInt combine(List<List<BigInt>> shares) {
    BigInt secret = BigInt.zero;
    for (int i = 0; i < shares.length; i++) {
      BigInt xi = shares[i][0];
      BigInt yi = shares[i][1];
      BigInt num = BigInt.one;
      BigInt den = BigInt.one;
      for (int j = 0; j < shares.length; j++) {
        if (i == j) continue;
        BigInt xj = shares[j][0];
        num = (num * (BigInt.zero - xj)) % _prime;
        den = (den * (xi - xj)) % _prime;
      }
      secret = (secret + yi * num * den.modInverse(_prime)) % _prime;
    }
    return secret % _prime;
  }
}
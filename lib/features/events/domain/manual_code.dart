import 'dart:math';

/// Same charset/shape as the join-code generator: unambiguous when printed
/// and typed back in manually (no 0/O/1/I).
const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateManualCode(Random random, {int length = 6}) {
  return List.generate(length, (_) => _codeChars[random.nextInt(_codeChars.length)]).join();
}

/// Mirrors the player app's Journal.normalizeCode — trimmed, uppercased,
/// non-alphanumeric stripped — so printed formatting doesn't affect matching.
String normalizeManualCode(String raw) {
  return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

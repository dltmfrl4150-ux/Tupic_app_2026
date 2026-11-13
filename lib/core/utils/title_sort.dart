/// Natural, case-insensitive title compare for playback queues.
///
/// - Digits compare as numbers (`2` before `10`).
/// - Latin letters fold case; Hangul keeps code-unit (가나다) order.
/// - Blank titles sort after non-blank titles (caller may negate for desc).
int compareNaturalTitles(String a, String b) {
  final left = a.trim();
  final right = b.trim();
  if (left.isEmpty && right.isEmpty) return 0;
  if (left.isEmpty) return 1;
  if (right.isEmpty) return -1;

  var i = 0;
  var j = 0;
  while (i < left.length && j < right.length) {
    final ca = left.codeUnitAt(i);
    final cb = right.codeUnitAt(j);
    final da = _isDigit(ca);
    final db = _isDigit(cb);

    if (da && db) {
      var endA = i;
      while (endA < left.length && _isDigit(left.codeUnitAt(endA))) {
        endA++;
      }
      var endB = j;
      while (endB < right.length && _isDigit(right.codeUnitAt(endB))) {
        endB++;
      }
      final numA = int.tryParse(left.substring(i, endA)) ?? 0;
      final numB = int.tryParse(right.substring(j, endB)) ?? 0;
      final byNum = numA.compareTo(numB);
      if (byNum != 0) return byNum;
      final byLen = (endA - i).compareTo(endB - j);
      if (byLen != 0) return byLen;
      i = endA;
      j = endB;
      continue;
    }

    final fa = _foldAscii(ca);
    final fb = _foldAscii(cb);
    if (fa != fb) return fa.compareTo(fb);
    i++;
    j++;
  }
  return (left.length - i).compareTo(right.length - j);
}

bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

int _foldAscii(int codeUnit) {
  if (codeUnit >= 0x41 && codeUnit <= 0x5A) {
    return codeUnit + 0x20;
  }
  return codeUnit;
}

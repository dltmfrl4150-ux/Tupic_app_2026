/// Lightweight access gate based on birth year only — not legal age verification.
bool passesParentalGate(int birthYear, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (birthYear < 1900 || birthYear > current.year) {
    return false;
  }
  return (current.year - birthYear) >= 18;
}

int? parseBirthYear(String input) {
  final trimmed = input.trim();
  if (trimmed.length != 4) return null;
  return int.tryParse(trimmed);
}

/// Parental gate is required only when leaving a kids channel for a general
/// channel during playback. Management screens never use this.
bool requiresParentalGateForChannelSwitch({
  required bool fromKidsChannel,
  required bool toKidsChannel,
}) {
  return fromKidsChannel && !toKidsChannel;
}

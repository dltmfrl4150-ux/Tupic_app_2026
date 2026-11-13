import 'package:flutter/foundation.dart';

/// Debug-only developer Premium test access.
///
/// Configure UIDs locally (never commit real values):
/// ```
/// flutter run --dart-define=TUPIC_DEV_PREMIUM_UIDS=your_firebase_uid
/// ```
/// or
/// ```
/// flutter run --dart-define-from-file=tool/dev_premium.defines.json
/// ```
/// (`tool/dev_premium.defines.json` is gitignored; copy from the `.example` file.)
///
/// Release builds always return false. Matching UID alone never grants paid
/// production entitlements — only this debug test path uses PlanLimits.
List<String> configuredDevPremiumUids({String? rawOverride}) {
  final raw =
      rawOverride ??
      const String.fromEnvironment('TUPIC_DEV_PREMIUM_UIDS', defaultValue: '');
  if (raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

/// Whether the signed-in Firebase Auth UID may use debug Premium test limits.
bool hasDevPremiumTestAccess({
  required String? firebaseUid,
  bool? debugModeOverride,
  List<String>? allowedUidsOverride,
  String? rawDefineOverride,
}) {
  final isDebug = debugModeOverride ?? kDebugMode;
  if (!isDebug) return false;

  final uid = firebaseUid?.trim();
  if (uid == null || uid.isEmpty) return false;

  final allowed =
      allowedUidsOverride ??
      configuredDevPremiumUids(rawOverride: rawDefineOverride);
  if (allowed.isEmpty) return false;

  return allowed.contains(uid);
}

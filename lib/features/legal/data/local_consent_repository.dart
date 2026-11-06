import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/consent_record.dart';
import '../domain/legal_document.dart';

const consentRecordsKey = 'tupic_consent_records_v1';

/// Local-only consent store. Not a server-verified legal evidence log.
class LocalConsentRepository {
  LocalConsentRepository({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<List<ConsentRecord>> loadRecords() async {
    final prefs = await _prefs;
    final raw = prefs.getString(consentRecordsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <ConsentRecord>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final record = ConsentRecord.fromJson(item);
          if (record != null) out.add(record);
        } else if (item is Map) {
          final record = ConsentRecord.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          );
          if (record != null) out.add(record);
        }
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> hasConsented({
    required String itemId,
    required String documentVersion,
  }) async {
    final records = await loadRecords();
    return records.any(
      (r) => r.itemId == itemId && r.documentVersion == documentVersion,
    );
  }

  Future<bool> hasAcceptedCurrentTerms() {
    return hasConsented(
      itemId: LegalDocumentIds.termsOfService,
      documentVersion: LegalDocumentVersions.termsOfService,
    );
  }

  /// Appends consent records only for an explicit accept action.
  /// Viewing a document must not call this.
  Future<void> recordConsents(List<ConsentRecord> newRecords) async {
    if (newRecords.isEmpty) return;
    final prefs = await _prefs;
    final existing = await loadRecords();
    final merged = [...existing, ...newRecords];
    await prefs.setString(
      consentRecordsKey,
      jsonEncode(merged.map((e) => e.toJson()).toList()),
    );
  }
}

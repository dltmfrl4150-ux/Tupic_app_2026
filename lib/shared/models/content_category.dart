enum ContentCategory {
  all,
  english,
  music,
  science,
  art,
  animals,
  other,
}

extension ContentCategoryX on ContentCategory {
  String get storageKey => name;
}

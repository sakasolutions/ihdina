/// Inhaltstyp eines Eintrags in [assets/data/duas.json].
enum DuaType {
  dua,
  anleitung,
  koranvers,
  hinweis;

  String toJson() => name;

  static DuaType fromJson(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'anleitung':
        return DuaType.anleitung;
      case 'koranvers':
        return DuaType.koranvers;
      case 'hinweis':
        return DuaType.hinweis;
      case 'dua':
        return DuaType.dua;
      default:
        return DuaType.dua;
    }
  }
}

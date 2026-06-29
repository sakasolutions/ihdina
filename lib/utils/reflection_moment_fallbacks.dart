/// Offline-Impulse, wenn `/api/v1/reflection-moment` nicht erreichbar ist.
class ReflectionMomentFallbacks {
  ReflectionMomentFallbacks._();

  static const List<String> daily = [
    'Zwischen zwei Gebeten liegt oft der wertvollste Moment: nicht perfekt sein, sondern aufrichtig zurückkommen. Was wäre heute ein kleiner Schritt in diese Richtung?',
    'Manchmal reicht es, den Tag bewusst anzunehmen — mit Dankbarkeit für das, was da ist, und Geduld mit dem, was noch fehlt. Wofür bist du heute wirklich dankbar?',
    'Stille ist kein Leerlauf. Sie kann Raum sein, um neu zu sortieren, was im Herzen wichtig ist. Wo brauchst du heute etwas mehr Ruhe?',
    'Ein ehrliches Bittgebet braucht keine langen Worte. Gott kennt die Absicht — oft früher als wir sie selbst verstehen. Was möchtest du heute leise anvertrauen?',
    'Kleine Gewohnheiten tragen: ein kurzer Moment der Aufmerksamkeit vor dem Gebet, ein freundliches Wort, eine unterbrochene Ungeduld. Welche kleine Sache willst du heute bewusst wählen?',
    'Du musst heute nicht alles lösen. Manchmal ist Stärke, stehenzubleiben und wieder anzufangen. Was darf heute einfacher werden?',
    'Wer anderen begegnet, begegnet oft auch sich selbst. Achtsamkeit im Umgang mit Menschen ist auch Gottesdienst im Kleinen. Wen kannst du heute etwas leichter machen?',
    'Der Koran lädt nicht zu Hast ein, sondern zu Tiefe. Ein Vers, ein Atemzug, eine ehrliche Frage — das kann den Tag verändern. Welche Frage nimmst du heute mit?',
  ];

  static const List<String> friday = [
    'Freitag ist ein Tag der Gemeinschaft: Viele gehen zur Jumuʿah — nicht nur wegen einer Predigt, sondern weil das Gebet uns aneinander erinnert. Was nimmst du heute aus der Gemeinschaft mit?',
    'Vor dem Freitagsgebet lohnt sich ein kurzer Moment der Besinnung: Herunterfahren, Absicht klären, dem Herzen zuhören. Wie möchtest du heute bewusst in den Tag gehen?',
    'Jumuʿah verbindet: unterschiedliche Wege, ein gemeinsamer Ruf zur Nähe zu Gott. Du musst nicht alles allein tragen. Wo darfst du heute Unterstützung annehmen?',
    'Freitag kann mehr sein als ein Termin im Kalender — er kann eine Einladung sein, das Wesentliche neu zu sortieren. Was soll heute nicht unter Eile verloren gehen?',
    'Die Gemeinde ist nicht perfekt — und doch ein Ort, an dem Aufrichtigkeit wächst. Ein Lächeln, ein Gruß, eine geduldige Geste zählen. Wen wirst du heute bewusst wahrnehmen?',
    'Manchmal kommt Berührung durch ein Gebet in der Reihe neben Fremden — und genau das erinnert: Wir sind verbunden. Was bedeutet dir Gemeinschaft heute?',
    'Freitag lädt ein, Dankbarkeit zu sammeln: für den Tag, für Gesundheit, für einen neuen Anfang nach Fehlern. Wofür sagst du heute innerlich Danke?',
    'Ein ruhiger Moment vor dem Gebet kann tiefer wirken als viele Worte danach. Was möchtest du Gott heute ohne Umschweife sagen?',
  ];

  static String pick({required bool isFriday}) {
    final list = isFriday ? friday : daily;
    final i = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return list[i % list.length];
  }
}

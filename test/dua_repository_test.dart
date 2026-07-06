import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ihdina/data/dua/dua_entry.dart';
import 'package:ihdina/data/dua/dua_repository.dart';
import 'package:ihdina/data/dua/dua_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DuaRepository.resetCacheForTest();
  });

  test('duas.json lädt 87 Einträge mit meta', () async {
    final data = await DuaRepository.instance.load();
    expect(data.meta.schemaVersion, 1);
    expect(data.meta.locale, 'de');
    expect(data.entries.length, 87);
    expect(data.byId[1]?.category, 'Aufwachen aus dem Schlaf');
  });

  test('getBySituation filtert nach situation-Tag', () async {
    final morgen = await DuaRepository.instance.getBySituation('morgen');
    expect(morgen.every((e) => e.situation.contains('morgen')), isTrue);
    expect(morgen.length, greaterThan(0));

    final reise = await DuaRepository.instance.getBySituation('reise');
    expect(reise.every((e) => e.situation.contains('reise')), isTrue);
    expect(reise.map((e) => e.id).toSet(), {206, 207, 208, 217});
  });

  test('DuaType.fromJson fällt auf dua bei unbekanntem Wert', () {
    expect(DuaType.fromJson('anleitung'), DuaType.anleitung);
    expect(DuaType.fromJson('koranvers'), DuaType.koranvers);
    expect(DuaType.fromJson('hinweis'), DuaType.hinweis);
    expect(DuaType.fromJson('dua'), DuaType.dua);
    expect(DuaType.fromJson('unknown'), DuaType.dua);
    expect(DuaType.fromJson(null), DuaType.dua);
  });

  test('filterSearch priorisiert german/category/arabic vor source_raw', () {
    const entries = [
      DuaEntry(
        id: 1,
        chapter: 1,
        category: 'Test',
        german: 'O Allah, vergib mir.',
        arabic: 'arabisch',
        sourceRaw: 'Muslim 4/2071',
        type: DuaType.dua,
      ),
      DuaEntry(
        id: 2,
        chapter: 1,
        category: 'Andere',
        german: 'Unrelated text.',
        arabic: 'arabisch zwei',
        sourceRaw: 'Muslim 4/2071',
        type: DuaType.dua,
      ),
    ];

    final sourceHits = DuaRepository.filterSearch(entries, 'Muslim');
    expect(sourceHits.map((e) => e.id).toList(), [1, 2]);

    final primaryFirst = DuaRepository.filterSearch(entries, 'vergib');
    expect(primaryFirst.map((e) => e.id).toList(), [1]);

    const mixed = [
      DuaEntry(
        id: 10,
        chapter: 1,
        category: 'Reise',
        german: 'Bittgebet für die Reise.',
        arabic: 'arabisch',
        sourceRaw: 'At-Tirmidhi 5/491',
        type: DuaType.dua,
      ),
      DuaEntry(
        id: 11,
        chapter: 1,
        category: 'Markt',
        german: 'Allgemeiner Text.',
        arabic: 'arabisch',
        sourceRaw: 'At-Tirmidhi 5/491',
        type: DuaType.dua,
      ),
    ];
    final primaryBeforeSource =
        DuaRepository.filterSearch(mixed, 'Reise');
    expect(primaryBeforeSource.map((e) => e.id).toList(), [10]);

    const sourceRanking = [
      DuaEntry(
        id: 20,
        chapter: 1,
        category: 'X',
        german: 'Überliefert bei At-Tirmidhi.',
        arabic: 'arabisch',
        sourceRaw: 'Sonstige Quelle',
        type: DuaType.dua,
      ),
      DuaEntry(
        id: 21,
        chapter: 1,
        category: 'Y',
        german: 'Neutraler Text.',
        arabic: 'arabisch',
        sourceRaw: 'At-Tirmidhi 5/491',
        type: DuaType.dua,
      ),
    ];
    final ranked = DuaRepository.filterSearch(sourceRanking, 'Tirmidhi');
    expect(ranked.map((e) => e.id).toList(), [20, 21]);
  });
}

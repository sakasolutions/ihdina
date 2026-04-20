// ignore_for_file: avoid_print
/// One-time SQLite DB generator for Ihdina. Pure Dart CLI; run: dart run tools/generate_db.dart
/// Uses sqflite_common_ffi. Output: tools/output/ihdina.db (copy to assets/db/ihdina.db).

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// --- Input path: try Layout 1 (sura|ayah|text) or Layout 3 (one verse per line in order).
const inputPath = 'assets/tanzil/quran-uthmani.txt';
const translitPath = 'assets/tanzil/en.transliteration.txt';
const surahsDirPath = 'assets/quran/surahs';

/// Strips HTML-like tags (e.g. <u>, <b>, <i>) from Tanzil transliteration for plain text.
String _stripTranslitTags(String s) {
  return s.replaceAll(RegExp(r'<[^>]*>'), '').trim();
}

/// Parses en.transliteration.txt (sura|ayah|translit). Returns map keyed by 'surahId_ayahNumber'.
Map<String, String> _parseTransliterationFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final result = <String, String>{};
  final lines = file.readAsStringSync().split('\n');
  for (final line in lines) {
    final parts = line.split('|');
    if (parts.length < 3) continue;
    final surahId = int.tryParse(parts[0].trim()) ?? 0;
    final ayahNumber = int.tryParse(parts[1].trim()) ?? 0;
    final translit = _stripTranslitTags(parts.sublist(2).join('|').trim());
    if (surahId <= 0 || ayahNumber <= 0) continue;
    result['${surahId}_$ayahNumber'] = translit;
  }
  return result;
}

/// 114 surahs: id, name_ar, name_en, revelation_type, ayah_count (standard Tanzil).
final List<Map<String, dynamic>> surahMetadata = [
  {'id': 1, 'name_ar': 'الفاتحة', 'name_en': 'Al-Fatihah', 'revelation_type': 'Meccan', 'ayah_count': 7},
  {'id': 2, 'name_ar': 'البقرة', 'name_en': 'Al-Baqarah', 'revelation_type': 'Medinan', 'ayah_count': 286},
  {'id': 3, 'name_ar': 'آل عمران', 'name_en': "Ali 'Imran", 'revelation_type': 'Medinan', 'ayah_count': 200},
  {'id': 4, 'name_ar': 'النساء', 'name_en': 'An-Nisa', 'revelation_type': 'Medinan', 'ayah_count': 176},
  {'id': 5, 'name_ar': 'المائدة', 'name_en': "Al-Ma'idah", 'revelation_type': 'Medinan', 'ayah_count': 120},
  {'id': 6, 'name_ar': 'الأنعام', 'name_en': "Al-An'am", 'revelation_type': 'Meccan', 'ayah_count': 165},
  {'id': 7, 'name_ar': 'الأعراف', 'name_en': "Al-A'raf", 'revelation_type': 'Meccan', 'ayah_count': 206},
  {'id': 8, 'name_ar': 'الأنفال', 'name_en': 'Al-Anfal', 'revelation_type': 'Medinan', 'ayah_count': 75},
  {'id': 9, 'name_ar': 'التوبة', 'name_en': 'At-Tawbah', 'revelation_type': 'Medinan', 'ayah_count': 129},
  {'id': 10, 'name_ar': 'يونس', 'name_en': 'Yunus', 'revelation_type': 'Meccan', 'ayah_count': 109},
  {'id': 11, 'name_ar': 'هود', 'name_en': 'Hud', 'revelation_type': 'Meccan', 'ayah_count': 123},
  {'id': 12, 'name_ar': 'يوسف', 'name_en': 'Yusuf', 'revelation_type': 'Meccan', 'ayah_count': 111},
  {'id': 13, 'name_ar': 'الرعد', 'name_en': "Ar-Ra'd", 'revelation_type': 'Medinan', 'ayah_count': 43},
  {'id': 14, 'name_ar': 'إبراهيم', 'name_en': 'Ibrahim', 'revelation_type': 'Meccan', 'ayah_count': 52},
  {'id': 15, 'name_ar': 'الحجر', 'name_en': 'Al-Hijr', 'revelation_type': 'Meccan', 'ayah_count': 99},
  {'id': 16, 'name_ar': 'النحل', 'name_en': "An-Nahl", 'revelation_type': 'Meccan', 'ayah_count': 128},
  {'id': 17, 'name_ar': 'الإسراء', 'name_en': 'Al-Isra', 'revelation_type': 'Meccan', 'ayah_count': 111},
  {'id': 18, 'name_ar': 'الكهف', 'name_en': 'Al-Kahf', 'revelation_type': 'Meccan', 'ayah_count': 110},
  {'id': 19, 'name_ar': 'مريم', 'name_en': 'Maryam', 'revelation_type': 'Meccan', 'ayah_count': 98},
  {'id': 20, 'name_ar': 'طه', 'name_en': 'Ta Ha', 'revelation_type': 'Meccan', 'ayah_count': 135},
  {'id': 21, 'name_ar': 'الأنبياء', 'name_en': 'Al-Anbya', 'revelation_type': 'Meccan', 'ayah_count': 112},
  {'id': 22, 'name_ar': 'الحج', 'name_en': 'Al-Hajj', 'revelation_type': 'Medinan', 'ayah_count': 78},
  {'id': 23, 'name_ar': 'المؤمنون', 'name_en': 'Al-Mu\'minun', 'revelation_type': 'Meccan', 'ayah_count': 118},
  {'id': 24, 'name_ar': 'النور', 'name_en': 'An-Nur', 'revelation_type': 'Medinan', 'ayah_count': 64},
  {'id': 25, 'name_ar': 'الفرقان', 'name_en': 'Al-Furqan', 'revelation_type': 'Meccan', 'ayah_count': 77},
  {'id': 26, 'name_ar': 'الشعراء', 'name_en': 'Ash-Shu\'ara', 'revelation_type': 'Meccan', 'ayah_count': 227},
  {'id': 27, 'name_ar': 'النمل', 'name_en': 'An-Naml', 'revelation_type': 'Meccan', 'ayah_count': 93},
  {'id': 28, 'name_ar': 'القصص', 'name_en': 'Al-Qasas', 'revelation_type': 'Meccan', 'ayah_count': 88},
  {'id': 29, 'name_ar': 'العنكبوت', 'name_en': "Al-'Ankabut", 'revelation_type': 'Meccan', 'ayah_count': 69},
  {'id': 30, 'name_ar': 'الروم', 'name_en': 'Ar-Rum', 'revelation_type': 'Meccan', 'ayah_count': 60},
  {'id': 31, 'name_ar': 'لقمان', 'name_en': 'Luqman', 'revelation_type': 'Meccan', 'ayah_count': 34},
  {'id': 32, 'name_ar': 'السجدة', 'name_en': 'As-Sajdah', 'revelation_type': 'Meccan', 'ayah_count': 30},
  {'id': 33, 'name_ar': 'الأحزاب', 'name_en': 'Al-Ahzab', 'revelation_type': 'Medinan', 'ayah_count': 73},
  {'id': 34, 'name_ar': 'سبأ', 'name_en': 'Saba', 'revelation_type': 'Meccan', 'ayah_count': 54},
  {'id': 35, 'name_ar': 'فاطر', 'name_en': 'Fatir', 'revelation_type': 'Meccan', 'ayah_count': 45},
  {'id': 36, 'name_ar': 'يس', 'name_en': 'Ya-Sin', 'revelation_type': 'Meccan', 'ayah_count': 83},
  {'id': 37, 'name_ar': 'الصافات', 'name_en': 'As-Saffat', 'revelation_type': 'Meccan', 'ayah_count': 182},
  {'id': 38, 'name_ar': 'ص', 'name_en': 'Sad', 'revelation_type': 'Meccan', 'ayah_count': 88},
  {'id': 39, 'name_ar': 'الزمر', 'name_en': 'Az-Zumar', 'revelation_type': 'Meccan', 'ayah_count': 75},
  {'id': 40, 'name_ar': 'غافر', 'name_en': 'Ghafir', 'revelation_type': 'Meccan', 'ayah_count': 85},
  {'id': 41, 'name_ar': 'فصلت', 'name_en': 'Fussilat', 'revelation_type': 'Meccan', 'ayah_count': 54},
  {'id': 42, 'name_ar': 'الشورى', 'name_en': 'Ash-Shura', 'revelation_type': 'Meccan', 'ayah_count': 53},
  {'id': 43, 'name_ar': 'الزخرف', 'name_en': 'Az-Zukhruf', 'revelation_type': 'Meccan', 'ayah_count': 89},
  {'id': 44, 'name_ar': 'الدخان', 'name_en': 'Ad-Dukhan', 'revelation_type': 'Meccan', 'ayah_count': 59},
  {'id': 45, 'name_ar': 'الجاثية', 'name_en': 'Al-Jathiyah', 'revelation_type': 'Meccan', 'ayah_count': 37},
  {'id': 46, 'name_ar': 'الأحقاف', 'name_en': 'Al-Ahqaf', 'revelation_type': 'Meccan', 'ayah_count': 35},
  {'id': 47, 'name_ar': 'محمد', 'name_en': 'Muhammad', 'revelation_type': 'Medinan', 'ayah_count': 38},
  {'id': 48, 'name_ar': 'الفتح', 'name_en': 'Al-Fath', 'revelation_type': 'Medinan', 'ayah_count': 29},
  {'id': 49, 'name_ar': 'الحجرات', 'name_en': 'Al-Hujurat', 'revelation_type': 'Medinan', 'ayah_count': 18},
  {'id': 50, 'name_ar': 'ق', 'name_en': 'Qaf', 'revelation_type': 'Meccan', 'ayah_count': 45},
  {'id': 51, 'name_ar': 'الذاريات', 'name_en': 'Adh-Dhariyat', 'revelation_type': 'Meccan', 'ayah_count': 60},
  {'id': 52, 'name_ar': 'الطور', 'name_en': 'At-Tur', 'revelation_type': 'Meccan', 'ayah_count': 49},
  {'id': 53, 'name_ar': 'النجم', 'name_en': 'An-Najm', 'revelation_type': 'Meccan', 'ayah_count': 62},
  {'id': 54, 'name_ar': 'القمر', 'name_en': 'Al-Qamar', 'revelation_type': 'Meccan', 'ayah_count': 55},
  {'id': 55, 'name_ar': 'الرحمن', 'name_en': 'Ar-Rahman', 'revelation_type': 'Medinan', 'ayah_count': 78},
  {'id': 56, 'name_ar': 'الواقعة', 'name_en': "Al-Waqi'ah", 'revelation_type': 'Meccan', 'ayah_count': 96},
  {'id': 57, 'name_ar': 'الحديد', 'name_en': 'Al-Hadid', 'revelation_type': 'Medinan', 'ayah_count': 29},
  {'id': 58, 'name_ar': 'المجادلة', 'name_en': 'Al-Mujadila', 'revelation_type': 'Medinan', 'ayah_count': 22},
  {'id': 59, 'name_ar': 'الحشر', 'name_en': 'Al-Hashr', 'revelation_type': 'Medinan', 'ayah_count': 24},
  {'id': 60, 'name_ar': 'الممتحنة', 'name_en': 'Al-Mumtahanah', 'revelation_type': 'Medinan', 'ayah_count': 13},
  {'id': 61, 'name_ar': 'الصف', 'name_en': 'As-Saf', 'revelation_type': 'Medinan', 'ayah_count': 14},
  {'id': 62, 'name_ar': 'الجمعة', 'name_en': "Al-Jumu'ah", 'revelation_type': 'Medinan', 'ayah_count': 11},
  {'id': 63, 'name_ar': 'المنافقون', 'name_en': 'Al-Munafiqun', 'revelation_type': 'Medinan', 'ayah_count': 11},
  {'id': 64, 'name_ar': 'التغابن', 'name_en': 'At-Taghabun', 'revelation_type': 'Medinan', 'ayah_count': 18},
  {'id': 65, 'name_ar': 'الطلاق', 'name_en': 'At-Talaq', 'revelation_type': 'Medinan', 'ayah_count': 12},
  {'id': 66, 'name_ar': 'التحريم', 'name_en': 'At-Tahrim', 'revelation_type': 'Medinan', 'ayah_count': 12},
  {'id': 67, 'name_ar': 'الملك', 'name_en': 'Al-Mulk', 'revelation_type': 'Meccan', 'ayah_count': 30},
  {'id': 68, 'name_ar': 'القلم', 'name_en': 'Al-Qalam', 'revelation_type': 'Meccan', 'ayah_count': 52},
  {'id': 69, 'name_ar': 'الحاقة', 'name_en': 'Al-Haqqah', 'revelation_type': 'Meccan', 'ayah_count': 52},
  {'id': 70, 'name_ar': 'المعارج', 'name_en': "Al-Ma'arij", 'revelation_type': 'Meccan', 'ayah_count': 44},
  {'id': 71, 'name_ar': 'نوح', 'name_en': 'Nuh', 'revelation_type': 'Meccan', 'ayah_count': 28},
  {'id': 72, 'name_ar': 'الجن', 'name_en': 'Al-Jinn', 'revelation_type': 'Meccan', 'ayah_count': 28},
  {'id': 73, 'name_ar': 'المزمل', 'name_en': 'Al-Muzzammil', 'revelation_type': 'Meccan', 'ayah_count': 20},
  {'id': 74, 'name_ar': 'المدثر', 'name_en': 'Al-Muddaththir', 'revelation_type': 'Meccan', 'ayah_count': 56},
  {'id': 75, 'name_ar': 'القيامة', 'name_en': 'Al-Qiyamah', 'revelation_type': 'Meccan', 'ayah_count': 40},
  {'id': 76, 'name_ar': 'الإنسان', 'name_en': 'Al-Insan', 'revelation_type': 'Medinan', 'ayah_count': 31},
  {'id': 77, 'name_ar': 'المرسلات', 'name_en': 'Al-Mursalat', 'revelation_type': 'Meccan', 'ayah_count': 50},
  {'id': 78, 'name_ar': 'النبأ', 'name_en': 'An-Naba', 'revelation_type': 'Meccan', 'ayah_count': 40},
  {'id': 79, 'name_ar': 'النازعات', 'name_en': "An-Nazi'at", 'revelation_type': 'Meccan', 'ayah_count': 46},
  {'id': 80, 'name_ar': 'عبس', 'name_en': 'Abasa', 'revelation_type': 'Meccan', 'ayah_count': 42},
  {'id': 81, 'name_ar': 'التكوير', 'name_en': 'At-Takwir', 'revelation_type': 'Meccan', 'ayah_count': 29},
  {'id': 82, 'name_ar': 'الانفطار', 'name_en': 'Al-Infitar', 'revelation_type': 'Meccan', 'ayah_count': 19},
  {'id': 83, 'name_ar': 'المطففين', 'name_en': 'Al-Mutaffifin', 'revelation_type': 'Meccan', 'ayah_count': 36},
  {'id': 84, 'name_ar': 'الانشقاق', 'name_en': 'Al-Inshiqaq', 'revelation_type': 'Meccan', 'ayah_count': 25},
  {'id': 85, 'name_ar': 'البروج', 'name_en': 'Al-Buruj', 'revelation_type': 'Meccan', 'ayah_count': 22},
  {'id': 86, 'name_ar': 'الطارق', 'name_en': 'At-Tariq', 'revelation_type': 'Meccan', 'ayah_count': 17},
  {'id': 87, 'name_ar': 'الأعلى', 'name_en': "Al-A'la", 'revelation_type': 'Meccan', 'ayah_count': 19},
  {'id': 88, 'name_ar': 'الغاشية', 'name_en': 'Al-Ghashiyah', 'revelation_type': 'Meccan', 'ayah_count': 26},
  {'id': 89, 'name_ar': 'الفجر', 'name_en': 'Al-Fajr', 'revelation_type': 'Meccan', 'ayah_count': 30},
  {'id': 90, 'name_ar': 'البلد', 'name_en': 'Al-Balad', 'revelation_type': 'Meccan', 'ayah_count': 20},
  {'id': 91, 'name_ar': 'الشمس', 'name_en': 'Ash-Shams', 'revelation_type': 'Meccan', 'ayah_count': 15},
  {'id': 92, 'name_ar': 'الليل', 'name_en': 'Al-Layl', 'revelation_type': 'Meccan', 'ayah_count': 21},
  {'id': 93, 'name_ar': 'الضحى', 'name_en': 'Ad-Duhaa', 'revelation_type': 'Meccan', 'ayah_count': 11},
  {'id': 94, 'name_ar': 'الشرح', 'name_en': 'Ash-Sharh', 'revelation_type': 'Meccan', 'ayah_count': 8},
  {'id': 95, 'name_ar': 'التين', 'name_en': 'At-Tin', 'revelation_type': 'Meccan', 'ayah_count': 8},
  {'id': 96, 'name_ar': 'العلق', 'name_en': 'Al-Alaq', 'revelation_type': 'Meccan', 'ayah_count': 19},
  {'id': 97, 'name_ar': 'القدر', 'name_en': 'Al-Qadr', 'revelation_type': 'Meccan', 'ayah_count': 5},
  {'id': 98, 'name_ar': 'البينة', 'name_en': 'Al-Bayyinah', 'revelation_type': 'Medinan', 'ayah_count': 8},
  {'id': 99, 'name_ar': 'الزلزلة', 'name_en': 'Az-Zalzalah', 'revelation_type': 'Medinan', 'ayah_count': 8},
  {'id': 100, 'name_ar': 'العاديات', 'name_en': "Al-'Adiyat", 'revelation_type': 'Meccan', 'ayah_count': 11},
  {'id': 101, 'name_ar': 'القارعة', 'name_en': "Al-Qari'ah", 'revelation_type': 'Meccan', 'ayah_count': 11},
  {'id': 102, 'name_ar': 'التكاثر', 'name_en': 'At-Takathur', 'revelation_type': 'Meccan', 'ayah_count': 8},
  {'id': 103, 'name_ar': 'العصر', 'name_en': "Al-'Asr", 'revelation_type': 'Meccan', 'ayah_count': 3},
  {'id': 104, 'name_ar': 'الهمزة', 'name_en': 'Al-Humazah', 'revelation_type': 'Meccan', 'ayah_count': 9},
  {'id': 105, 'name_ar': 'الفيل', 'name_en': 'Al-Fil', 'revelation_type': 'Meccan', 'ayah_count': 5},
  {'id': 106, 'name_ar': 'قريش', 'name_en': 'Quraysh', 'revelation_type': 'Meccan', 'ayah_count': 4},
  {'id': 107, 'name_ar': 'الماعون', 'name_en': "Al-Ma'un", 'revelation_type': 'Meccan', 'ayah_count': 7},
  {'id': 108, 'name_ar': 'الكوثر', 'name_en': 'Al-Kawthar', 'revelation_type': 'Meccan', 'ayah_count': 3},
  {'id': 109, 'name_ar': 'الكافرون', 'name_en': 'Al-Kafirun', 'revelation_type': 'Meccan', 'ayah_count': 6},
  {'id': 110, 'name_ar': 'النصر', 'name_en': 'An-Nasr', 'revelation_type': 'Medinan', 'ayah_count': 3},
  {'id': 111, 'name_ar': 'المسد', 'name_en': 'Al-Masad', 'revelation_type': 'Meccan', 'ayah_count': 5},
  {'id': 112, 'name_ar': 'الإخلاص', 'name_en': 'Al-Ikhlas', 'revelation_type': 'Meccan', 'ayah_count': 4},
  {'id': 113, 'name_ar': 'الفلق', 'name_en': 'Al-Falaq', 'revelation_type': 'Meccan', 'ayah_count': 5},
  {'id': 114, 'name_ar': 'الناس', 'name_en': 'An-Nas', 'revelation_type': 'Meccan', 'ayah_count': 6},
];

const expectedSurahCount = 114;
const expectedAyahCount = 6236;

void main(List<String> args) async {
  sqfliteFfiInit();

  final root = Directory.current.path;
  final outDir = p.join(root, 'tools', 'output');
  final outPath = p.join(outDir, 'ihdina.db');
  print('[GEN] outPath=$outPath');

  Directory(outDir).createSync(recursive: true);

  final inputFile = File(inputPath);
  final surahsDir = Directory(surahsDirPath);

  // Detect layout
  String layout;
  List<AyahInput> ayahs;

  if (inputFile.existsSync()) {
    final content = inputFile.readAsStringSync();
    final lines = content.split('\n');
    final nonEmpty = lines.map((s) => s.trimRight()).where((s) => s.isNotEmpty).toList();

    final first = nonEmpty.isNotEmpty ? nonEmpty.first : '';
    final isLayout1 = first.contains('|') &&
        first.split('|').length >= 3 &&
        int.tryParse(first.split('|')[0].trim()) != null &&
        int.tryParse(first.split('|')[1].trim()) != null;

    if (isLayout1) {
      layout = 'Layout 1 (sura|ayah|text)';
      ayahs = _parseLayout1(nonEmpty);
    } else if (nonEmpty.length == expectedAyahCount) {
      layout = 'Layout 3 (one verse per line in order)';
      ayahs = _parseLayout3(nonEmpty);
    } else {
      throw Exception(
        'Expected $inputPath to be Layout 1 (first line: sura|ayah|text) or '
        'Layout 3 ($expectedAyahCount lines, one verse per line). '
        'Found ${nonEmpty.length} non-empty lines. Expected paths: $inputPath or $surahsDirPath/001.txt..114.txt',
      );
    }
  } else if (surahsDir.existsSync()) {
    layout = 'Layout 2 (114 files)';
    ayahs = _parseLayout2(surahsDirPath);
  } else {
    throw Exception(
      'No input found. Expected one of: (1) File $inputPath for Layout 1 or Layout 3, '
      'or (2) Directory $surahsDirPath with 001.txt..114.txt (or 1.txt..114.txt) for Layout 2.',
    );
  }

  print('[GEN] input: $layout');
  print('[GEN] ayahs parsed: ${ayahs.length}');

  final translitMap = _parseTransliterationFile(translitPath);
  print('[GEN] transliteration entries: ${translitMap.length}');

  for (final suffix in ['', '-wal', '-shm']) {
    final f = File(outPath + suffix);
    if (f.existsSync()) f.deleteSync();
  }

  final db = await databaseFactoryFfi.openDatabase(outPath);

  await db.execute(
    'CREATE TABLE surahs(id INTEGER PRIMARY KEY, name_ar TEXT, name_en TEXT, revelation_type TEXT, ayah_count INTEGER)',
  );
  await db.execute(
    'CREATE TABLE ayahs(id INTEGER PRIMARY KEY, surah_id INTEGER, ayah_number INTEGER, text_ar TEXT, text_translit TEXT)',
  );

  for (final row in surahMetadata) {
    await db.insert(
      'surahs',
      {
        'id': row['id'],
        'name_ar': row['name_ar'],
        'name_en': row['name_en'],
        'revelation_type': row['revelation_type'],
        'ayah_count': row['ayah_count'],
      },
    );
  }

  int ayahId = 1;
  for (final a in ayahs) {
    final translit = translitMap['${a.surahId}_${a.ayahNumber}'];
    await db.insert(
      'ayahs',
      {
        'id': ayahId++,
        'surah_id': a.surahId,
        'ayah_number': a.ayahNumber,
        'text_ar': a.textAr,
        'text_translit': translit ?? '',
      },
    );
  }

  final surahCount = _firstInt(await db.rawQuery('SELECT COUNT(*) as c FROM surahs'));
  final ayahCount = _firstInt(await db.rawQuery('SELECT COUNT(*) as c FROM ayahs'));

  if (surahCount != expectedSurahCount) {
    throw Exception('Sanity: surahs count=$surahCount, expected $expectedSurahCount');
  }
  if (ayahCount != expectedAyahCount) {
    throw Exception('Sanity: ayahs count=$ayahCount, expected $expectedAyahCount');
  }

  for (final row in surahMetadata) {
    final id = row['id'] as int;
    final expected = row['ayah_count'] as int;
    final actual = _firstInt(await db.rawQuery('SELECT COUNT(*) as c FROM ayahs WHERE surah_id = ?', [id]));
    if (actual != expected) {
      throw Exception('Sanity: surah $id ayah count=$actual, expected $expected');
    }
  }

  await db.execute('PRAGMA wal_checkpoint(FULL);');
  await db.close();

  final outFile = File(outPath);
  print('[GEN] exists after close: ${outFile.existsSync()}');
  if (outFile.existsSync()) {
    print('[GEN] size bytes: ${outFile.lengthSync()}');
  } else {
    throw Exception('Database file was not created at $outPath');
  }

  print('[GEN] surahs=$surahCount ok');
  print('[GEN] ayahs=$ayahCount ok');
  print('[GEN] wrote $outPath');
}

int _firstInt(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return 0;
  final v = rows.first['c'];
  if (v == null) return 0;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? 0;
}

class AyahInput {
  AyahInput({required this.surahId, required this.ayahNumber, required this.textAr});
  final int surahId;
  final int ayahNumber;
  final String textAr;
}

List<AyahInput> _parseLayout1(List<String> lines) {
  final result = <AyahInput>[];
  for (final line in lines) {
    final parts = line.split('|');
    if (parts.length < 3) continue;
    final surahId = int.tryParse(parts[0].trim()) ?? 0;
    final ayahNumber = int.tryParse(parts[1].trim()) ?? 0;
    final textAr = parts.sublist(2).join('|').trimRight();
    if (surahId <= 0 || ayahNumber <= 0) continue;
    result.add(AyahInput(surahId: surahId, ayahNumber: ayahNumber, textAr: textAr));
  }
  return result;
}

List<AyahInput> _parseLayout3(List<String> lines) {
  final result = <AyahInput>[];
  var offset = 0;
  for (final row in surahMetadata) {
    final surahId = row['id'] as int;
    final ayahCount = row['ayah_count'] as int;
    for (var a = 1; a <= ayahCount; a++) {
      if (offset >= lines.length) break;
      result.add(AyahInput(
        surahId: surahId,
        ayahNumber: a,
        textAr: lines[offset].trimRight(),
      ));
      offset++;
    }
  }
  return result;
}

List<AyahInput> _parseLayout2(String dirPath) {
  final result = <AyahInput>[];
  for (var s = 1; s <= 114; s++) {
    final padded = s.toString().padLeft(3, '0');
    final file1 = File(p.join(dirPath, '$padded.txt'));
    final file2 = File(p.join(dirPath, '$s.txt'));
    final file = file1.existsSync() ? file1 : (file2.existsSync() ? file2 : null);
    if (file == null || !file.existsSync()) {
      throw Exception('Layout 2: missing file for surah $s (tried $padded.txt and $s.txt in $dirPath)');
    }
    final lines = file.readAsStringSync().split('\n');
    var ayahNumber = 1;
    for (final line in lines) {
      final t = line.trimRight();
      if (t.isEmpty) continue;
      result.add(AyahInput(surahId: s, ayahNumber: ayahNumber++, textAr: t));
    }
  }
  return result;
}

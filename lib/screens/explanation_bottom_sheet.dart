import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter, PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ai/ai_service.dart';
import '../data/ai/related_ayah_ref.dart';
import '../data/api/ihdina_api_client.dart';
import '../data/quran/quran_repository.dart';
import '../models/surah.dart';
import '../services/install_id_service.dart';
import '../services/revenuecat_service.dart';
import 'paywall_screen.dart';
import 'quran_reader_screen.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);
/// Vor Store-Launch `true`: Eingabefeld immer, unabhängig von `--dart-define`.
/// Vor Release auf `false`; dann wie Server über [_kAllowFreeFollowups].
const bool _followUpsFreeBeta = true;

/// Wenn [_followUpsFreeBeta] false: Folgefragen ohne Pro (default an).
/// Production: `--dart-define=ALLOW_FREE_FOLLOWUPS=false`.
const bool _kAllowFreeFollowups = bool.fromEnvironment(
  'ALLOW_FREE_FOLLOWUPS',
  defaultValue: true,
);

/// Strukturierte Vers-Erklärung (JSON vom Backend im Feld `text`).
class VerseCards {
  VerseCards({
    required this.bedeutung,
    required this.kontext,
    required this.heute,
    this.relatedAyahs = const [],
  });

  final String bedeutung;
  final String kontext;
  final String heute;
  final List<RelatedAyahRef> relatedAyahs;
}

/// Öffnet die KI-Erklärung: Tagesvers immer frei; Pro immer frei; Free: Paywall wenn Backend kein Extra-Kontingent mehr meldet.
Future<void> showAiExplanationWithQuotaCheck(
  BuildContext context, {
  String? verseTitle,
  String? surahName,
  int? ayahNumber,
  String? textAr,
  String? textDe,
  bool isFreeDailyVerse = false,
  bool showVerseHeader = true,
}) async {
  if (isFreeDailyVerse) {
    showExplanationBottomSheet(
      context,
      verseTitle: verseTitle,
      surahName: surahName,
      ayahNumber: ayahNumber,
      textAr: textAr,
      textDe: textDe,
      isFreeDailyVerse: true,
      showVerseHeader: showVerseHeader,
    );
    return;
  }
  if (RevenueCatService.isPro) {
    if (!context.mounted) return;
    showExplanationBottomSheet(
      context,
      verseTitle: verseTitle,
      surahName: surahName,
      ayahNumber: ayahNumber,
      textAr: textAr,
      textDe: textDe,
      isFreeDailyVerse: false,
      showVerseHeader: showVerseHeader,
    );
    return;
  }

  // Bereits gecachte Erklärung: kein Entitlement-Call, Sheet direkt öffnen.
  if (surahName != null &&
      surahName.isNotEmpty &&
      ayahNumber != null) {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(AIService.cacheKey(surahName, ayahNumber));
    if (cached != null && cached.trim().isNotEmpty) {
      if (!context.mounted) return;
      showExplanationBottomSheet(
        context,
        verseTitle: verseTitle,
        surahName: surahName,
        ayahNumber: ayahNumber,
        textAr: textAr,
        textDe: textDe,
        isFreeDailyVerse: false,
        showVerseHeader: showVerseHeader,
      );
      return;
    }
  }

  final api = IhdinaApiClient.instance;
  if (api.isConfigured) {
    try {
      final installId = await InstallIdService.instance.getOrCreate();
      final ent = await api.fetchEntitlement(installId);
      final raw = ent['freeExtraRemainingToday'];
      final int? freeExtra = raw == null
          ? null
          : (raw is int ? raw : (raw is num ? raw.toInt() : null));
      if (!context.mounted) return;
      if (freeExtra != null && freeExtra <= 0) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
        );
        return;
      }
    } catch (_) {
      // Bei Netzwerkfehler: Sheet öffnen, Fehler dort anzeigen.
    }
  }

  if (!context.mounted) return;
  showExplanationBottomSheet(
    context,
    verseTitle: verseTitle,
    surahName: surahName,
    ayahNumber: ayahNumber,
    textAr: textAr,
    textDe: textDe,
    isFreeDailyVerse: false,
    showVerseHeader: showVerseHeader,
  );
}

/// Single chat entry: user or assistant.
class ChatMessage {
  const ChatMessage({
    required this.isUser,
    required this.text,
    this.relatedAyahs,
  });

  final bool isUser;
  final String text;
  /// Chips unter einer Assistant-Folgeantwort (Server-Feld `relatedAyahs`).
  final List<RelatedAyahRef>? relatedAyahs;
}

/// Verse data for AI explanation. If all are provided, the sheet will call the AI.
class VerseExplanationParams {
  const VerseExplanationParams({
    required this.verseTitle,
    this.surahName,
    this.ayahNumber,
    this.textAr,
    this.textDe,
    this.isFreeDailyVerse = false,
    this.showVerseHeader = true,
  });

  final String verseTitle;
  final String? surahName;
  final int? ayahNumber;
  final String? textAr;
  final String? textDe;
  /// Tagesvers: zählt nicht gegen das tägliche Free-Kontingent.
  final bool isFreeDailyVerse;

  /// `true`: Arabisch + Deutsch + Trennlinie oben (z. B. Tagesvers). `false`: Leser (nur Tabs + Karten).
  final bool showVerseHeader;

  bool get canCallAi =>
      surahName != null &&
      ayahNumber != null &&
      textAr != null &&
      textAr!.isNotEmpty &&
      textDe != null;

  String get initialUserPrompt =>
      'Erkläre folgenden Vers aus dem Koran:\n'
      'Sure: $surahName, Vers: $ayahNumber\n'
      'Arabisch: $textAr\n'
      'Deutsche Übersetzung: $textDe\n\n'
      'Gib eine strukturierte Erklärung mit: Kernaussage, Erklärung, Kontext und Bedeutung für heute.';
}

/// Bottom Sheet: KI-Verserklärung mit Chat, Markdown und Follow-ups (Follow-ups nur mit Pro).
void showExplanationBottomSheet(
  BuildContext context, {
  String? verseTitle,
  String? surahName,
  int? ayahNumber,
  String? textAr,
  String? textDe,
  bool isFreeDailyVerse = false,
  bool showVerseHeader = true,
}) {
  final params = VerseExplanationParams(
    verseTitle: verseTitle ?? 'Vers-Erklärung',
    surahName: surahName,
    ayahNumber: ayahNumber,
    textAr: textAr,
    textDe: textDe,
    isFreeDailyVerse: isFreeDailyVerse,
    showVerseHeader: showVerseHeader,
  );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (context) => _ExplanationBottomSheetContent(params: params),
  );
}

class _ExplanationBottomSheetContent extends StatefulWidget {
  const _ExplanationBottomSheetContent({required this.params});

  final VerseExplanationParams params;

  @override
  State<_ExplanationBottomSheetContent> createState() =>
      _ExplanationBottomSheetContentState();
}

class _ExplanationBottomSheetContentState
    extends State<_ExplanationBottomSheetContent> {
  final List<ChatMessage> _messages = [];
  String? _initialUserPrompt;
  Future<AiExplanationResult>? _explanationFuture;
  String? _errorMessage;
  bool _isRateLimit = false;
  bool _isAiTransient = false;
  bool _isInvalidInput = false;
  bool _isLoadingFollowUp = false;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _explanationTabIndex = 0;

  /// Erste KI-Antwort als Karten (JSON); Follow-ups bleiben in [_messages].
  VerseCards? _cards;

  /// Normalisierte Sure-Namen (EN/AR) → Sure-ID für Linkify („Sure An-Nisa, Vers 1“).
  Map<String, int>? _surahNameToId;

  /// Verbleibende Follow-ups laut letzter Server-Antwort; `null` = noch keine Follow-up-Antwort in dieser Session.
  int? _remainingFollowUps;
  String? _installId;

  bool get isProUser => RevenueCatService.isPro;

  /// Folgefragen-Chat: Pro **oder** Beta-Schalter **oder** Dart-Define (siehe [_kAllowFreeFollowups]).
  bool get _followUpsUnlocked =>
      RevenueCatService.isPro || _followUpsFreeBeta || _kAllowFreeFollowups;

  /// Volltext der ersten Assistant-Antwort für Follow-up-API / Konversationskontext.
  String get _firstAssistantReplyText {
    final c = _cards;
    if (c != null) {
      return '${c.bedeutung}\n\n${c.kontext}\n\n${c.heute}'.trim();
    }
    if (_messages.isNotEmpty && !_messages.first.isUser) {
      return _messages.first.text;
    }
    return '';
  }

  void _onProStatusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  static const List<String> _quickQuestions = [
    'Welche Schlüsselbegriffe im Vers muss ich verstehen?',
    'Gibt es einen authentischen Hadith mit Bezug (kurz + Quelle)?',
    'Was missverstehen viele an diesem Vers?',
  ];

  String _uiLanguageTag() {
    return PlatformDispatcher.instance.locale.toLanguageTag();
  }

  /// „Sure 2 (Al-Baqara), Vers 97“ — nicht innerhalb bereits gesetzter Markdown-Labels `[...]`.
  static final RegExp _ayahRefRegex = RegExp(
    r'(?<!\[)(Sure|Surah|Sura)\s*(\d{1,3})(\s*\([^)]{1,80}\))?\s*[,:\-–]?\s*(Vers|Aya|Ayah)\s*(\d{1,3})',
    caseSensitive: false,
  );

  /// „Sure Al-Hujurat (49:13)“
  static final RegExp _ayahParenSurahAyahRegex = RegExp(
    r'(?<!\[)(Sure|Surah|Sura)\s+([^\n(]+?)\s*\((\d{1,3})\s*:\s*(\d{1,3})\)',
    caseSensitive: false,
  );

  /// „Sure 2:255“
  static final RegExp _ayahShortColonRegex = RegExp(
    r'(?<!\[)\b(Sure|Surah|Sura)\s*(\d{1,3})\s*:\s*(\d{1,3})\b',
    caseSensitive: false,
  );

  /// „Sure An-Nisa, Vers 1“ (Name → ID über [_surahNameToId])
  static final RegExp _ayahNamedSurahVersRegex = RegExp(
    r'(?<!\[)(Sure|Surah|Sura)\s+([^,\n]+?)\s*,\s*(?:Vers|Aya|Ayah)\s*(\d{1,3})',
    caseSensitive: false,
  );

  static String _normalizeSurahLookupKey(String raw) {
    var t = raw.toLowerCase().trim();
    t = t.replaceAll(RegExp(r"[`'’´]+"), '');
    t = t.replaceAll(
      RegExp(r'[\u00ad\u2010\u2011\u2012\u2013\u2014\u2212\s\-_\.]+'),
      '',
    );
    return t;
  }

  VerseCards _parseVerseCards(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return VerseCards(bedeutung: raw, kontext: '', heute: '');
      }
      final m = Map<String, dynamic>.from(decoded);
      final refs = <RelatedAyahRef>[];
      final related = m['relatedAyahs'];
      if (related is List) {
        for (final e in related) {
          if (e is! Map) continue;
          final map = Map<String, dynamic>.from(e);
          final sRaw = map['surahId'];
          final aRaw = map['ayahNumber'];
          final surahId = sRaw is int ? sRaw : (sRaw is num ? sRaw.toInt() : null);
          final ayahNumber = aRaw is int ? aRaw : (aRaw is num ? aRaw.toInt() : null);
          if (surahId == null || ayahNumber == null || surahId <= 0 || ayahNumber <= 0) {
            continue;
          }
          refs.add(
            RelatedAyahRef(
              surahId: surahId,
              ayahNumber: ayahNumber,
              shortLabel: map['shortLabel']?.toString(),
            ),
          );
        }
      }
      return VerseCards(
        bedeutung: m['bedeutung']?.toString() ?? raw,
        kontext: m['kontext']?.toString() ?? '',
        heute: m['heute']?.toString() ?? '',
        relatedAyahs: refs,
      );
    } catch (_) {
      return VerseCards(bedeutung: raw, kontext: '', heute: '');
    }
  }

  VerseCards _mergeServerRelatedAyahs(VerseCards cards, List<RelatedAyahRef> server) {
    if (server.isEmpty) return cards;
    final seen = <String>{};
    final merged = <RelatedAyahRef>[];
    for (final r in cards.relatedAyahs) {
      final k = '${r.surahId}:${r.ayahNumber}';
      if (seen.add(k)) merged.add(r);
    }
    for (final r in server) {
      final k = '${r.surahId}:${r.ayahNumber}';
      if (seen.add(k)) merged.add(r);
    }
    return VerseCards(
      bedeutung: cards.bedeutung,
      kontext: cards.kontext,
      heute: cards.heute,
      relatedAyahs: merged,
    );
  }

  Future<void> _openRelatedAyah(RelatedAyahRef ref) async {
    final surahs = await QuranRepository.instance.getAllSurahs();
    final idx = surahs.indexWhere((s) => s.id == ref.surahId);
    if (!mounted) return;
    if (idx < 0) {
      return;
    }
    final surahModel = surahs[idx];
    final surah = Surah(
      number: surahModel.id,
      nameDe: surahModel.nameEn,
      nameAr: surahModel.nameAr,
      verses: const [],
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => QuranReaderScreen(
          surah: surah,
          initialAyahNumber: ref.ayahNumber,
        ),
      ),
    );
  }

  Future<void> _openAyahFromHref(String href) async {
    final h = href.trim();
    final m = RegExp(r'^quran://(\d{1,3}):(\d{1,3})$').firstMatch(h);
    if (m == null) {
      return;
    }
    final surahId = int.tryParse(m.group(1) ?? '');
    final ayahNumber = int.tryParse(m.group(2) ?? '');
    if (surahId == null || ayahNumber == null) {
      return;
    }
    await _openRelatedAyah(RelatedAyahRef(surahId: surahId, ayahNumber: ayahNumber));
  }

  String _linkifyAyahReferences(String text) {
    var t = text.replaceAllMapped(_ayahRefRegex, (m) {
      final surahId = int.tryParse(m.group(2) ?? '');
      final ayahNumber = int.tryParse(m.group(5) ?? '');
      if (surahId == null || ayahNumber == null) {
        return m.group(0) ?? '';
      }
      if (surahId < 1 || surahId > 114 || ayahNumber < 1) {
        return m.group(0) ?? '';
      }
      final label = m.group(0) ?? '';
      return '[$label](quran://$surahId:$ayahNumber)';
    });

    t = t.replaceAllMapped(_ayahParenSurahAyahRegex, (m) {
      final surahId = int.tryParse(m.group(3) ?? '');
      final ayahNumber = int.tryParse(m.group(4) ?? '');
      if (surahId == null || ayahNumber == null) {
        return m.group(0) ?? '';
      }
      if (surahId < 1 || surahId > 114 || ayahNumber < 1) {
        return m.group(0) ?? '';
      }
      final label = m.group(0) ?? '';
      return '[$label](quran://$surahId:$ayahNumber)';
    });

    t = t.replaceAllMapped(_ayahShortColonRegex, (m) {
      final surahId = int.tryParse(m.group(2) ?? '');
      final ayahNumber = int.tryParse(m.group(3) ?? '');
      if (surahId == null || ayahNumber == null) {
        return m.group(0) ?? '';
      }
      if (surahId < 1 || surahId > 114 || ayahNumber < 1) {
        return m.group(0) ?? '';
      }
      final label = m.group(0) ?? '';
      return '[$label](quran://$surahId:$ayahNumber)';
    });

    final nameMap = _surahNameToId;
    if (nameMap != null && nameMap.isNotEmpty) {
      t = t.replaceAllMapped(_ayahNamedSurahVersRegex, (m) {
        final namePart = m.group(2)?.trim() ?? '';
        final compact = namePart.replaceAll(RegExp(r'\s+'), '');
        if (compact.isEmpty || RegExp(r'^\d+$').hasMatch(compact)) {
          return m.group(0) ?? '';
        }
        final ayahNumber = int.tryParse(m.group(3) ?? '');
        if (ayahNumber == null || ayahNumber < 1) {
          return m.group(0) ?? '';
        }
        final sid = nameMap[_normalizeSurahLookupKey(namePart)];
        if (sid == null) {
          return m.group(0) ?? '';
        }
        final label = m.group(0) ?? '';
        return '[$label](quran://$sid:$ayahNumber)';
      });
    }

    return t;
  }

  void _loadSurahNameLookup() {
    QuranRepository.instance.getAllSurahs().then((surahs) {
      if (!mounted) return;
      final m = <String, int>{};
      for (final s in surahs) {
        void addKey(String raw) {
          final k = _normalizeSurahLookupKey(raw);
          if (k.isNotEmpty) {
            m[k] = s.id;
          }
        }

        addKey(s.nameEn);
        addKey(s.nameAr);
      }
      setState(() => _surahNameToId = m);
    });
  }

  /// Sure-ID des aktuellen Sheets (für Filter „Weitere Verse“).
  int? _currentSheetSurahId() {
    final name = widget.params.surahName?.trim();
    if (name == null || name.isEmpty) return null;
    final m = _surahNameToId;
    if (m == null || m.isEmpty) return null;
    return m[_normalizeSurahLookupKey(name)];
  }

  /// Blendet Verweise auf genau den geöffneten Vers aus (rein UI, keine API-Änderung).
  List<RelatedAyahRef> _filterRelatedAyahs(List<RelatedAyahRef> refs) {
    final sid = _currentSheetSurahId();
    final ayah = widget.params.ayahNumber;
    if (sid == null || ayah == null) return refs;
    return refs
        .where((r) => !(r.surahId == sid && r.ayahNumber == ayah))
        .toList(growable: false);
  }

  String? _lastUserMessageText() {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) return _messages[i].text.trim();
    }
    return null;
  }

  /// Schnellfragen-Chips: identische letzte Nutzerzeile nicht erneut als Chip (weniger Redundanz).
  List<String> _visibleQuickQuestions() {
    final last = _lastUserMessageText();
    if (last == null || last.isEmpty) return List<String>.from(_quickQuestions);
    return _quickQuestions.where((q) => q.trim() != last).toList();
  }

  Future<AiExplanationResult> _loadExplanation() async {
    final prefs = await SharedPreferences.getInstance();
    final key = AIService.cacheKey(
      widget.params.surahName!,
      widget.params.ayahNumber!,
    );
    final cached = prefs.getString(key);
    if (cached != null && cached.trim().isNotEmpty) {
      final id = await InstallIdService.instance.getOrCreate();
      if (!mounted) return const AiExplanationResult('');
      setState(() => _installId = id);
      return AiExplanationResult(cached.trim());
    }

    final id = await InstallIdService.instance.getOrCreate();
    if (!mounted) return const AiExplanationResult('');
    setState(() => _installId = id);
    return AIService.instance.getExplanation(
      widget.params.surahName!,
      widget.params.ayahNumber!,
      widget.params.textAr!,
      widget.params.textDe!,
      installId: id,
      isDailyVerse: widget.params.isFreeDailyVerse,
      language: _uiLanguageTag(),
    );
  }

  @override
  void initState() {
    super.initState();
    RevenueCatService.isProNotifier.addListener(_onProStatusChanged);
    RevenueCatService.updateCustomerStatus();
    _loadSurahNameLookup();
    if (widget.params.canCallAi) {
      _explanationFuture = _loadExplanation().then((value) {
        if (mounted) {
          setState(() {
            _initialUserPrompt = widget.params.initialUserPrompt;
            _cards = _mergeServerRelatedAyahs(
              _parseVerseCards(value.text),
              value.relatedAyahs,
            );
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
          });
        }
        return value;
      }).catchError((Object e, StackTrace _) {
        if (mounted) {
          setState(() {
            _applyExplainError(e);
          });
        }
        return const AiExplanationResult('');
      });
    }
  }

  void _applyExplainError(Object e) {
    if (e is IhdinaApiException) {
      _isRateLimit = e.code == IhdinaApiErrorCodes.freeLimitReached;
      _isAiTransient = e.code == IhdinaApiErrorCodes.aiTemporarilyUnavailable;
      _isInvalidInput = e.code == IhdinaApiErrorCodes.invalidInput;
      _errorMessage = _isRateLimit
          ? 'Du hast dein heutiges Kontingent für zusätzliche KI-Erklärungen (ohne Tagesvers) aufgebraucht. Morgen geht es weiter – mit Ihdina Pro unbegrenzt.'
          : e.message;
      return;
    }
    if (e is AIRateLimitException) {
      _errorMessage = e.message;
      _isRateLimit = true;
      _isAiTransient = false;
      _isInvalidInput = false;
      return;
    }
    if (e is AIServiceException) {
      _errorMessage = e.message;
      _isRateLimit = false;
      _isAiTransient = false;
      _isInvalidInput = false;
      return;
    }
    _errorMessage = e.toString();
    _isRateLimit = false;
    _isAiTransient = false;
    _isInvalidInput = false;
  }

  @override
  void dispose() {
    RevenueCatService.isProNotifier.removeListener(_onProStatusChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Map<String, String>> _buildConversationHistory(String newUserText) {
    final history = <Map<String, String>>[
      {'role': 'system', 'content': aiSystemPrompt},
      {'role': 'user', 'content': _initialUserPrompt!},
      {'role': 'assistant', 'content': _firstAssistantReplyText},
    ];
    final n = _messages.length;
    for (var i = 0; i + 1 < n; i += 2) {
      history.add({'role': 'user', 'content': _messages[i].text});
      history.add({'role': 'assistant', 'content': _messages[i + 1].text});
    }
    history.add({'role': 'user', 'content': newUserText});
    return history;
  }

  Future<void> _sendFollowUp(String question) async {
    if (!_followUpsUnlocked) return;
    if (_remainingFollowUps != null && _remainingFollowUps! <= 0) {
      return;
    }
    if (question.trim().isEmpty ||
        _isLoadingFollowUp ||
        _initialUserPrompt == null ||
        _firstAssistantReplyText.isEmpty) {
      return;
    }
    if (_installId == null ||
        widget.params.surahName == null ||
        widget.params.ayahNumber == null) {
      return;
    }

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: question.trim()));
      _isLoadingFollowUp = true;
    });
    _scrollToBottom();

    final full = _buildConversationHistory(question.trim());
    final history = List<Map<String, String>>.from(full);
    if (history.isEmpty) {
      setState(() => _isLoadingFollowUp = false);
      return;
    }
    final last = history.removeLast();
    if (last['role'] != 'user') {
      setState(() => _isLoadingFollowUp = false);
      return;
    }
    final q = last['content'] ?? '';

    try {
      final result = await AIService.instance.askFollowUpForVerse(
        installId: _installId!,
        surahName: widget.params.surahName!,
        ayahNumber: widget.params.ayahNumber!,
        history: history,
        question: q,
        language: _uiLanguageTag(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            isUser: false,
            text: result.text,
            relatedAyahs:
                result.relatedAyahs.isEmpty ? null : result.relatedAyahs,
          ),
        );
        _isLoadingFollowUp = false;
        _remainingFollowUps = result.remainingFollowUpsForVerse;
      });
      _scrollToBottom();
    } on IhdinaApiException catch (e) {
      if (!mounted) return;
      if (e.code == IhdinaApiErrorCodes.proRequired) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
        );
      }
      if (e.code == IhdinaApiErrorCodes.followupLimitReached) {
        setState(() => _remainingFollowUps = 0);
      }
      setState(() {
        _messages.add(ChatMessage(isUser: false, text: e.message));
        _isLoadingFollowUp = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          text: e is AIServiceException ? e.message : e.toString(),
        ));
        _isLoadingFollowUp = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: media.size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.42),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.28), width: 1),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: media.viewInsets.bottom + media.padding.bottom,
              left: 14,
              right: 14,
              top: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    widget.params.verseTitle,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildContent(),
                ),
                _buildBottomComposer(media),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      final orangeHint = _isRateLimit || _isAiTransient;
      final invalid = _isInvalidInput;
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: orangeHint
                ? Colors.orange.withOpacity(0.2)
                : invalid
                    ? Colors.amber.withOpacity(0.15)
                    : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: orangeHint
                  ? Colors.orange.withOpacity(0.5)
                  : invalid
                      ? Colors.amber.withOpacity(0.45)
                      : Colors.red.withOpacity(0.5),
            ),
          ),
          child: Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    if (!widget.params.canCallAi) {
      return const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _MarkdownSection(
          text:
              'Öffne einen Vers im Koran-Leser und tippe darauf, um die KI-Erklärung zu laden.',
        ),
      );
    }

    return FutureBuilder<AiExplanationResult>(
      future: _explanationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              snapshot.error.toString(),
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          );
        }
        if (_cards == null) return const SizedBox.shrink();
        final c = _cards!;
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.params.showVerseHeader) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.params.textAr ?? '',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.68,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    widget.params.textDe ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
              _buildExplanationTabPills(),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                layoutBuilder:
                    (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder:
                    (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_explanationTabIndex),
                  child: _buildVerseExplainCardForIndex(c),
                ),
              ),
              if (c.relatedAyahs.isNotEmpty) ...[
                Builder(
                  builder: (context) {
                    final vis = _filterRelatedAyahs(c.relatedAyahs);
                    if (vis.isEmpty) return const SizedBox.shrink();
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),
                        _buildRelatedAyahsSection(vis),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              for (final m in _messages) ...[
                _MessageBubble(
                  message: m,
                  onTapLink: _openAyahFromHref,
                  linkifyAyahReferences: _linkifyAyahReferences,
                ),
                if (!m.isUser && (m.relatedAyahs?.isNotEmpty ?? false)) ...[
                  Builder(
                    builder: (context) {
                      final vis = _filterRelatedAyahs(m.relatedAyahs!);
                      if (vis.isEmpty) return const SizedBox.shrink();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          _buildRelatedAyahsSection(vis),
                        ],
                      );
                    },
                  ),
                ],
              ],
              if (_isLoadingFollowUp)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white70,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'KI tippt...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static const List<String> _explanationTabLabels = [
    'Bedeutung',
    'Kontext',
    'Heute',
  ];

  Widget _buildVerseExplainCardForIndex(VerseCards c) {
    final i = _explanationTabIndex;
    final body = i == 0
        ? c.bedeutung
        : i == 1
            ? c.kontext
            : c.heute;
    return _buildVerseExplainCard(body);
  }

  Widget _buildExplanationTabPills() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final selected = _explanationTabIndex == i;
        return Padding(
          padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => setState(() => _explanationTabIndex = i),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? _accentChampagneGold
                      : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _accentChampagneGold.withOpacity(0.35),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset.zero,
                          ),
                        ]
                      : const [],
                ),
                child: Text(
                  _explanationTabLabels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF1A1A1A)
                        : Colors.white.withOpacity(0.65),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVerseExplainCard(String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.035),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: _MarkdownSection(
            text: _linkifyAyahReferences(body),
            textColor: Colors.white,
            onTapLink: _openAyahFromHref,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    final qs = _visibleQuickQuestions();
    if (qs.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: qs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = qs[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoadingFollowUp ? null : () => _sendFollowUp(label),
              borderRadius: BorderRadius.circular(22),
              splashColor: Colors.white.withOpacity(0.08),
              highlightColor: Colors.white.withOpacity(0.06),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: _isLoadingFollowUp ? Colors.white38 : Colors.white.withOpacity(0.92),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInput() {
    if (!_followUpsUnlocked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
              );
            },
            borderRadius: BorderRadius.circular(22),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: _accentChampagneGold, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Eigene Fragen stellen? Werde Pro-Mitglied',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.92),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_remainingFollowUps != null && _remainingFollowUps! <= 0) {
      return _buildFollowUpLimitHint();
    }
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                enabled: !_isLoadingFollowUp,
                textAlign: _inputController.text.isEmpty
                    ? TextAlign.center
                    : TextAlign.start,
                textAlignVertical: TextAlignVertical.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Colors.white.withOpacity(0.95),
                ),
                cursorColor: _accentChampagneGold,
                decoration: InputDecoration(
                  hintText: 'Eigene Frage stellen…',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.45),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _sendFollowUp(_inputController.text),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.14),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withOpacity(0.06),
                  disabledForegroundColor: Colors.white38,
                  padding: const EdgeInsets.all(10),
                  minimumSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const CircleBorder(),
                ),
                onPressed: _isLoadingFollowUp
                    ? null
                    : () {
                        final t = _inputController.text;
                        _inputController.clear();
                        setState(() {});
                        _sendFollowUp(t);
                      },
                icon: const Icon(Icons.arrow_upward_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpLimitHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Text(
        'Du hast diesen Vers bereits ausführlich erkundet ✨\n'
        'Öffne einen anderen Vers oder starte mit einem neuen Impuls.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: Colors.white.withOpacity(0.72),
        ),
      ),
    );
  }

  Widget _buildRelatedAyahsSection(List<RelatedAyahRef> refs) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Weitere Verse',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: refs.map((ref) {
              final label = (ref.shortLabel != null && ref.shortLabel!.trim().isNotEmpty)
                  ? ref.shortLabel!.trim()
                  : 'Sure ${ref.surahId}, Vers ${ref.ayahNumber}';
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openRelatedAyah(ref),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomComposer(MediaQueryData media) {
    final showComposer = (_cards != null || _messages.isNotEmpty) && _errorMessage == null;
    if (!showComposer) {
      return const SizedBox.shrink();
    }
    final keyboardOpen = media.viewInsets.bottom > 0;
    final quickQs = _visibleQuickQuestions();
    final showQuickChips = _followUpsUnlocked &&
        (_remainingFollowUps == null || _remainingFollowUps! > 0) &&
        !keyboardOpen &&
        quickQs.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, thickness: 1, color: Colors.white.withOpacity(0.08)),
          SizedBox(height: showQuickChips ? 10 : 8),
          if (showQuickChips) ...[
            _buildQuickChips(),
            const SizedBox(height: 10),
          ],
          _buildChatInput(),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onTapLink,
    required this.linkifyAyahReferences,
  });

  final ChatMessage message;
  final Future<void> Function(String href) onTapLink;
  final String Function(String text) linkifyAyahReferences;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                (message.isUser ? 0.82 : 0.94),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: message.isUser
                  ? Colors.white.withOpacity(0.14)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isUser ? 18 : 6),
                bottomRight: Radius.circular(message.isUser ? 6 : 18),
              ),
              border: message.isUser
                  ? null
                  : Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: message.isUser
                  ? Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    )
                  : _MarkdownSection(
                      text: linkifyAyahReferences(message.text),
                      onTapLink: onTapLink,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkdownSection extends StatelessWidget {
  const _MarkdownSection({
    required this.text,
    this.textColor = Colors.white70,
    this.onTapLink,
  });

  final String text;
  final Color textColor;
  final Future<void> Function(String href)? onTapLink;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: false,
      onTapLink: onTapLink == null
          ? null
          : (text, href, title) {
              if (href == null || href.trim().isEmpty) return;
              onTapLink!(href);
            },
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 15,
          color: Colors.white70,
          height: 1.5,
        ),
        h1: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        h2: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        h3: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        listIndent: 24,
        blockquote: TextStyle(
          fontSize: 15,
          color: textColor.withOpacity(0.9),
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.white.withOpacity(0.4),
              width: 3,
            ),
          ),
        ),
        blockSpacing: 12,
      ).copyWith(
        p: TextStyle(
          fontSize: 15,
          color: textColor,
          height: 1.5,
        ),
        h1: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h3: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        a: TextStyle(
          color: _accentChampagneGold,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: _accentChampagneGold.withOpacity(0.85),
        ),
      ),
    );
  }
}

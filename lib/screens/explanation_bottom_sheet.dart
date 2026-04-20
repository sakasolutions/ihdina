import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ai/ai_service.dart';
import '../data/api/ihdina_api_client.dart';
import '../services/install_id_service.dart';
import '../services/revenuecat_service.dart';
import 'paywall_screen.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);
const int _freeExtraExplanationsPerDay = 10;

/// Strukturierte Vers-Erklärung (JSON vom Backend im Feld `text`).
class VerseCards {
  VerseCards({
    required this.bedeutung,
    required this.kontext,
    required this.heute,
  });

  final String bedeutung;
  final String kontext;
  final String heute;
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
  const ChatMessage({required this.isUser, required this.text});
  final bool isUser;
  final String text;
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
  Future<String>? _explanationFuture;
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

  /// Verbleibende Follow-ups laut letzter Server-Antwort; `null` = noch keine Follow-up-Antwort in dieser Session.
  int? _remainingFollowUps;
  String? _installId;

  bool get isProUser => RevenueCatService.isPro;

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
    'Was bedeutet das für mich?',
    'Wie kann ich das anwenden?',
    'Gibt es passende Hadithe?',
  ];

  String _uiLanguageTag() {
    return PlatformDispatcher.instance.locale.toLanguageTag();
  }

  VerseCards _parseVerseCards(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return VerseCards(bedeutung: raw, kontext: '', heute: '');
      }
      final m = Map<String, dynamic>.from(decoded);
      return VerseCards(
        bedeutung: m['bedeutung']?.toString() ?? raw,
        kontext: m['kontext']?.toString() ?? '',
        heute: m['heute']?.toString() ?? '',
      );
    } catch (_) {
      return VerseCards(bedeutung: raw, kontext: '', heute: '');
    }
  }

  Future<String> _loadExplanation() async {
    final prefs = await SharedPreferences.getInstance();
    final key = AIService.cacheKey(
      widget.params.surahName!,
      widget.params.ayahNumber!,
    );
    final cached = prefs.getString(key);
    if (cached != null && cached.trim().isNotEmpty) {
      final id = await InstallIdService.instance.getOrCreate();
      if (!mounted) return '';
      setState(() => _installId = id);
      return cached.trim();
    }

    final id = await InstallIdService.instance.getOrCreate();
    if (!mounted) return '';
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
    if (widget.params.canCallAi) {
      _explanationFuture = _loadExplanation().then((value) {
        if (mounted) {
          setState(() {
            _initialUserPrompt = widget.params.initialUserPrompt;
            _cards = _parseVerseCards(value);
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
        return '';
      });
    }
  }

  void _applyExplainError(Object e) {
    if (e is IhdinaApiException) {
      _isRateLimit = e.code == IhdinaApiErrorCodes.freeLimitReached;
      _isAiTransient = e.code == IhdinaApiErrorCodes.aiTemporarilyUnavailable;
      _isInvalidInput = e.code == IhdinaApiErrorCodes.invalidInput;
      _errorMessage = _isRateLimit
          ? 'Du hast heute bereits $_freeExtraExplanationsPerDay kostenlose KI-Erklärungen genutzt. Morgen geht es weiter oder mit Pro jederzeit unbegrenzt.'
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
    if (!isProUser) return;
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
        _messages.add(ChatMessage(isUser: false, text: result.text));
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
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: media.size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: media.viewInsets.bottom + media.padding.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                const SizedBox(height: 16),
                Expanded(
                  child: _buildContent(),
                ),
                if ((_cards != null || _messages.isNotEmpty) &&
                    _errorMessage == null) ...[
                  if (isProUser &&
                      (_remainingFollowUps == null || _remainingFollowUps! > 0))
                    _buildQuickChips(),
                  _buildChatInput(),
                ],
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

    return FutureBuilder<String>(
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
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
              const SizedBox(height: 8),
              ..._messages.map((m) => _MessageBubble(message: m)),
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
                      ? const Color(0xFFE5C07B)
                      : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE5C07B).withOpacity(0.3),
                            blurRadius: 8,
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
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF1A1A1A)
                        : Colors.white.withOpacity(0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        alignment: Alignment.topCenter,
        child: Text(
          body,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _quickQuestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final label = _quickQuestions[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoadingFollowUp ? null : () => _sendFollowUp(label),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Transform.translate(
                  offset: const Offset(0, -1.5),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: _isLoadingFollowUp
                          ? Colors.white38
                          : Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    textAlign: TextAlign.center,
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
    if (!isProUser) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const PaywallScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _accentChampagneGold.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: _accentChampagneGold, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Eigene Fragen stellen? Werde Pro-Mitglied',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _inputController,
                enabled: !_isLoadingFollowUp,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Eigene Frage stellen...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
                minLines: 1,
                onSubmitted: (_) => _sendFollowUp(_inputController.text),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoadingFollowUp
                  ? null
                  : () {
                      final t = _inputController.text;
                      _inputController.clear();
                      _sendFollowUp(t);
                    },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _isLoadingFollowUp ? Colors.white38 : Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpLimitHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
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
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: message.isUser
                ? Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  )
                : _MarkdownSection(text: message.text),
          ),
        ),
      ),
    );
  }
}

class _MarkdownSection extends StatelessWidget {
  const _MarkdownSection({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: false,
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
          color: Colors.white70,
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
      ),
    );
  }
}

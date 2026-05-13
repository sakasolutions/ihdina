import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../config/geonames_config.dart';
import '../data/location/city_search_result.dart';
import '../data/location/geonames_repository.dart';
import '../data/prayer/prayer_models.dart';
import '../data/prayer/prayer_times_repository.dart';
import '../data/settings/settings_repository.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/local_dictation_icon_button.dart';
import '../widgets/local_speech_privacy_caption.dart';

/// City search for prayer location. No GPS; selects from GeoNames results.
class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  static const Color _champagneGold = Color(0xFFE5C07B);

  final _queryController = TextEditingController();
  Timer? _debounce;
  static const int _debounceMs = 300;

  List<CitySearchResult> _results = [];
  String? _errorMessage;
  bool _loading = false;
  PrayerTimesResult? _prayerResult;

  @override
  void initState() {
    super.initState();
    _queryController.addListener(_onQueryChanged);
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    final settings = await SettingsRepository.instance.getPrayerSettings();
    if (!mounted) return;
    final now = DateTime.now();
    final result = PrayerTimesRepository.instance.computeToday(settings, now);
    if (mounted) setState(() => _prayerResult = result);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      _search(_queryController.text);
    });
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _errorMessage = null;
          _loading = false;
        });
      }
      return;
    }

    if (!isGeonamesConfigured) {
      if (mounted) {
        setState(() {
          _results = [];
          _errorMessage =
              'Stadtsuche nicht konfiguriert. Bitte GeoNames Username in lib/config/geonames_config.dart eintragen.';
          _loading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final response = await GeonamesRepository.instance.searchCities(q);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.errorMessage != null) {
        _errorMessage = response.errorMessage;
        _results = [];
      } else {
        _errorMessage = null;
        _results = response.results ?? [];
      }
    });
  }

  Future<void> _selectCity(CitySearchResult city) async {
    final label = city.persistenceLabel;
    final lat = city.lat;
    final lng = city.lng;
    await SettingsRepository.instance.setPrayerLocation(label, lat, lng);
    if (kDebugMode) {
      debugPrint('[CITY] saved: $label lat=$lat lng=$lng');
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final heroPhase = DynamicHeroTheme.phaseFromPrayer(_prayerResult?.nextPrayerType);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.mainGradient,
          ),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset(
                    DynamicHeroTheme.backgroundAsset(heroPhase),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    _buildSearchField(),
                    Expanded(child: _buildMainArea()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Stadt auswählen',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: 'Stadt suchen',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.4),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: _champagneGold,
                ),
                suffixIcon: LocalDictationIconButton(
                  controller: _queryController,
                  listenMode: ListenMode.search,
                  iconColor: _champagneGold,
                  padding: const EdgeInsetsDirectional.only(end: 4),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                disabledBorder: border,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
              autofocus: true,
            ),
            const LocalSpeechPrivacyCaption(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainArea() {
    if (!isGeonamesConfigured) {
      return _buildCenteredStatus(
        icon: Icons.travel_explore_outlined,
        title: 'Stadtsuche nicht konfiguriert',
        text:
            'Bitte GeoNames Username in lib/config/geonames_config.dart eintragen.',
      );
    }
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _champagneGold,
        ),
      );
    }
    if (_errorMessage != null) {
      return _buildCenteredStatus(
        icon: Icons.cloud_off_outlined,
        title: 'Fehler',
        text: _errorMessage!,
      );
    }
    if (_results.isEmpty && _queryController.text.trim().isNotEmpty) {
      return _buildCenteredStatus(
        icon: Icons.search_off_rounded,
        title: 'Keine Treffer',
        text: 'Keine Städte gefunden.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 130),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withOpacity(0.08),
      ),
      itemBuilder: (context, index) {
        final city = _results[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectCity(city),
            borderRadius: BorderRadius.circular(22),
            child: GlassCard(
              borderRadius: 22,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _champagneGold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            city.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            city.displayLabel != city.name
                                ? city.displayLabel
                                : city.countryName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenteredStatus({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white.withOpacity(0.35),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.4,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../services/revenuecat_service.dart';
import '../theme/app_theme.dart';
import '../theme/hero_theme.dart';
import '../widgets/glass_card.dart';

const Color _accentChampagneGold = Color(0xFFE5C07B);

/// CTA-Gradient (warm gold-beige).
const Color _ctaGradientTop = Color(0xFFE6C48A);
const Color _ctaGradientBottom = Color(0xFFD4A95A);

/// Maximale Kartenbreite (Anteil der SafeArea-Breite).
const double _paywallDesignWidth = 352;

/// RevenueCat-Paket-IDs — müssen zum Dashboard / Offering passen.
const String _proMonthlyPackageId = 'pro_monthly';
const String _proYearlyPackageId = 'pro_yearly';

/// Paywall: Kauf-/Restore über [handlePurchase] / RevenueCat (Logik unverändert).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool isLoading = false;
  bool isRestoring = false;
  bool _yearlySelected = true;

  Future<void> handlePurchase(String packageId) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final offerings = await RevenueCatService.getOfferings();
    Package? package;
    final current = offerings?.current;
    if (current != null) {
      for (final p in current.availablePackages) {
        if (p.identifier == packageId) {
          package = p;
          break;
        }
      }
    }

    if (package == null) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Angebot nicht verfügbar. Bitte später erneut versuchen.')),
        );
      }
      return;
    }

    final success = await RevenueCatService.purchasePackage(package);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Willkommen bei Ihdina Pro!')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _onRestore() async {
    setState(() => isRestoring = true);
    final ok = await RevenueCatService.restorePurchases();
    if (!mounted) return;
    setState(() => isRestoring = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Käufe wiederhergestellt.' : 'Wiederherstellung fehlgeschlagen.',
        ),
      ),
    );
    if (ok && RevenueCatService.isPro) {
      Navigator.of(context).pop();
    }
  }

  void _onPurchaseTap() {
    final id = _yearlySelected ? _proYearlyPackageId : _proMonthlyPackageId;
    handlePurchase(id);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
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
                      DynamicHeroTheme.backgroundAsset(HeroPhase.day),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth * 0.9;
                      final layoutW = min(_paywallDesignWidth, maxW);
                      return Center(
                        child: SizedBox(
                          width: layoutW,
                          child: _PaywallPremiumCard(
                            yearlySelected: _yearlySelected,
                            onYearlySelected: (yearly) {
                              setState(() => _yearlySelected = yearly);
                            },
                            isLoading: isLoading,
                            isRestoring: isRestoring,
                            onClose: () => Navigator.of(context).pop(),
                            onPurchase: _onPurchaseTap,
                            onRestore: _onRestore,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaywallPremiumCard extends StatelessWidget {
  const _PaywallPremiumCard({
    required this.yearlySelected,
    required this.onYearlySelected,
    required this.isLoading,
    required this.isRestoring,
    required this.onClose,
    required this.onPurchase,
    required this.onRestore,
  });

  final bool yearlySelected;
  final ValueChanged<bool> onYearlySelected;
  final bool isLoading;
  final bool isRestoring;
  final VoidCallback onClose;
  final VoidCallback onPurchase;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(27),
        color: const Color(0xFF0D2D24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.26),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.22),
            blurRadius: 28,
            spreadRadius: -2,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.06),
            blurRadius: 42,
            spreadRadius: 0,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: GlassCard(
          borderRadius: 26,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onClose,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.15)),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Text(
                    'Manchmal reicht der Vers – manchmal brauchst du einen klaren Gedanken dazu',
                    textAlign: TextAlign.start,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      height: 1.24,
                      color: Colors.white,
                      letterSpacing: -0.22,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Text(
                    'Dann hilft dir Pro mit einfühlsamen Erklärungen und der Möglichkeit nachzufragen – ohne Überforderung.',
                    textAlign: TextAlign.start,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.56),
                      height: 1.42,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _BillingToggle(
                  yearlySelected: yearlySelected,
                  onChanged: onYearlySelected,
                ),
                const SizedBox(height: 14),
                _DualPriceRows(
                  yearlySelected: yearlySelected,
                  onSelectMonthly: () => onYearlySelected(false),
                  onSelectYearly: () => onYearlySelected(true),
                ),
                const SizedBox(height: 12),
                _BenefitLine(
                  icon: Icons.auto_stories_outlined,
                  text: 'Unbegrenzte KI-Erklärungen',
                ),
                const SizedBox(height: 5),
                _BenefitLine(
                  icon: Icons.chat_bubble_outline_rounded,
                  text: 'Folgefragen zu jedem Vers',
                ),
                const SizedBox(height: 5),
                _BenefitLine(
                  icon: Icons.spa_outlined,
                  text: 'Tieferes Verständnis',
                ),
                const SizedBox(height: 17),
                _BreathingCta(
                  isLoading: isLoading,
                  onTap: onPurchase,
                ),
                const SizedBox(height: 8),
                Text(
                  'Beginne heute – in deinem Tempo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Jederzeit kündbar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.34),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: (isLoading || isRestoring) ? null : () => onRestore(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.24),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isRestoring ? 'Wiederherstellen…' : 'Käufe wiederherstellen',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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
}

/// Segment-Toggle; Badge „Spare 4 Monate“ (Jahres-Empfehlung).
class _BillingToggle extends StatelessWidget {
  const _BillingToggle({
    required this.yearlySelected,
    required this.onChanged,
  });

  final bool yearlySelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Expanded(
              child: _ToggleSegment(
                label: 'Monatlich',
                selected: !yearlySelected,
                onTap: () => onChanged(false),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleSegment(
                label: 'Jährlich',
                selected: yearlySelected,
                onTap: () => onChanged(true),
              ),
            ),
          ],
        ),
        Positioned(
          top: -20,
          right: 0,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6C48A).withOpacity(0.94),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Spare 4 Monate',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A2418),
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 38,
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.14)
                : Colors.white.withOpacity(0.025),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _accentChampagneGold.withOpacity(0.48)
                  : Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? Colors.white.withOpacity(0.96)
                    : Colors.white.withOpacity(0.74),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Beide Preismodelle gleichzeitig; Auswahl per Tap oder Toggle.
class _DualPriceRows extends StatelessWidget {
  const _DualPriceRows({
    required this.yearlySelected,
    required this.onSelectMonthly,
    required this.onSelectYearly,
  });

  final bool yearlySelected;
  final VoidCallback onSelectMonthly;
  final VoidCallback onSelectYearly;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SelectablePriceRow(
            selected: !yearlySelected,
            onTap: onSelectMonthly,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Monatlich',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.52),
                    ),
                  ),
                ),
                Text(
                  '3,99 €',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.94),
                    height: 0.98,
                  ),
                ),
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '/ Monat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.44),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          _SelectablePriceRow(
            selected: yearlySelected,
            onTap: onSelectYearly,
            highlightYearly: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Jährlich',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.76),
                        ),
                      ),
                    ),
                    Text(
                      '31,99 €',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 0.98,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        '/ Jahr',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'entspricht nur 2,66 € / Monat',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF2E6CC).withOpacity(0.96),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectablePriceRow extends StatelessWidget {
  const _SelectablePriceRow({
    required this.selected,
    required this.onTap,
    required this.child,
    this.highlightYearly = false,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final bool highlightYearly;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? (highlightYearly
            ? const Color(0xFFC4A574).withOpacity(0.38)
            : const Color(0xFFC4A574).withOpacity(0.28))
        : Colors.white.withOpacity(0.06);

    final BoxDecoration decoration;
    if (selected && highlightYearly) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentChampagneGold.withOpacity(0.09),
            Colors.white.withOpacity(0.03),
          ],
        ),
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        color: selected
            ? Colors.white.withOpacity(0.065)
            : Colors.white.withOpacity(0.02),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: child,
        ),
      ),
    );
  }
}

/// CTA mit warmem Gradient, Glow, Schatten und dezenter Breathing-Animation.
class _BreathingCta extends StatefulWidget {
  const _BreathingCta({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  State<_BreathingCta> createState() => _BreathingCtaState();
}

class _BreathingCtaState extends State<_BreathingCta>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.12, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_BreathingCta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.stop();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ctaRadius = 18.0;
    return Semantics(
      button: true,
      label: 'Verstehen freischalten',
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _glow]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isLoading ? 1.0 : _scale.value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ctaRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE6C48A).withOpacity(_glow.value * 0.35),
                    blurRadius: 22,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onTap,
            borderRadius: BorderRadius.circular(ctaRadius),
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _ctaGradientTop,
                    _ctaGradientBottom,
                  ],
                ),
                borderRadius: BorderRadius.circular(ctaRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF2A2418),
                            strokeWidth: 2.2,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            'Verstehen freischalten',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2A2418),
                              letterSpacing: 0.12,
                              height: 1.2,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withOpacity(0.54);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Align(
            alignment: Alignment.topLeft,
            child: Icon(
              icon,
              size: 16,
              weight: 0.35,
              grade: -25,
              color: muted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              text,
              textAlign: TextAlign.start,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: muted,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

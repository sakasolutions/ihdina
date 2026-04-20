import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Signature accent for selected tab (matches home, prayer, sources).
const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Floating glassmorphism bottom bar: Home, Koran, Gebet, Mehr. Blur, tint, gold accent for active.
class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.enableHaptics = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool enableHaptics;

  static const int _itemCount = 4;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.055),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_itemCount, (index) => _NavItem(
                label: _labels[index],
                icon: _icons[index],
                selected: currentIndex == index,
                accentColor: _accentChampagneGold,
                onTap: () {
                  if (enableHaptics) {
                    HapticFeedback.lightImpact();
                  }
                  onTap(index);
                },
              )),
            ),
          ),
        ),
      ),
    );
  }

  static const List<String> _labels = ['Home', 'Koran', 'Gebet', 'Mehr'];
  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.menu_book_rounded,
    Icons.schedule_rounded,
    Icons.more_horiz_rounded,
  ];
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accentColor : Colors.white54;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

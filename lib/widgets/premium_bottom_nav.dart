import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Signature accent for selected tab (matches home, prayer, sources).
const Color _accentChampagneGold = Color(0xFFE5C07B);

/// Floating glassmorphism bottom bar: Dua, Koran, Home, Gebet, Mehr.
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

  static const int _itemCount = 5;
  static const int _homeTabIndex = 2;

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
              children: List.generate(
                  _itemCount,
                  (index) => _NavItem(
                        label: _labels[index],
                        icon: _icons[index],
                        iconSize: index == _homeTabIndex
                            ? _NavItem._homeIconSize
                            : _NavItem._iconSize,
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

  static const List<String> _labels = [
    'Dua',
    'Koran',
    'Home',
    'Gebet',
    'Mehr',
  ];
  static const List<IconData> _icons = [
    Icons.volunteer_activism_rounded,
    Icons.menu_book_rounded,
    Icons.home_rounded,
    Icons.schedule_rounded,
    Icons.more_horiz_rounded,
  ];
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final double iconSize;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  static const double _iconSize = 24;
  static const double _homeIconSize = 28;
  static const double _iconLayoutSlot = _iconSize;

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
                _NavIcon(
                  icon: icon,
                  iconSize: iconSize,
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

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.iconSize,
    required this.color,
  });

  final IconData icon;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: iconSize,
      color: color,
    );

    if (iconSize <= _NavItem._iconLayoutSlot) {
      return iconWidget;
    }

    return SizedBox(
      width: _NavItem._iconLayoutSlot,
      height: _NavItem._iconLayoutSlot,
      child: OverflowBox(
        maxWidth: iconSize,
        maxHeight: iconSize,
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: Center(child: iconWidget),
        ),
      ),
    );
  }
}

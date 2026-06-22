import 'dart:ui';

import 'package:club_india_user/views/navigation%20bar/history_page.dart';
import 'package:club_india_user/views/navigation%20bar/home_page.dart';
import 'package:club_india_user/views/navigation%20bar/offer_page.dart';
import 'package:club_india_user/views/navigation%20bar/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

// final homeKey = GlobalKey<HomePageState>();
// final offerKey = GlobalKey<SpecialOffersPageState>();
// final historyKey = GlobalKey<HistoryPageState>();
// final profileKey = GlobalKey<ProfilePageState>();

class MainNavScreen extends StatefulWidget {
  final int initialTabIndex;
  final String phoneNumber;

  const MainNavScreen({
    super.key,
    this.initialTabIndex = 0,
    this.phoneNumber = '',
  });

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  final homeKey = GlobalKey<HomePageState>();
  final offerKey = GlobalKey<SpecialOffersPageState>();
  final historyKey = GlobalKey<HistoryPageState>();
  final profileKey = GlobalKey<ProfilePageState>();

  late int _selectedScreen;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedScreen = widget.initialTabIndex;
    _pages = [
      HomePage(key: homeKey),
      SpecialOffersPage(
        key: offerKey,
        onBack: () => setState(() => _selectedScreen = 0),
      ),
      HistoryPage(
        key: historyKey,
        onBack: () => setState(() => _selectedScreen = 0),
      ),
      ProfilePage(
        key: profileKey,
        onBack: () => setState(() => _selectedScreen = 0),
      ),
    ];
  }

  Future<void> _onNavItemTapped(int index) async {
    switch (index) {
      case 0:
        await homeKey.currentState?.refreshPage();
        break;
      case 1:
        await offerKey.currentState?.refreshPage();
        break;
      case 2:
        await historyKey.currentState?.refreshPage();
        break;
      case 3:
        await profileKey.currentState?.refreshPage();
        break;
    }

    if (_selectedScreen != index) {
      setState(() => _selectedScreen = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFFCEEF1),
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(index: _selectedScreen, children: _pages),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPadding + 12,
            child: _ClubIndiaNavBar(
              currentIndex: _selectedScreen,
              onTap: _onNavItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Bar Widget ───────────────────────────────────────────────────────────

class _ClubIndiaNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ClubIndiaNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.card_giftcard_outlined,
      selectedIcon: Icons.card_giftcard,
      label: 'Offers',
    ),
    _NavItem(
      icon: Icons.history_outlined,
      selectedIcon: Icons.history_rounded,
      label: 'History',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  State<_ClubIndiaNavBar> createState() => _ClubIndiaNavBarState();
}

// ─── Nav Bar State (Spring Physics + Drag) ────────────────────────────────────

class _ClubIndiaNavBarState extends State<_ClubIndiaNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _springController;

  double? _dragPosition;

  double _itemWidth = 0;
  double _pillStretch = 0;

  static const double _springStiffness = 700.0;
  static const double _springDamping = 22.0;

  @override
  void initState() {
    super.initState();

    _springController = AnimationController.unbounded(vsync: this);
  }

  @override
  void didUpdateWidget(_ClubIndiaNavBar old) {
    super.didUpdateWidget(old);

    if (old.currentIndex != widget.currentIndex && _dragPosition == null) {
      _springToIndex(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _springToIndex(int index) {
    if (_itemWidth == 0) return;

    final targetX = _itemWidth * index + 8;
    final currentX = _springController.value;
    final currentVelocity = _springController.velocity;

    final simulation = SpringSimulation(
      const SpringDescription(
        mass: 1.0,
        stiffness: _springStiffness,
        damping: _springDamping,
      ),
      currentX,
      targetX,
      currentVelocity,
    );

    _springController.animateWith(simulation);
  }

  // ── Drag handlers ───────────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails details) {
    if (_itemWidth == 0) return;

    setState(() {
      final minX = 8.0;
      final maxX = _itemWidth * (_ClubIndiaNavBar._items.length - 1) + 8;

      _springController.stop();

      _dragPosition =
          ((_dragPosition ?? _springController.value) + details.delta.dx).clamp(
            minX,
            maxX,
          );

      // Liquid stretch effect
      _pillStretch = (details.delta.dx.abs() * 2).clamp(0.0, 20.0);

      _springController.value = _dragPosition!;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_itemWidth == 0) return;

    final rawIndex = ((_dragPosition ?? _springController.value) / _itemWidth)
        .round();
    final targetIndex = rawIndex.clamp(0, _ClubIndiaNavBar._items.length - 1);

    final fingerVelocity = details.velocity.pixelsPerSecond.dx;
    final simulation = SpringSimulation(
      const SpringDescription(
        mass: 1.0,
        stiffness: _springStiffness,
        damping: _springDamping,
      ),
      _springController.value,
      _itemWidth * targetIndex + 8,
      fingerVelocity,
    );

    setState(() {
      _dragPosition = null;
      _pillStretch = 0;
    });

    _springController.animateWith(simulation);
    HapticFeedback.lightImpact();
    // Notify parent (triggers refreshPage + setState for index highlight)
    widget.onTap(targetIndex);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.30), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB6C8).withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              _itemWidth =
                  constraints.maxWidth / _ClubIndiaNavBar._items.length;

              if (!_springController.isAnimating &&
                  _springController.value == 0) {
                _springController.value = _itemWidth * widget.currentIndex + 8;
              }

              return GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                child: AnimatedBuilder(
                  animation: _springController,
                  builder: (context, child) {
                    final pillLeft = _dragPosition ?? _springController.value;

                    return Stack(
                      children: [
                        Positioned(
                          left: pillLeft - (_pillStretch / 2),
                          top: 14,
                          child: Container(
                            width: (_itemWidth - 16) + _pillStretch,
                            height: 62,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF48FB1), Color(0xFFFFD8E5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF48FB1,
                                  ).withOpacity(0.40),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Nav items row ──────────────────────────────────────
                        Row(
                          children: List.generate(
                            _ClubIndiaNavBar._items.length,
                            (i) => Expanded(
                              child: _NavBarItem(
                                item: _ClubIndiaNavBar._items[i],
                                isSelected: widget.currentIndex == i,
                                onTap: () => widget.onTap(i),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Individual nav item ──────────────────────────────────────────────────────

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: double.infinity,
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            scale: isSelected ? 1.08 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: isSelected ? 72 : 56,
              height: isSelected ? 62 : 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      key: ValueKey(isSelected),
                      size: isSelected ? 28 : 24,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4A4A68),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF4A4A68),
                    ),
                    child: Text(item.label),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

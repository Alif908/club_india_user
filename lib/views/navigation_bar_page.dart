import 'package:club_india_user/views/navigation%20bar/history_page.dart';
import 'package:club_india_user/views/navigation%20bar/home_page.dart';
import 'package:club_india_user/views/navigation%20bar/offer_page.dart';
import 'package:club_india_user/views/navigation%20bar/profile_page.dart';
import 'package:flutter/material.dart';

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
  late int _selectedScreen;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedScreen = widget.initialTabIndex;
    _pages = [
       HomePage(),
      SpecialOffersPage(onBack: () => setState(() => _selectedScreen = 0)),
       HistoryPage(onBack: () => setState(() => _selectedScreen = 0)),
      ProfilePage(onBack: () => setState(() => _selectedScreen = 0)),
    ];
  }

  void _onNavItemTapped(int index) {
    if (_selectedScreen != index) setState(() => _selectedScreen = index);
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

class _ClubIndiaNavBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB6C8).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _items.length,
            (i) => _NavBarItem(
              item: _items[i],
              isSelected: currentIndex == i,
              onTap: () => onTap(i),
            ),
          ),
        ),
      ),
    );
  }
}

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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: double.infinity,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            width: isSelected ? 72 : 56,
            height: isSelected ? 62 : 56,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFFF48FB1), Color(0xFFFFF5F8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? item.selectedIcon : item.icon,
                    key: ValueKey(isSelected),
                    size: 26,
                    color: isSelected ? Colors.white : const Color(0xFF4A4A68),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? Colors.white : const Color(0xFF4A4A68),
                  ),
                  child: Text(item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';

/// Root shell that renders the active tab and the floating bottom navbar.
/// Gates onboarding on first launch.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _onboardingChecked = false;

  static const _tabs = <_NavItem>[
    _NavItem(icon: Icons.grid_view_rounded, label: 'Home'),
    _NavItem(icon: Icons.auto_awesome_outlined, label: 'Chat'),
    _NavItem(icon: Icons.tune_rounded, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    if (mounted) {
      setState(() => _onboardingChecked = true);
      if (!completed) {
        // Show onboarding as a full-screen modal
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (context) => const OnboardingScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force light status bar icons on dark canvas
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: KokoColors.canvas,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          ChatScreen(),
          SettingsScreen(),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _FloatingNavBar(
        items: _tabs,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating bottom navigation bar — rounded pill shape, warm-dark surface
// ─────────────────────────────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        KokoSpacing.xxl,              // 32px from left
        0,
        KokoSpacing.xxl,              // 32px from right
        bottomPadding + KokoSpacing.lg, // safe area + 16px
      ),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: KokoColors.canvasSoft,
          borderRadius: KokoRadius.pillBorder,
          border: Border.all(color: KokoColors.hairline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isActive = index == currentIndex;
            return _NavBarItem(
              icon: items[index].icon,
              label: items[index].label,
              isActive: isActive,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Icon(
                icon,
                size: 22,
                color: isActive ? KokoColors.ink : KokoColors.mute,
              ),
            ),
            const SizedBox(height: KokoSpacing.xs),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? KokoColors.ink : KokoColors.mute,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';

/// Three-step onboarding: Welcome → Permission → Indexing progress.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KokoColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomePage(onNext: _next),
                  _PermissionPage(onNext: _next),
                  _IndexingPage(onComplete: _complete),
                ],
              ),
            ),
            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: KokoSpacing.xxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? KokoColors.ink : KokoColors.hairline,
                      borderRadius: KokoRadius.pillBorder,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome ──

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KokoSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: KokoColors.canvasSoft,
              borderRadius: KokoRadius.lgBorder,
              border: Border.all(color: KokoColors.hairline),
            ),
            child: const Icon(
              Icons.auto_awesome_motion_rounded,
              size: 36,
              color: KokoColors.ink,
            ),
          ),
          const SizedBox(height: KokoSpacing.xxl),
          const Text(
            'KokoShots',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.8,
              color: KokoColors.ink,
            ),
          ),
          const SizedBox(height: KokoSpacing.lg),
          const Text(
            'Your screenshot memory,\npowered by AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              height: 1.5,
              color: KokoColors.body,
            ),
          ),
          const SizedBox(height: KokoSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              child: const Text('Get started'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 2: Permission ──

class _PermissionPage extends ConsumerWidget {
  const _PermissionPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(KokoSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: KokoColors.canvasSoft,
              borderRadius: KokoRadius.lgBorder,
              border: Border.all(color: KokoColors.hairline),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 36,
              color: KokoColors.ink,
            ),
          ),
          const SizedBox(height: KokoSpacing.xxl),
          const Text(
            'Photo access',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: KokoColors.ink,
            ),
          ),
          const SizedBox(height: KokoSpacing.lg),
          const Text(
            'KokoShots needs access to your photos to discover and index screenshots on your device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              height: 1.5,
              color: KokoColors.body,
            ),
          ),
          const SizedBox(height: KokoSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () async {
                await controller.requestPermissionAndScan();
                onNext();
              },
              child: const Text('Allow photo access'),
            ),
          ),
          const SizedBox(height: KokoSpacing.lg),
          GestureDetector(
            onTap: onNext,
            child: const Text(
              'Skip for now',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: KokoColors.mute,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Indexing ──

class _IndexingPage extends ConsumerWidget {
  const _IndexingPage({required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);
    final progress = controller.screenshots.isEmpty
        ? 0.0
        : controller.processedCount / controller.screenshots.length;

    return Padding(
      padding: const EdgeInsets.all(KokoSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: KokoColors.canvasSoft,
              borderRadius: KokoRadius.lgBorder,
              border: Border.all(color: KokoColors.hairline),
            ),
            child: controller.isScanning
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KokoColors.ink,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                    size: 36,
                    color: KokoColors.ink,
                  ),
          ),
          const SizedBox(height: KokoSpacing.xxl),
          Text(
            controller.isScanning ? 'Indexing screenshots' : 'Ready to go',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: KokoColors.ink,
            ),
          ),
          const SizedBox(height: KokoSpacing.lg),
          Text(
            controller.statusText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: KokoColors.body,
            ),
          ),
          const SizedBox(height: KokoSpacing.xl),
          if (controller.screenshots.isNotEmpty) ...[
            ClipRRect(
              borderRadius: KokoRadius.smBorder,
              child: LinearProgressIndicator(
                minHeight: 4,
                value: progress == 0 ? null : progress,
                backgroundColor: KokoColors.canvasSoft,
                valueColor: const AlwaysStoppedAnimation(KokoColors.ink),
              ),
            ),
            const SizedBox(height: KokoSpacing.sm),
            Text(
              '${controller.screenshots.length} found · ${controller.processedCount} analyzed',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: KokoColors.mute,
              ),
            ),
          ],
          const SizedBox(height: KokoSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onComplete,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

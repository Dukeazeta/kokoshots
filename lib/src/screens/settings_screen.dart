import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/app_controller.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

/// Settings tab — API config, scan controls, indexing stats.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          KokoSpacing.xl,
          KokoSpacing.lg,
          KokoSpacing.xl,
          MediaQuery.of(context).padding.bottom + 100, // clear floating navbar
        ),
        children: [
          // ── Header ──
          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: KokoColors.ink,
            ),
          ),
          const SizedBox(height: KokoSpacing.xl),

          // ── Indexing stats ──
          _StatsRow(controller: controller),
          const SizedBox(height: KokoSpacing.lg),

          // ── Scan progress ──
          if (controller.isScanning) ...[
            ClipRRect(
              borderRadius: KokoRadius.smBorder,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: KokoColors.canvasSoft,
                valueColor: const AlwaysStoppedAnimation(KokoColors.ink),
              ),
            ),
            const SizedBox(height: KokoSpacing.sm),
            Text(
              controller.statusText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: KokoColors.mute,
              ),
            ),
            const SizedBox(height: KokoSpacing.lg),
          ],

          // ── Action buttons ──
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: controller.isScanning
                      ? null
                      : controller.requestPermissionAndScan,
                  icon: controller.isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: KokoColors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_motion, size: 18),
                  label: Text(controller.isScanning ? 'Scanning...' : 'Scan'),
                ),
              ),
              const SizedBox(width: KokoSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.geminiConfigured
                      ? controller.analyzePending
                      : null,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Analyze'),
                ),
              ),
            ],
          ),
          const SizedBox(height: KokoSpacing.xxl),

          // ── Config cards ──
          _ConfigCard(
            title: 'Gemini API key',
            status: controller.geminiConfigured ? 'Active' : 'Required',
            body:
                'Run with --dart-define=GEMINI_API_KEY=your_key to enable AI descriptions.',
            good: controller.geminiConfigured,
          ),
          const SizedBox(height: KokoSpacing.sm),
          _CodeBlock(
            text:
                'flutter run --dart-define=GEMINI_API_KEY=your_key_here',
          ),
          const SizedBox(height: KokoSpacing.lg),
          _ConfigCard(
            title: 'Gemini model',
            status: GeminiService.model,
            body:
                'Override with --dart-define=GEMINI_MODEL=gemini-2.0-flash if needed.',
            good: true,
          ),
          const SizedBox(height: KokoSpacing.lg),
          _ConfigCard(
            title: 'Photo permission',
            status: controller.permission == null
                ? 'Requested on scan'
                : controller.permission.toString(),
            body:
                'Android will ask for photo access when you first scan. Choose Allow.',
            good: true,
          ),
          const SizedBox(height: KokoSpacing.xxl),

          // ── Danger zone ──
          const Text(
            'DATA',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: KokoColors.mute,
            ),
          ),
          const SizedBox(height: KokoSpacing.md),
          OutlinedButton.icon(
            onPressed: controller.clearChat,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Clear chat history'),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ──

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'INDEXED',
          value: controller.screenshots.length.toString(),
        ),
        const SizedBox(width: KokoSpacing.sm),
        _StatTile(
          label: 'ANALYZED',
          value: controller.processedCount.toString(),
        ),
        const SizedBox(width: KokoSpacing.sm),
        _StatTile(
          label: 'PENDING',
          value: controller.pendingCount.toString(),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(KokoSpacing.lg),
        decoration: BoxDecoration(
          color: KokoColors.canvasSoft,
          borderRadius: KokoRadius.mdBorder,
          border: Border.all(color: KokoColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: KokoColors.ink,
              ),
            ),
            const SizedBox(height: KokoSpacing.xxs),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
                color: KokoColors.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Config card ──

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.title,
    required this.status,
    required this.body,
    required this.good,
  });

  final String title;
  final String status;
  final String body;
  final bool good;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KokoSpacing.lg),
      decoration: BoxDecoration(
        color: KokoColors.canvasSoft,
        borderRadius: KokoRadius.mdBorder,
        border: Border.all(color: KokoColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: KokoColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KokoSpacing.md,
                  vertical: KokoSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: good ? KokoColors.ink : KokoColors.warning,
                  borderRadius: KokoRadius.smBorder,
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: good ? KokoColors.onPrimary : KokoColors.canvas,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KokoSpacing.md),
          Text(
            body,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: KokoColors.body,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Code block ──

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KokoSpacing.lg),
      decoration: BoxDecoration(
        color: KokoColors.canvas,
        borderRadius: KokoRadius.mdBorder,
        border: Border.all(color: KokoColors.hairline),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: KokoColors.bodyStrong,
          height: 1.5,
        ),
      ),
    );
  }
}

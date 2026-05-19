import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';

/// Settings tab — API key input, scan controls, indexing stats.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;
  bool _apiKeySaved = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing key if configured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(appControllerProvider);
      if (controller.geminiConfigured) {
        _apiKeyController.text = '••••••••••••'; // mask existing key
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          KokoSpacing.xl,
          KokoSpacing.lg,
          KokoSpacing.xl,
          MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          // ── Header ──
          const Text(
            'Settings',
            style: TextStyle(
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
              style: const TextStyle(fontSize: 13, color: KokoColors.mute),
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

          // ── Gemini API Key ──
          const Text(
            'GEMINI API KEY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: KokoColors.mute,
            ),
          ),
          const SizedBox(height: KokoSpacing.sm),
          const Text(
            'Required for AI-powered screenshot descriptions and smart search.',
            style: TextStyle(fontSize: 13, color: KokoColors.body, height: 1.5),
          ),
          const SizedBox(height: KokoSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apiKeyController,
                  obscureText: _apiKeyObscured,
                  style: const TextStyle(
                    color: KokoColors.ink,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste your API key here',
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
                      child: Icon(
                        _apiKeyObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 18,
                        color: KokoColors.mute,
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_apiKeySaved) setState(() => _apiKeySaved = false);
                  },
                ),
              ),
              const SizedBox(width: KokoSpacing.sm),
              FilledButton(
                onPressed: () async {
                  final key = _apiKeyController.text.trim();
                  await controller.setApiKey(key);
                  setState(() => _apiKeySaved = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _apiKeySaved = false);
                  });
                },
                child: Text(_apiKeySaved ? '✓ Saved' : 'Save'),
              ),
            ],
          ),
          if (controller.geminiConfigured) ...[
            const SizedBox(height: KokoSpacing.sm),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: KokoColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: KokoSpacing.sm),
                const Text(
                  'API key active',
                  style: TextStyle(fontSize: 12, color: KokoColors.success),
                ),
              ],
            ),
          ],
          const SizedBox(height: KokoSpacing.xxl),

          // ── Data ──
          const Text(
            'DATA',
            style: TextStyle(
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
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: KokoColors.ink,
              ),
            ),
            const SizedBox(height: KokoSpacing.xxs),
            Text(
              label,
              style: const TextStyle(
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

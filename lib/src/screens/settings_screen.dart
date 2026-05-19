import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/app_controller.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Setup')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _SetupCard(
            title: 'Gemini API key',
            status: controller.geminiConfigured
                ? 'Configured'
                : 'Needs attention',
            body:
                'Build or run the app with --dart-define=GEMINI_API_KEY=your_key. The current app keeps local indexing available even before this is set.',
            good: controller.geminiConfigured,
          ),
          const SizedBox(height: 12),
          _CodeBlock(
            text:
                'flutter run --dart-define=GEMINI_API_KEY=your_key_here\nflutter build apk --dart-define=GEMINI_API_KEY=your_key_here',
          ),
          const SizedBox(height: 12),
          _SetupCard(
            title: 'Gemini model',
            status: GeminiService.model,
            body:
                'Optional override: --dart-define=GEMINI_MODEL=gemini-2.0-flash. Keep the default unless you have a specific model preference.',
            good: true,
          ),
          const SizedBox(height: 12),
          _SetupCard(
            title: 'Photo permission',
            status: controller.permission == null
                ? 'Requested on scan'
                : controller.permission.toString(),
            body:
                'Android will ask for photo access the first time you tap Scan. Choose Allow so KokoShots can index screenshots.',
            good: true,
          ),
          const SizedBox(height: 12),
          _SetupCard(
            title: 'Release signing',
            status: 'Needs attention before Play Store release',
            body:
                'The project currently uses debug signing for release builds. Add a real upload keystore before publishing.',
            good: false,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: controller.geminiConfigured
                ? controller.analyzePending
                : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Analyze pending screenshots'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.clearChat,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear chat history'),
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: good ? KokoColors.cream : KokoColors.orange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: good ? KokoColors.black : KokoColors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KokoColors.black,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: KokoColors.cream,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }
}

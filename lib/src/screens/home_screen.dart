import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/app_controller.dart';
import '../models/chat_message.dart';
import '../models/screenshot_item.dart';
import '../theme/app_theme.dart';
import '../widgets/screenshot_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _chatController = TextEditingController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    if (_searchController.text != controller.query) {
      _searchController.value = TextEditingValue(
        text: controller.query,
        selection: TextSelection.collapsed(offset: controller.query.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('KokoShots'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: controller.isLoading
          ? const _LoadingView()
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
                    child: _HeroPanel(controller: controller),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(
                      controller: _searchController,
                      onChanged: controller.setQuery,
                      decoration: const InputDecoration(
                        labelText: 'Search screenshots',
                        hintText: 'receipt, map, chat, code, bank app',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  if (controller.categories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = controller.categories[index];
                          return ActionChip(
                            onPressed: () {
                              _searchController.text = category.key;
                              controller.setQuery(category.key);
                            },
                            label: Text('${category.key} ${category.value}'),
                            backgroundColor: controller.query == category.key
                                ? KokoColors.black
                                : KokoColors.cream,
                            labelStyle: TextStyle(
                              color: controller.query == category.key
                                  ? KokoColors.white
                                  : KokoColors.black,
                            ),
                            side: const BorderSide(color: KokoColors.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentButton(
                            selected: _tabIndex == 0,
                            icon: Icons.grid_view,
                            label: 'Library',
                            onTap: () => setState(() => _tabIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _SegmentButton(
                            selected: _tabIndex == 1,
                            icon: Icons.forum_outlined,
                            label: 'Chat',
                            onTap: () => setState(() => _tabIndex = 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _tabIndex == 0
                          ? _LibraryView(
                              key: const ValueKey('library'),
                              items: controller.filteredScreenshots,
                              controller: controller,
                            )
                          : _ChatView(
                              key: const ValueKey('chat'),
                              messages: controller.messages,
                              controller: controller,
                              textController: _chatController,
                            ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: KokoColors.ivory,
          border: Border(top: BorderSide(color: KokoColors.line)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                controller.statusText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: controller.isScanning
                  ? null
                  : controller.requestPermissionAndScan,
              icon: controller.isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_motion),
              label: Text(controller.isScanning ? 'Indexing' : 'Scan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = controller.screenshots.isEmpty
        ? 0.0
        : controller.processedCount / controller.screenshots.length;

    return Container(
      decoration: BoxDecoration(
        color: KokoColors.cream,
        border: Border.all(color: KokoColors.line),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1f7f6315),
            offset: Offset(-8, 16),
            blurRadius: 39,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -24, top: -16, child: _KokoMark(size: 118)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SCREENSHOT MEMORY', style: textTheme.labelLarge),
                const SizedBox(height: 10),
                Text(
                  'Find the screenshot you meant to save.',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Metric(
                      label: 'Indexed',
                      value: controller.screenshots.length.toString(),
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      label: 'Analyzed',
                      value: controller.processedCount.toString(),
                    ),
                    const SizedBox(width: 10),
                    _Metric(
                      label: 'Pending',
                      value: controller.pendingCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress == 0 ? null : progress,
                    backgroundColor: KokoColors.ivory,
                    valueColor: const AlwaysStoppedAnimation(KokoColors.orange),
                  ),
                ),
                if (!controller.geminiConfigured) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Gemini API key is not set. Local indexing works now; AI descriptions unlock after you add the key.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView({
    super.key,
    required this.items,
    required this.controller,
  });

  final List<ScreenshotItem> items;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No screenshots indexed',
        body: 'Tap Scan to grant photo access and build your local library.',
        actionLabel: 'Scan screenshots',
        onAction: controller.requestPermissionAndScan,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.scanScreenshots,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .72,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => ScreenshotTile(item: items[index]),
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({
    super.key,
    required this.messages,
    required this.controller,
    required this.textController,
  });

  final List<ChatMessage> messages;
  final AppController controller;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _EmptyState(
                  icon: Icons.question_answer_outlined,
                  title: 'Ask for a screenshot',
                  body:
                      'Try: "receipts from last month" or "screenshots of maps".',
                  actionLabel: 'Use sample prompt',
                  onAction: () {
                    textController.text = 'Find receipts from last month';
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message.role == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 310),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser ? KokoColors.black : KokoColors.white,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isUser ? KokoColors.black : KokoColors.line,
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: isUser ? KokoColors.white : KokoColors.black,
                            height: 1.35,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: KokoColors.ivory,
            border: Border(top: BorderSide(color: KokoColors.line)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ask KokoShots',
                    hintText: 'Find that screenshot with...',
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Send',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _send() {
    final text = textController.text;
    textController.clear();
    controller.ask(text);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: KokoColors.ivory,
          border: Border.all(color: KokoColors.line),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? KokoColors.black : KokoColors.cream,
          border: Border.all(
            color: selected ? KokoColors.black : KokoColors.line,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? KokoColors.white : KokoColors.black,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? KokoColors.white : KokoColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 28.0;
        final minHeight = constraints.maxHeight > padding * 2
            ? constraints.maxHeight - padding * 2
            : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 42, color: KokoColors.orange),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ),
            ),
          ),
        ),
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _KokoMark extends StatelessWidget {
  const _KokoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = [
      KokoColors.gold,
      KokoColors.cream,
      KokoColors.amber,
      KokoColors.orange,
      KokoColors.flame,
    ];
    return Opacity(
      opacity: .62,
      child: SizedBox(
        width: size,
        height: size,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          children: List.generate(9, (index) {
            final active =
                index == 0 ||
                index == 2 ||
                index == 3 ||
                index == 4 ||
                index == 5 ||
                index == 6 ||
                index == 8;
            return Container(
              margin: const EdgeInsets.all(2),
              color: active
                  ? colors[index % colors.length]
                  : Colors.transparent,
            );
          }),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../controllers/app_controller.dart';
import '../models/chat_message.dart';
import '../models/screenshot_item.dart';
import '../screens/screenshot_viewer.dart';
import '../theme/app_theme.dart';

/// Dedicated chat screen for the AI screenshot search assistant.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(appControllerProvider).ask(text);
    // Scroll to bottom after a short delay for the new message to render
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final messages = controller.messages;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KokoSpacing.xl, KokoSpacing.lg, KokoSpacing.xl, KokoSpacing.sm,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'KokoShots AI',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.4,
                      color: KokoColors.ink,
                    ),
                  ),
                ),
                if (messages.isNotEmpty)
                  GestureDetector(
                    onTap: controller.clearChat,
                    child: const Text(
                      'Clear',
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
          ),
          const Divider(),

          // ── Message list ──
          Expanded(
            child: messages.isEmpty && !controller.isThinking
                ? _EmptyChatState(onPromptTap: (prompt) {
                    _textController.text = prompt;
                    _send();
                  })
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      KokoSpacing.xl, KokoSpacing.sm, KokoSpacing.xl, 100,
                    ),
                    itemCount: messages.length + (controller.isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Typing indicator at the end
                      if (index == messages.length) {
                        return const _TypingIndicator();
                      }
                      return _ChatBubble(
                        message: messages[index],
                        allScreenshots: controller.screenshots,
                      );
                    },
                  ),
          ),

          // ── Input bar ──
          Container(
            decoration: const BoxDecoration(
              color: KokoColors.canvas,
              border: Border(
                top: BorderSide(color: KokoColors.hairline),
              ),
            ),
            // Extra bottom padding to clear the floating navbar
            padding: EdgeInsets.fromLTRB(
              KokoSpacing.xl,
              KokoSpacing.sm,
              KokoSpacing.xl,
              MediaQuery.of(context).padding.bottom + 80,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(
                      color: KokoColors.ink,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Find that screenshot with...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: KokoSpacing.lg,
                        vertical: KokoSpacing.md,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: KokoSpacing.sm),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: KokoColors.ink,
                      borderRadius: KokoRadius.pillBorder,
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: KokoColors.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chat bubble with optional image previews ──

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.allScreenshots,
  });

  final ChatMessage message;
  final List<ScreenshotItem> allScreenshots;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final hasMatches = !isUser &&
        message.matchedAssetIds != null &&
        message.matchedAssetIds!.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: KokoSpacing.md),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Text bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? KokoColors.ink : KokoColors.canvasSoft,
                borderRadius: KokoRadius.mdBorder,
                border: isUser
                    ? null
                    : Border.all(color: KokoColors.hairline),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.42,
                  color: isUser ? KokoColors.onPrimary : KokoColors.ink,
                ),
              ),
            ),
            // Image preview row
            if (hasMatches) ...[
              const SizedBox(height: KokoSpacing.sm),
              _ImagePreviewRow(
                assetIds: message.matchedAssetIds!,
                allScreenshots: allScreenshots,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Inline image preview thumbnails ──

class _ImagePreviewRow extends StatelessWidget {
  const _ImagePreviewRow({
    required this.assetIds,
    required this.allScreenshots,
  });

  final List<String> assetIds;
  final List<ScreenshotItem> allScreenshots;

  @override
  Widget build(BuildContext context) {
    final displayIds = assetIds.take(6).toList();

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayIds.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: KokoSpacing.xs),
        itemBuilder: (context, index) {
          return _PreviewThumb(
            assetId: displayIds[index],
            allScreenshots: allScreenshots,
          );
        },
      ),
    );
  }
}

class _PreviewThumb extends StatefulWidget {
  const _PreviewThumb({
    required this.assetId,
    required this.allScreenshots,
  });

  final String assetId;
  final List<ScreenshotItem> allScreenshots;

  @override
  State<_PreviewThumb> createState() => _PreviewThumbState();
}

class _PreviewThumbState extends State<_PreviewThumb> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final asset = await AssetEntity.fromId(widget.assetId);
    if (asset == null) return;
    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(168, 224),
      quality: 72,
    );
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Find the item index in all screenshots
        final itemIndex = widget.allScreenshots
            .indexWhere((s) => s.assetId == widget.assetId);
        if (itemIndex == -1) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => ScreenshotViewer(
              items: widget.allScreenshots,
              initialIndex: itemIndex,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: KokoRadius.smBorder,
        child: SizedBox(
          width: 56,
          height: 74,
          child: _bytes != null
              ? Image.memory(_bytes!, fit: BoxFit.cover)
              : Container(color: KokoColors.canvasSoft),
        ),
      ),
    );
  }
}

// ── Typing indicator (pulsing dots) ──

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: KokoSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: KokoSpacing.lg,
          vertical: KokoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: KokoColors.canvasSoft,
          borderRadius: KokoRadius.mdBorder,
          border: Border.all(color: KokoColors.hairline),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final t = (_controller.value - delay).clamp(0.0, 1.0);
                // Pulsing opacity cycle
                final opacity = 0.3 + 0.7 * (0.5 + 0.5 * _cosine(t * 2));
                return Padding(
                  padding: EdgeInsets.only(
                    left: index > 0 ? 4.0 : 0,
                  ),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: KokoColors.body,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  double _cosine(double t) {
    // Simple cosine wave for smooth pulsing
    return (1.0 + (t * 3.14159 * 2).clamp(-6.28, 6.28).toDouble()) / 2.0;
  }
}

// ── Empty state with prompt chips ──

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.onPromptTap});

  final ValueChanged<String> onPromptTap;

  static const _prompts = [
    'Find receipts from last month',
    'Show me screenshots of maps',
    'Screenshots of my bank app',
    'That meme with the cat',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KokoSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: KokoColors.mute,
            ),
            const SizedBox(height: KokoSpacing.lg),
            const Text(
              'Ask for a screenshot',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: KokoColors.ink,
              ),
            ),
            const SizedBox(height: KokoSpacing.sm),
            const Text(
              'Describe what you remember and the AI will find it.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: KokoColors.body,
              ),
            ),
            const SizedBox(height: KokoSpacing.xl),
            Wrap(
              spacing: KokoSpacing.sm,
              runSpacing: KokoSpacing.sm,
              alignment: WrapAlignment.center,
              children: _prompts.map((prompt) {
                return GestureDetector(
                  onTap: () => onPromptTap(prompt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KokoSpacing.lg,
                      vertical: KokoSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: KokoColors.canvasSoft,
                      borderRadius: KokoRadius.smBorder,
                      border: Border.all(color: KokoColors.hairline),
                    ),
                    child: Text(
                      prompt,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: KokoColors.body,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

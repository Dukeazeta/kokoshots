import 'dart:io';
import 'dart:math' as math;
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
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final next = _textController.text.trim().isNotEmpty;
    if (next == _canSend) return;
    setState(() => _canSend = next);
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    ref.read(appControllerProvider).ask(text);
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
    final indexedCount = controller.screenshots.length;
    final status = indexedCount == 0
        ? 'Ready when screenshots are indexed'
        : '$indexedCount indexed screenshots';

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _ChatHeader(
            status: status,
            hasMessages: messages.isNotEmpty,
            onClear: controller.clearChat,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          KokoColors.canvasSoft.withValues(alpha: 0.28),
                          KokoColors.canvas.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.34],
                      ),
                    ),
                  ),
                ),
                messages.isEmpty && !controller.isThinking
                    ? _EmptyChatState(
                        indexedCount: indexedCount,
                        onPromptTap: (prompt) {
                          _textController.text = prompt;
                          _send();
                        },
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          KokoSpacing.xl,
                          KokoSpacing.lg,
                          KokoSpacing.xl,
                          112,
                        ),
                        itemCount:
                            messages.length + (controller.isThinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == messages.length) {
                            return const _TypingIndicator();
                          }
                          return _ChatBubble(
                            message: messages[index],
                            allScreenshots: controller.screenshots,
                          );
                        },
                      ),
              ],
            ),
          ),
          _ChatComposer(
            controller: _textController,
            canSend: _canSend,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.status,
    required this.hasMessages,
    required this.onClear,
  });

  final String status;
  final bool hasMessages;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: KokoColors.canvas,
        border: Border(bottom: BorderSide(color: KokoColors.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(
        KokoSpacing.xl,
        KokoSpacing.lg,
        KokoSpacing.xl,
        KokoSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: KokoColors.canvasSoft,
              borderRadius: KokoRadius.lgBorder,
              border: Border.all(color: KokoColors.hairline),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: KokoColors.ink,
            ),
          ),
          const SizedBox(width: KokoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KokoShots AI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    height: 1.12,
                    color: KokoColors.ink,
                  ),
                ),
                const SizedBox(height: KokoSpacing.xs),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: KokoColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: KokoSpacing.xs),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.2,
                          color: KokoColors.mute,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: KokoSpacing.md),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: hasMessages ? 1 : 0,
            child: IgnorePointer(
              ignoring: !hasMessages,
              child: TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Clear'),
                style: TextButton.styleFrom(
                  foregroundColor: KokoColors.mute,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KokoSpacing.md,
                    vertical: KokoSpacing.sm,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.allScreenshots});

  final ChatMessage message;
  final List<ScreenshotItem> allScreenshots;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final hasMatches =
        !isUser &&
        message.matchedAssetIds != null &&
        message.matchedAssetIds!.isNotEmpty;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final time = _formatTime(message.createdAt);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(260, 360)),
        margin: const EdgeInsets.only(bottom: KokoSpacing.lg),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
              decoration: BoxDecoration(
                color: isUser
                    ? KokoColors.ink
                    : KokoColors.canvasSoft.withValues(alpha: 0.86),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(KokoRadius.lg),
                  topRight: const Radius.circular(KokoRadius.lg),
                  bottomLeft: Radius.circular(
                    isUser ? KokoRadius.lg : KokoRadius.xs,
                  ),
                  bottomRight: Radius.circular(
                    isUser ? KokoRadius.xs : KokoRadius.lg,
                  ),
                ),
                border: Border.all(
                  color: isUser ? KokoColors.ink : KokoColors.hairline,
                ),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.42,
                  color: isUser ? KokoColors.onPrimary : KokoColors.ink,
                ),
              ),
            ),
            const SizedBox(height: KokoSpacing.xs),
            Text(
              isUser
                  ? time
                  : hasMatches
                  ? '$time - matches found'
                  : time,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                color: KokoColors.mute,
              ),
            ),
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

  String _formatTime(DateTime value) {
    if (value.millisecondsSinceEpoch == 0) return 'Saved';
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

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
    final overflow = assetIds.length - displayIds.length;

    return SizedBox(
      height: 104,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemCount: displayIds.length + (overflow > 0 ? 1 : 0),
        separatorBuilder: (context, index) =>
            const SizedBox(width: KokoSpacing.sm),
        itemBuilder: (context, index) {
          if (index == displayIds.length) {
            return _OverflowResultCard(count: overflow);
          }
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
  const _PreviewThumb({required this.assetId, required this.allScreenshots});

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
    final bytes =
        await asset?.thumbnailDataWithSize(
          const ThumbnailSize(168, 224),
          quality: 72,
        ) ??
        await _fileBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  Future<Uint8List?> _fileBytes() async {
    ScreenshotItem? item;
    for (final screenshot in widget.allScreenshots) {
      if (screenshot.assetId == widget.assetId) {
        item = screenshot;
        break;
      }
    }
    final path = item?.filePath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final itemIndex = widget.allScreenshots.indexWhere(
          (s) => s.assetId == widget.assetId,
        );
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
      child: Container(
        width: 72,
        padding: const EdgeInsets.all(KokoSpacing.xs),
        decoration: BoxDecoration(
          color: KokoColors.canvas,
          borderRadius: KokoRadius.lgBorder,
          border: Border.all(color: KokoColors.hairline),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: KokoRadius.mdBorder,
                child: SizedBox.expand(
                  child: _bytes != null
                      ? Image.memory(_bytes!, fit: BoxFit.cover)
                      : Container(
                          color: KokoColors.canvasSoft,
                          child: const Icon(
                            Icons.image_outlined,
                            size: 18,
                            color: KokoColors.mute,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: KokoSpacing.xs),
            const Icon(
              Icons.open_in_full_rounded,
              size: 11,
              color: KokoColors.mute,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverflowResultCard extends StatelessWidget {
  const _OverflowResultCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: KokoColors.canvasSoft.withValues(alpha: 0.72),
        borderRadius: KokoRadius.lgBorder,
        border: Border.all(color: KokoColors.hairline),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: KokoColors.ink,
        ),
      ),
    );
  }
}

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
        margin: const EdgeInsets.only(bottom: KokoSpacing.lg),
        padding: const EdgeInsets.symmetric(
          horizontal: KokoSpacing.lg,
          vertical: KokoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: KokoColors.canvasSoft,
          borderRadius: KokoRadius.lgBorder,
          border: Border.all(color: KokoColors.hairline),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final t = _controller.value * 2 * math.pi - delay * math.pi;
                final opacity = (0.35 + 0.65 * (0.5 + 0.5 * math.sin(t))).clamp(
                  0.0,
                  1.0,
                );
                return Padding(
                  padding: EdgeInsets.only(left: index > 0 ? 4.0 : 0),
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
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({
    required this.indexedCount,
    required this.onPromptTap,
  });

  final int indexedCount;
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          KokoSpacing.xl,
          KokoSpacing.xxl,
          KokoSpacing.xl,
          112,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: KokoColors.canvasSoft,
                borderRadius: KokoRadius.lgBorder,
                border: Border.all(color: KokoColors.hairline),
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 34,
                color: KokoColors.ink,
              ),
            ),
            const SizedBox(height: KokoSpacing.xl),
            const Text(
              'Search your visual memory',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.16,
                color: KokoColors.ink,
              ),
            ),
            const SizedBox(height: KokoSpacing.sm),
            Text(
              indexedCount == 0
                  ? 'Index screenshots first, then describe what you remember.'
                  : 'Ask in plain language across $indexedCount indexed screenshots.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: KokoColors.body,
              ),
            ),
            const SizedBox(height: KokoSpacing.xl),
            Wrap(
              spacing: KokoSpacing.sm,
              runSpacing: KokoSpacing.sm,
              alignment: WrapAlignment.center,
              children: _prompts.map((prompt) {
                return _PromptChip(prompt: prompt, onTap: onPromptTap);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.prompt, required this.onTap});

  final String prompt;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KokoColors.canvasSoft,
      borderRadius: KokoRadius.pillBorder,
      child: InkWell(
        onTap: () => onTap(prompt),
        borderRadius: KokoRadius.pillBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KokoSpacing.lg,
            vertical: KokoSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: KokoRadius.pillBorder,
            border: Border.all(color: KokoColors.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_rounded,
                size: 14,
                color: KokoColors.mute,
              ),
              const SizedBox(width: KokoSpacing.xs),
              Text(
                prompt,
                style: const TextStyle(
                  fontSize: 13,
                  color: KokoColors.bodyStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: KokoColors.canvas.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: KokoColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
        KokoSpacing.xl,
        KokoSpacing.md,
        KokoSpacing.xl,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          KokoSpacing.md,
          KokoSpacing.xs,
          KokoSpacing.xs,
          KokoSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: KokoColors.canvasSoft,
          borderRadius: KokoRadius.lgBorder,
          border: Border.all(color: KokoColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Padding(
              padding: EdgeInsets.only(
                left: KokoSpacing.xs,
                top: KokoSpacing.md,
                bottom: KokoSpacing.md,
              ),
              child: Icon(
                Icons.manage_search_rounded,
                size: 20,
                color: KokoColors.mute,
              ),
            ),
            const SizedBox(width: KokoSpacing.sm),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                style: const TextStyle(
                  color: KokoColors.ink,
                  fontSize: 14,
                  height: 1.35,
                ),
                decoration: const InputDecoration(
                  hintText: 'Describe the screenshot you remember',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: KokoSpacing.md,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: KokoSpacing.sm),
            GestureDetector(
              onTap: canSend ? onSend : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: canSend ? KokoColors.ink : KokoColors.hairline,
                  borderRadius: KokoRadius.mdBorder,
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: canSend ? KokoColors.onPrimary : KokoColors.mute,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

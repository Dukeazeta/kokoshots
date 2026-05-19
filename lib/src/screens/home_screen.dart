import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/screenshot_item.dart';
import '../theme/app_theme.dart';
import '../widgets/screenshot_tile.dart';
import '../widgets/shimmer_tile.dart';

/// Minimal grid-first home screen with date-grouped sections,
/// shimmer loading, and staggered reveal animation.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);

    // Sync the search field with controller query
    if (_searchController.text != controller.query) {
      _searchController.value = TextEditingValue(
        text: controller.query,
        selection: TextSelection.collapsed(offset: controller.query.length),
      );
    }

    if (controller.isLoading) {
      return const _ShimmerLoadingView();
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Header ──
          _Header(
            searchVisible: _searchVisible,
            onSearchToggle: () =>
                setState(() => _searchVisible = !_searchVisible),
            isScanning: controller.isScanning,
          ),

          // ── Scan progress bar (thin, auto-hides) ──
          if (controller.isScanning)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: KokoSpacing.xl),
              child: ClipRRect(
                borderRadius: KokoRadius.smBorder,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: KokoColors.canvasSoft,
                  valueColor:
                      const AlwaysStoppedAnimation(KokoColors.ink),
                ),
              ),
            ),

          // ── Search field ──
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                KokoSpacing.xl, KokoSpacing.sm, KokoSpacing.xl, 0,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: controller.setQuery,
                style: const TextStyle(
                  color: KokoColors.ink,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search screenshots...',
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: KokoColors.mute,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            controller.setQuery('');
                          },
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: KokoColors.mute,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            crossFadeState: _searchVisible
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),

          // ── Category chips ──
          if (controller.categories.isNotEmpty) ...[
            const SizedBox(height: KokoSpacing.md),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: KokoSpacing.xl),
                scrollDirection: Axis.horizontal,
                itemCount: controller.categories.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: KokoSpacing.sm),
                itemBuilder: (context, index) {
                  final category = controller.categories[index];
                  final isActive = controller.query == category.key;
                  return GestureDetector(
                    onTap: () {
                      if (isActive) {
                        _searchController.clear();
                        controller.setQuery('');
                      } else {
                        _searchController.text = category.key;
                        controller.setQuery(category.key);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: KokoSpacing.lg,
                        vertical: KokoSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? KokoColors.ink
                            : KokoColors.canvasSoft,
                        borderRadius: KokoRadius.smBorder,
                        border: Border.all(
                          color: isActive
                              ? KokoColors.ink
                              : KokoColors.hairline,
                        ),
                      ),
                      child: Text(
                        '${category.key} ${category.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? KokoColors.onPrimary
                              : KokoColors.body,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: KokoSpacing.md),

          // ── Image grid with date headers ──
          Expanded(
            child: controller.filteredScreenshots.isEmpty
                ? _EmptyLibrary(
                    hasScreenshots: controller.screenshots.isNotEmpty,
                    onScan: controller.requestPermissionAndScan,
                  )
                : _DateGroupedGrid(
                    items: controller.filteredScreenshots,
                    onRefresh: controller.scanScreenshots,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Header ──

class _Header extends StatelessWidget {
  const _Header({
    required this.searchVisible,
    required this.onSearchToggle,
    required this.isScanning,
  });

  final bool searchVisible;
  final VoidCallback onSearchToggle;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KokoSpacing.xl, KokoSpacing.lg, KokoSpacing.xl, KokoSpacing.sm,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'KokoShots',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
                color: KokoColors.ink,
              ),
            ),
          ),
          GestureDetector(
            onTap: onSearchToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: searchVisible
                    ? KokoColors.ink
                    : KokoColors.canvasSoft,
                borderRadius: KokoRadius.pillBorder,
                border: Border.all(color: KokoColors.hairline),
              ),
              child: Icon(
                searchVisible ? Icons.close : Icons.search,
                size: 18,
                color: searchVisible
                    ? KokoColors.onPrimary
                    : KokoColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date-grouped grid using CustomScrollView ──

class _DateGroupedGrid extends StatelessWidget {
  const _DateGroupedGrid({
    required this.items,
    required this.onRefresh,
  });

  final List<ScreenshotItem> items;
  final Future<void> Function() onRefresh;

  /// Groups items by calendar day and returns (label, items) pairs.
  List<_DateGroup> _buildGroups() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <_DateGroup>[];
    String? currentKey;
    List<ScreenshotItem> currentItems = [];

    for (final item in items) {
      final date = DateTime(
        item.dateTaken.year,
        item.dateTaken.month,
        item.dateTaken.day,
      );

      String label;
      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
        label = DateFormat.EEEE().format(item.dateTaken); // "Monday", etc.
      } else if (date.year == now.year) {
        label = DateFormat.MMMd().format(item.dateTaken); // "May 15"
      } else {
        label = DateFormat.yMMMd().format(item.dateTaken); // "May 15, 2025"
      }

      if (label != currentKey) {
        if (currentItems.isNotEmpty) {
          groups.add(_DateGroup(label: currentKey!, items: currentItems));
        }
        currentKey = label;
        currentItems = [item];
      } else {
        currentItems.add(item);
      }
    }
    if (currentItems.isNotEmpty && currentKey != null) {
      groups.add(_DateGroup(label: currentKey, items: currentItems));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _buildGroups();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: KokoColors.ink,
      backgroundColor: KokoColors.canvasSoft,
      child: CustomScrollView(
        slivers: [
          for (final group in groups) ...[
            // Date header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KokoSpacing.xl, KokoSpacing.lg, KokoSpacing.xl, KokoSpacing.sm,
                ),
                child: Text(
                  group.label,
                  style: const TextStyle(
                        fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: KokoColors.mute,
                  ),
                ),
              ),
            ),
            // Grid for this group
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: KokoSpacing.xl),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _StaggeredTile(
                      index: index,
                      child: ScreenshotTile(
                        item: group.items[index],
                        items: items,
                        index: items.indexOf(group.items[index]),
                      ),
                    );
                  },
                  childCount: group.items.length,
                ),
              ),
            ),
          ],
          // Bottom spacer for floating navbar
          SliverToBoxAdapter(
            child: SizedBox(height: bottomPadding + 100),
          ),
        ],
      ),
    );
  }
}

class _DateGroup {
  const _DateGroup({required this.label, required this.items});
  final String label;
  final List<ScreenshotItem> items;
}

// ── Staggered fade-in tile ──

class _StaggeredTile extends StatefulWidget {
  const _StaggeredTile({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredTile> createState() => _StaggeredTileState();
}

class _StaggeredTileState extends State<_StaggeredTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final delayMs = (widget.index * 50).clamp(0, 600);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ── Shimmer loading grid (shown during initial load) ──

class _ShimmerLoadingView extends StatelessWidget {
  const _ShimmerLoadingView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KokoSpacing.xl, KokoSpacing.lg, KokoSpacing.xl, KokoSpacing.sm,
            ),
            child: Container(
              width: 120,
              height: 28,
              decoration: BoxDecoration(
                color: KokoColors.canvasSoft,
                borderRadius: KokoRadius.smBorder,
              ),
            ),
          ),
          const SizedBox(height: KokoSpacing.xl),
          // Shimmer grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: KokoSpacing.xl),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                childAspectRatio: 0.75,
              ),
              itemCount: 12,
              itemBuilder: (context, index) => const ShimmerTile(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty library state ──

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({
    required this.hasScreenshots,
    required this.onScan,
  });

  final bool hasScreenshots;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final title =
        hasScreenshots ? 'No matches found' : 'No screenshots indexed';
    final body = hasScreenshots
        ? 'Try a different search term or category.'
        : 'Pull down to scan or tap the button below.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KokoSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasScreenshots
                  ? Icons.search_off_rounded
                  : Icons.photo_library_outlined,
              size: 40,
              color: KokoColors.mute,
            ),
            const SizedBox(height: KokoSpacing.lg),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: KokoColors.ink,
              ),
            ),
            const SizedBox(height: KokoSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: KokoColors.body,
              ),
            ),
            if (!hasScreenshots) ...[
              const SizedBox(height: KokoSpacing.xl),
              FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.auto_awesome_motion, size: 18),
                label: const Text('Scan screenshots'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

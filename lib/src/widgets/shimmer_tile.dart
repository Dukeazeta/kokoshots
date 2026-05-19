import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Animated skeleton placeholder tile with a diagonal shimmer sweep.
/// Used while thumbnails load and as a loading-state grid placeholder.
class ShimmerTile extends StatefulWidget {
  const ShimmerTile({super.key});

  @override
  State<ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: KokoRadius.mdBorder,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.0 + 2.0 * _controller.value, -0.3),
                end: Alignment(-0.5 + 2.0 * _controller.value, 0.3),
                colors: const [
                  KokoColors.canvasSoft,
                  Color(0xff4a4541), // slightly lighter highlight
                  KokoColors.canvasSoft,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}

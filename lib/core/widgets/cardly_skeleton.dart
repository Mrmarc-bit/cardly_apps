import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_motion.dart';

/// Skeleton Pulse Loader Cardly sesuai DESAIN.md (Animasi pulsasi tenang 0.65-1.00)
class CardlySkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const CardlySkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  const CardlySkeleton.rectangular({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.inputRadius,
  });

  const CardlySkeleton.circular({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = AppRadius.pillRadius;

  @override
  State<CardlySkeleton> createState() => _CardlySkeletonState();
}

class _CardlySkeletonState extends State<CardlySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.skeletonPulseDuration,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.pulseCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppColors.elevatedDark : AppColors.softGray;
    final radius = widget.borderRadius ?? AppRadius.inputRadius;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(color: baseColor, borderRadius: radius),
          ),
        );
      },
    );
  }
}

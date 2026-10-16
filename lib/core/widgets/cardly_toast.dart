import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

enum CardlyToastType { success, info, warning, error }

/// Floating pill toast modern Cardly dengan haptic feedback dan animasi elegan.
class CardlyToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    CardlyToastType type = CardlyToastType.info,
    Duration duration = const Duration(milliseconds: 2500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Haptic feedback sesuai tipe
    if (type == CardlyToastType.error) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      entry.remove();
      if (_currentEntry == entry) _currentEntry = null;
    });
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message, type: CardlyToastType.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message, type: CardlyToastType.error);
  }

  static void showInfo(BuildContext context, String message) {
    show(context, message, type: CardlyToastType.info);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final CardlyToastType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case CardlyToastType.success:
        return Icons.check_circle_rounded;
      case CardlyToastType.error:
        return Icons.error_rounded;
      case CardlyToastType.warning:
        return Icons.warning_amber_rounded;
      case CardlyToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case CardlyToastType.success:
        return AppColors.lime;
      case CardlyToastType.error:
        return const Color(0xFFFF5252);
      case CardlyToastType.warning:
        return const Color(0xFFFFB74D);
      case CardlyToastType.info:
        return AppColors.lime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 12.0;

    return Positioned(
      top: topPadding,
      left: 16.0,
      right: 16.0,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(
                    color: AppColors.charcoal.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16.0,
                      offset: const Offset(0.0, 6.0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIcon(), color: _getIconColor(), size: 20.0),
                    const SizedBox(width: 12.0),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: AppTypography.bodySmall(context).copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null &&
                        widget.onAction != null) ...[
                      const SizedBox(width: 12.0),
                      GestureDetector(
                        onTap: () {
                          widget.onAction?.call();
                          widget.onDismiss();
                        },
                        child: Text(
                          widget.actionLabel!,
                          style: AppTypography.caption(context).copyWith(
                            color: AppColors.lime,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Komponen Avatar Cardly Universal
/// Mendukung foto dari URL Cloud (Supabase Storage/Google),
/// berkas lokal di HP, maupun inisial huruf nama pengguna.
class CardlyAvatar extends StatelessWidget {
  final String avatarPath;
  final String name;
  final double size;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const CardlyAvatar({
    super.key,
    required this.avatarPath,
    required this.name,
    this.size = 64.0,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
  });

  bool get _isNetwork =>
      avatarPath.startsWith('http://') || avatarPath.startsWith('https://');

  bool get _isLocalFile =>
      avatarPath.isNotEmpty && !_isNetwork && File(avatarPath).existsSync();

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? AppColors.lime.withValues(alpha: 0.35);

    Widget avatarContent;

    if (_isNetwork) {
      avatarContent = Image.network(
        avatarPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackInitial(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.lime,
              ),
            ),
          );
        },
      );
    } else if (_isLocalFile) {
      avatarContent = Image.file(
        File(avatarPath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackInitial(),
      );
    } else {
      avatarContent = _buildFallbackInitial();
    }

    final avatarCircle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lime,
        border: showBorder
            ? Border.all(color: effectiveBorderColor, width: 2.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(child: avatarContent),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: avatarCircle,
      );
    }

    return avatarCircle;
  }

  Widget _buildFallbackInitial() {
    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : 'C';

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

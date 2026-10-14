import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';
import '../theme/app_motion.dart';

enum CardlyButtonVariant { primary, secondary, destructive, quiet }

/// Unified Cardly Button component supporting all 4 variants
class CardlyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CardlyButtonVariant variant;
  final IconData? icon;
  final Widget? leadingIcon;
  final bool isLoading;
  final double height;
  final BorderRadius? borderRadius;

  const CardlyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = CardlyButtonVariant.primary,
    this.icon,
    this.leadingIcon,
    this.isLoading = false,
    this.height = 52.0,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLeading =
        leadingIcon ??
        (icon != null
            ? Icon(
                icon,
                size: 20,
                color: variant == CardlyButtonVariant.primary
                    ? AppColors.ink
                    : variant == CardlyButtonVariant.destructive
                    ? AppColors.white
                    : null,
              )
            : null);

    switch (variant) {
      case CardlyButtonVariant.primary:
        return CardlyPrimaryButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          leadingIcon: effectiveLeading,
          height: height,
          borderRadius: borderRadius,
        );
      case CardlyButtonVariant.secondary:
        return CardlySecondaryButton(
          text: text,
          onPressed: onPressed,
          leadingIcon: effectiveLeading,
          height: height,
          borderRadius: borderRadius,
        );
      case CardlyButtonVariant.destructive:
        return CardlyDestructiveButton(
          text: text,
          onPressed: onPressed,
          isLoading: isLoading,
          height: height,
        );
      case CardlyButtonVariant.quiet:
        return CardlyQuietButton(text: text, onPressed: onPressed);
    }
  }
}

/// Tombol Primer Cardly berlatar Lime (#C8F45A) dengan teks Ink (#171717)
class CardlyPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? leadingIcon;
  final double height;
  final BorderRadius? borderRadius;

  const CardlyPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.height = 52.0,
    this.borderRadius,
  });

  @override
  State<CardlyPrimaryButton> createState() => _CardlyPrimaryButtonState();
}

class _CardlyPrimaryButtonState extends State<CardlyPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final radius = widget.borderRadius ?? AppRadius.pillRadius;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? AppMotion.pressedScale : 1.0,
        duration: AppMotion.pressDuration,
        curve: AppMotion.defaultCurve,
        child: AnimatedOpacity(
          opacity: isEnabled
              ? (_isPressed ? AppMotion.pressedOpacity : 1.0)
              : 0.6,
          duration: AppMotion.pressDuration,
          child: Container(
            height: widget.height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isEnabled ? AppColors.lime : AppColors.softGray,
              borderRadius: radius,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        widget.leadingIcon!,
                        const SizedBox(width: 8.0),
                      ],
                      Text(
                        widget.text,
                        style: AppTypography.bodySemiBoldStyle.copyWith(
                          color: isEnabled
                              ? AppColors.ink
                              : AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Sekunder Cardly berlatar Soft Gray (#EBEBE8)
class CardlySecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? leadingIcon;
  final double height;
  final BorderRadius? borderRadius;

  const CardlySecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.leadingIcon,
    this.height = 52.0,
    this.borderRadius,
  });

  @override
  State<CardlySecondaryButton> createState() => _CardlySecondaryButtonState();
}

class _CardlySecondaryButtonState extends State<CardlySecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null;
    final bgColor = isDark ? AppColors.elevatedDark : AppColors.softGray;
    final textColor = isDark ? AppColors.white : AppColors.ink;
    final radius = widget.borderRadius ?? AppRadius.pillRadius;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? AppMotion.pressedScale : 1.0,
        duration: AppMotion.pressDuration,
        curve: AppMotion.defaultCurve,
        child: AnimatedOpacity(
          opacity: isEnabled
              ? (_isPressed ? AppMotion.pressedOpacity : 1.0)
              : 0.5,
          duration: AppMotion.pressDuration,
          child: Container(
            height: widget.height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bgColor, borderRadius: radius),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.leadingIcon != null) ...[
                  widget.leadingIcon!,
                  const SizedBox(width: 8.0),
                ],
                Text(
                  widget.text,
                  style: AppTypography.bodySemiBoldStyle.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Destruktif Cardly berlatar Merah (#B93838) dengan teks Putih
class CardlyDestructiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const CardlyDestructiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.height = 52.0,
  });

  @override
  State<CardlyDestructiveButton> createState() =>
      _CardlyDestructiveButtonState();
}

class _CardlyDestructiveButtonState extends State<CardlyDestructiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _isPressed ? AppMotion.pressedScale : 1.0,
        duration: AppMotion.pressDuration,
        curve: AppMotion.defaultCurve,
        child: AnimatedOpacity(
          opacity: isEnabled
              ? (_isPressed ? AppMotion.pressedOpacity : 1.0)
              : 0.5,
          duration: AppMotion.pressDuration,
          child: Container(
            height: widget.height,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.error,
              borderRadius: AppRadius.pillRadius,
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                : Text(
                    widget.text,
                    style: AppTypography.bodySemiBoldStyle.copyWith(
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tombol Quiet/Ghost Cardly tanpa latar belakang
class CardlyQuietButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? textColor;

  const CardlyQuietButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = textColor ?? (isDark ? AppColors.white : AppColors.ink);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMediumStyle.copyWith(color: color),
      ),
    );
  }
}

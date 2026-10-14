import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Komponen visual PIN 6-digit & Keypad Numerik interaktif resmi Cardly.
class CardlyPinPad extends StatefulWidget {
  final int pinLength;
  final String currentPin;
  final bool hasError;
  final bool isBiometricAvailable;
  final ValueChanged<String> onPinChanged;
  final VoidCallback? onBiometricPressed;
  final VoidCallback? onCompleted;

  const CardlyPinPad({
    super.key,
    this.pinLength = 6,
    required this.currentPin,
    this.hasError = false,
    this.isBiometricAvailable = false,
    required this.onPinChanged,
    this.onBiometricPressed,
    this.onCompleted,
  });

  @override
  State<CardlyPinPad> createState() => _CardlyPinPadState();
}

class _CardlyPinPadState extends State<CardlyPinPad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant CardlyPinPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward(from: 0.0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleNumberPress(String digit) {
    if (widget.currentPin.length < widget.pinLength) {
      HapticFeedback.lightImpact();
      final newPin = widget.currentPin + digit;
      widget.onPinChanged(newPin);
      if (newPin.length == widget.pinLength && widget.onCompleted != null) {
        widget.onCompleted!();
      }
    }
  }

  void _handleBackspace() {
    if (widget.currentPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      final newPin = widget.currentPin.substring(
        0,
        widget.currentPin.length - 1,
      );
      widget.onPinChanged(newPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Deretan Indikator Titik PIN (6 Dots) dengan Animasi Shake
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = widget.hasError
                ? math.sin(_shakeAnimation.value * math.pi * 4) * 10.0
                : 0.0;
            return Transform.translate(
              offset: Offset(offset, 0.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.pinLength, (index) {
                  final isFilled = index < widget.currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    margin: const EdgeInsets.symmetric(horizontal: 10.0),
                    width: isFilled ? 18.0 : 16.0,
                    height: isFilled ? 18.0 : 16.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.hasError
                          ? AppColors.error
                          : (isFilled
                                ? (isDark ? AppColors.lime : AppColors.ink)
                                : Colors.transparent),
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.error
                            : (isFilled
                                  ? (isDark ? AppColors.lime : AppColors.ink)
                                  : (isDark
                                        ? AppColors.white.withValues(
                                            alpha: 0.35,
                                          )
                                        : AppColors.ink.withValues(
                                            alpha: 0.30,
                                          ))),
                        width: 2.0,
                      ),
                      boxShadow: isFilled && !widget.hasError && isDark
                          ? [
                              BoxShadow(
                                color: AppColors.lime.withValues(alpha: 0.5),
                                blurRadius: 10.0,
                                spreadRadius: 1.0,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            );
          },
        ),

        const SizedBox(height: 24.0),

        // 2. Touch Numpad Grid (3 x 4)
        Container(
          constraints: const BoxConstraints(maxWidth: 320.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNumpadRow(['1', '2', '3'], isDark),
              const SizedBox(height: 12.0),
              _buildNumpadRow(['4', '5', '6'], isDark),
              const SizedBox(height: 12.0),
              _buildNumpadRow(['7', '8', '9'], isDark),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Tombol Biometrik di kiri bawah
                  widget.isBiometricAvailable &&
                          widget.onBiometricPressed != null
                      ? _buildActionKey(
                          icon: Icons.fingerprint_rounded,
                          isDark: isDark,
                          onPressed: widget.onBiometricPressed!,
                          tooltip: 'Buka dengan Biometrik',
                        )
                      : const SizedBox(width: 72.0, height: 72.0),

                  // Angka 0 di tengah
                  _buildNumberKey('0', isDark),

                  // Tombol Backspace di kanan bawah
                  _buildActionKey(
                    icon: Icons.backspace_outlined,
                    isDark: isDark,
                    onPressed: _handleBackspace,
                    tooltip: 'Hapus digit',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumpadRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildNumberKey(digit, isDark)).toList(),
    );
  }

  static const Map<String, String> _subtitles = {
    '1': '',
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '',
  };

  Widget _buildNumberKey(String digit, bool isDark) {
    final bgColor = isDark ? const Color(0xFF262626) : AppColors.white;
    final textColor = isDark ? AppColors.white : AppColors.ink;
    final subtitle = _subtitles[digit] ?? '';

    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      elevation: isDark ? 0.0 : 1.0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => _handleNumberPress(digit),
        customBorder: const CircleBorder(),
        splashColor: AppColors.lime.withValues(alpha: 0.35),
        highlightColor: AppColors.lime.withValues(alpha: 0.15),
        child: SizedBox(
          width: 72.0,
          height: 72.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: AppTypography.tabular(
                  TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: AppTypography.fontFamily,
                    height: 1.1,
                  ),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 1.0),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: isDark
                        ? AppColors.white.withValues(alpha: 0.40)
                        : AppColors.ink.withValues(alpha: 0.40),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 72.0,
            height: 72.0,
            child: Center(
              child: Icon(
                icon,
                size: 26.0,
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.85)
                    : AppColors.ink.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

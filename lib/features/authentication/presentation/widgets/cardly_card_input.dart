import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';

/// Form Input bergaya Kartu Terbungkus (Enclosed Card Input)
/// Sesuai spesifikasi visual Figma (docs/4. Authentication/06 Masuk.png & 07 Buat akun.png)
class CardlyCardInput extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final bool autofocus;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? internalHelperText;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;

  const CardlyCardInput({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.isPassword = false,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.internalHelperText,
    this.errorText,
    this.inputFormatters,
  });

  @override
  State<CardlyCardInput> createState() => _CardlyCardInputState();
}

class _CardlyCardInputState extends State<CardlyCardInput> {
  late bool _isObscured;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
    _focusNode.addListener(() {
      if (mounted) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Background kartu: Putih di mode Terang, Charcoal di mode Gelap
    final cardBgColor = isDark ? AppColors.charcoal : AppColors.white;

    // Border: Halus secara default, Lime/Ink saat fokus, Merah saat error
    Color borderColor;
    if (hasError) {
      borderColor = AppColors.error;
    } else if (_isFocused) {
      borderColor = isDark ? AppColors.lime : AppColors.ink;
    } else {
      borderColor = isDark ? AppColors.elevatedDark : AppColors.softGray;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_focusNode.hasFocus) {
              _focusNode.requestFocus();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 12.0,
            ),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: AppRadius.inputRadius,
              border: Border.all(
                color: borderColor,
                width: _isFocused || hasError ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (!isDark && _isFocused)
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.04),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label di dalam kartu (atas)
                Text(
                  widget.label,
                  style: AppTypography.captionMedium.copyWith(
                    fontSize: 12.0,
                    color: hasError
                        ? AppColors.error
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.ink.withValues(alpha: 0.6)),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2.0),

                // Baris Input Teks & Action Toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        autofocus: widget.autofocus,
                        obscureText: widget.isPassword ? _isObscured : false,
                        keyboardType: widget.keyboardType,
                        textInputAction: widget.textInputAction,
                        onChanged: widget.onChanged,
                        onFieldSubmitted: widget.onSubmitted,
                        inputFormatters: widget.inputFormatters,
                        style: AppTypography.body.copyWith(
                          color: isDark ? AppColors.white : AppColors.ink,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4.0,
                          ),
                          hintText: widget.hintText,
                          hintStyle: AppTypography.body.copyWith(
                            color: isDark
                                ? AppColors.mediumGray
                                : AppColors.muted.withValues(alpha: 0.7),
                            fontSize: 15.0,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    if (widget.isPassword)
                      GestureDetector(
                        onTap: () => setState(() => _isObscured = !_isObscured),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            _isObscured
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20.0,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.ink.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),

                // Helper teks internal kartu (jika ada, misal info syarat kata sandi)
                if (widget.internalHelperText != null &&
                    widget.internalHelperText!.isNotEmpty) ...[
                  const SizedBox(height: 6.0),
                  Text(
                    widget.internalHelperText!,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11.5,
                      color: isDark ? AppColors.mediumGray : AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Teks Error di luar kartu
        if (hasError) ...[
          const SizedBox(height: 6.0),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              widget.errorText!,
              style: AppTypography.caption.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

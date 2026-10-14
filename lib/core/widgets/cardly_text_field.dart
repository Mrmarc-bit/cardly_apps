import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_radius.dart';

/// Form Input Cardly sesuai spesifikasi DESAIN.md (Tinggi 56 pt, Radius 16 pt, Focus tanpa glow)
class CardlyTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? hintText;
  final String? errorText;
  final bool isPassword;
  final bool obscureText;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final bool autofocus;

  const CardlyTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.hintText,
    this.errorText,
    this.isPassword = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<CardlyTextField> createState() => _CardlyTextFieldState();
}

class _CardlyTextFieldState extends State<CardlyTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword || widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final effectiveHint = widget.hint ?? widget.hintText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: AppTypography.captionMediumStyle.copyWith(
              color: hasError
                  ? AppColors.error
                  : (isDark ? AppColors.textSecondaryDark : AppColors.muted),
            ),
          ),
          const SizedBox(height: 6.0),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          obscureText: (widget.isPassword || widget.obscureText)
              ? _isObscured
              : false,
          keyboardType: widget.keyboardType,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          maxLength: widget.maxLength,
          maxLines: (widget.isPassword || widget.obscureText)
              ? 1
              : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: AppTypography.bodyStyle.copyWith(
            color: isDark ? AppColors.white : AppColors.ink,
          ),
          decoration: InputDecoration(
            hintText: effectiveHint,
            counterText: '',
            prefixIcon: widget.prefixIcon,
            suffixIcon: (widget.isPassword || widget.obscureText)
                ? IconButton(
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.muted,
                      size: 20.0,
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: isDark ? AppColors.charcoal : AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(
                color: isDark ? AppColors.elevatedDark : AppColors.softGray,
                width: 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error
                    : (isDark ? AppColors.elevatedDark : AppColors.softGray),
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.inputRadius,
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error
                    : (isDark ? AppColors.white : AppColors.ink),
                width: 1.5,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4.0),
          Text(
            widget.errorText!,
            style: AppTypography.captionStyle.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

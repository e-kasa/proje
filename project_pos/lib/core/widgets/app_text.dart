import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Merkezi Tipografi Sistemi - Tüm ekranlarda metin standartı için
class AppText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const AppText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  });

  // Display Styles
  factory AppText.display(String text, {Color? color, TextAlign? textAlign}) => AppText(
        text,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: color ?? AppColors.textPrimary,
          letterSpacing: -1,
        ),
        textAlign: textAlign,
      );

  // Headline Styles
  factory AppText.headline(String text, {Color? color, TextAlign? textAlign}) => AppText(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: color ?? AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        textAlign: textAlign,
      );

  // Title Styles
  factory AppText.title(String text, {Color? color, FontWeight? fontWeight, TextAlign? textAlign}) => AppText(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: fontWeight ?? FontWeight.w700,
          color: color ?? AppColors.textPrimary,
        ),
        textAlign: textAlign,
      );

  // Body Styles
  factory AppText.body(String text, {Color? color, FontWeight? fontWeight, TextAlign? textAlign, int? maxLines}) => AppText(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: fontWeight ?? FontWeight.w400,
          color: color ?? AppColors.textPrimary,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );

  // Label Styles (Small/Secondary)
  factory AppText.label(String text, {Color? color, FontWeight? fontWeight, TextAlign? textAlign}) => AppText(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: fontWeight ?? FontWeight.w500,
          color: color ?? AppColors.textSecondary,
        ),
        textAlign: textAlign,
      );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: style?.copyWith(
            color: color,
            fontWeight: fontWeight,
            fontSize: fontSize,
          ) ??
          TextStyle(
            color: color,
            fontWeight: fontWeight,
            fontSize: fontSize,
          ),
    );
  }
}

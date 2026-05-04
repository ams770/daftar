import 'package:flutter/material.dart';

class DaftarThemeExtension extends ThemeExtension<DaftarThemeExtension> {
  final Color surfaceColor;
  final BoxDecoration cardDecoration;
  final BoxDecoration daftarBoxDecoration;

  const DaftarThemeExtension({
    required this.surfaceColor,
    required this.cardDecoration,
    required this.daftarBoxDecoration,
  });

  @override
  ThemeExtension<DaftarThemeExtension> copyWith({
    Color? surfaceColor,
    BoxDecoration? cardDecoration,
    BoxDecoration? daftarBoxDecoration,
  }) {
    return DaftarThemeExtension(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardDecoration: cardDecoration ?? this.cardDecoration,
      daftarBoxDecoration: daftarBoxDecoration ?? this.daftarBoxDecoration,
    );
  }

  @override
  ThemeExtension<DaftarThemeExtension> lerp(
    ThemeExtension<DaftarThemeExtension>? other,
    double t,
  ) {
    if (other is! DaftarThemeExtension) return this;
    return DaftarThemeExtension(
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      cardDecoration: BoxDecoration.lerp(
        cardDecoration,
        other.cardDecoration,
        t,
      )!,
      daftarBoxDecoration: BoxDecoration.lerp(
        daftarBoxDecoration,
        other.daftarBoxDecoration,
        t,
      )!,
    );
  }
}

import 'package:flutter/material.dart';

class BentoThemeExtension extends ThemeExtension<BentoThemeExtension> {
  final Color surfaceColor;
  final BoxDecoration cardDecoration;
  final BoxDecoration bentoBoxDecoration;

  const BentoThemeExtension({
    required this.surfaceColor,
    required this.cardDecoration,
    required this.bentoBoxDecoration,
  });

  @override
  ThemeExtension<BentoThemeExtension> copyWith({
    Color? surfaceColor,
    BoxDecoration? cardDecoration,
    BoxDecoration? bentoBoxDecoration,
  }) {
    return BentoThemeExtension(
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardDecoration: cardDecoration ?? this.cardDecoration,
      bentoBoxDecoration: bentoBoxDecoration ?? this.bentoBoxDecoration,
    );
  }

  @override
  ThemeExtension<BentoThemeExtension> lerp(
    ThemeExtension<BentoThemeExtension>? other,
    double t,
  ) {
    if (other is! BentoThemeExtension) return this;
    return BentoThemeExtension(
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      cardDecoration: BoxDecoration.lerp(cardDecoration, other.cardDecoration, t)!,
      bentoBoxDecoration: BoxDecoration.lerp(bentoBoxDecoration, other.bentoBoxDecoration, t)!,
    );
  }
}

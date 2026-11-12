import 'dart:ui' show FontVariation;

import 'package:flutter/material.dart';

/// Typographie locale : Inter pour l'interface et Space Grotesk pour
/// les titres importants. Les deux polices sont des fichiers variables.
abstract final class AmzTypography {
  static TextTheme apply(TextTheme base, Color primary, Color secondary) {
    TextStyle? style(
        TextStyle? source, {
          required String family,
          required FontWeight weight,
          required double axisWeight,
          Color? color,
        }) => source?.copyWith(
      fontFamily: family,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', axisWeight)],
      color: color ?? primary,
    );

    return base.copyWith(
      displayLarge: style(base.displayLarge, family: 'SpaceGrotesk', weight: FontWeight.w700, axisWeight: 700),
      displayMedium: style(base.displayMedium, family: 'SpaceGrotesk', weight: FontWeight.w700, axisWeight: 700),
      displaySmall: style(base.displaySmall, family: 'SpaceGrotesk', weight: FontWeight.w600, axisWeight: 600),
      headlineLarge: style(base.headlineLarge, family: 'SpaceGrotesk', weight: FontWeight.w700, axisWeight: 700),
      headlineMedium: style(base.headlineMedium, family: 'SpaceGrotesk', weight: FontWeight.w700, axisWeight: 700),
      headlineSmall: style(base.headlineSmall, family: 'SpaceGrotesk', weight: FontWeight.w700, axisWeight: 700),
      titleLarge: style(base.titleLarge, family: 'SpaceGrotesk', weight: FontWeight.w600, axisWeight: 600),
      titleMedium: style(base.titleMedium, family: 'Inter', weight: FontWeight.w600, axisWeight: 600),
      titleSmall: style(base.titleSmall, family: 'Inter', weight: FontWeight.w600, axisWeight: 600),
      bodyLarge: style(base.bodyLarge, family: 'Inter', weight: FontWeight.w400, axisWeight: 400),
      bodyMedium: style(base.bodyMedium, family: 'Inter', weight: FontWeight.w400, axisWeight: 400),
      bodySmall: style(base.bodySmall, family: 'Inter', weight: FontWeight.w400, axisWeight: 400, color: secondary),
      labelLarge: style(base.labelLarge, family: 'Inter', weight: FontWeight.w600, axisWeight: 600),
      labelMedium: style(base.labelMedium, family: 'Inter', weight: FontWeight.w500, axisWeight: 500),
      labelSmall: style(base.labelSmall, family: 'Inter', weight: FontWeight.w500, axisWeight: 500),
    );
  }
}

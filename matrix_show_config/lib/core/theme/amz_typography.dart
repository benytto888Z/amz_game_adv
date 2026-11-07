import 'package:flutter/material.dart';

abstract final class AmzTypography {
  static TextTheme apply(TextTheme base, Color primary, Color secondary) {
    return base.apply(bodyColor: primary, displayColor: primary).copyWith(
      headlineSmall: base.headlineSmall?.copyWith(color: primary, fontWeight: FontWeight.w700),
      bodySmall: base.bodySmall?.copyWith(color: secondary),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
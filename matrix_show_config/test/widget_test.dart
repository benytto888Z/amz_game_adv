import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_show_config/main.dart';
import 'package:matrix_show_config/core/theme/amz_colors.dart';
import 'package:matrix_show_config/core/theme/amz_dark_theme.dart';
import 'package:matrix_show_config/core/theme/amz_light_theme.dart';

void main() {
  tearDown(Get.reset);
  test('Les deux thèmes utilisent les couleurs officielles', () {
    expect(amzDarkTheme.scaffoldBackgroundColor, AmzColors.darkBackground);
    expect(amzLightTheme.scaffoldBackgroundColor, AmzColors.lightBackground);
    expect(amzDarkTheme.colorScheme.primary, AmzColors.darkPrimary);
    expect(amzLightTheme.colorScheme.primary, AmzColors.lightPrimary);
  });
  testWidgets('La connexion reste disponible sur téléphone', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AmzApp());
    expect(find.text('Connecter le panneau'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
  testWidgets('Une navigation latérale est présente sur tablette', (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const AmzApp());
    expect(find.byType(NavigationRail), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matrix_show_config/main.dart';
import 'package:matrix_show_config/features/game_settings/game_settings_page.dart';
import 'package:matrix_show_config/services/panel_service.dart';

class FakeService extends PanelService {
  PanelConfig current=const PanelConfig(targetCs:1000,marginCs:0,easyRgb:0x00ff00,hardRgb:0xff0000,traversalMs:1000);
  @override Future<PanelConfig> getConfig() async => current;
  @override Future<PanelConfig> setConfig(PanelConfig c) async { current=c; return c; }
}

void main() {
  tearDown(Get.reset);
  testWidgets('Préréglages sans champ hexadécimal', (tester) async {
    final service=FakeService();
    await tester.pumpWidget(GetMaterialApp(translations:Texts(),locale:const Locale('fr','FR'),
        home:GameSettingsPage(service:service,connected:true.obs,gameState:'pret'.obs)));
    await tester.pumpAndSettle();
    expect(find.text('#00FF00'),findsNothing);
    expect(find.byType(TextFormField),findsNWidgets(3));
    expect(find.byTooltip('Vert'),findsNWidgets(2));
    await tester.ensureVisible(find.byTooltip('Bleu').first);
    await tester.tap(find.byTooltip('Bleu').first);
    await tester.ensureVisible(find.text('Appliquer au panneau'));
    await tester.tap(find.text('Appliquer au panneau'));
    await tester.pumpAndSettle();
    expect(service.current.easyRgb,0x0000ff);
  });
}
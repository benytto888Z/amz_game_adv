import 'package:flutter_test/flutter_test.dart';
import 'package:matrix_show_config/services/panel_service.dart';

void main() {
  test('Le JSON de configuration est lu et remis au bon format', () {
    final input=<String,dynamic>{'cible_cs':800,'marge_cs':5,'facile_rgb':255,'difficile_rgb':16711680,'traversee_ms':1500};
    expect(PanelConfig.fromJson(input).toJson(), input);
  });
  test('Rejette une vitesse hors plage', () {
    expect(() => PanelConfig.fromJson({'cible_cs':800,'marge_cs':0,'facile_rgb':0,'difficile_rgb':0,'traversee_ms':0}), throwsFormatException);
  });
}
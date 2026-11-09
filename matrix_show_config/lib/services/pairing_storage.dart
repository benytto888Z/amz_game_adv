/*
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage local des données d'association de chaque panneau.
///
/// Le contenu est opaque : son format et les vérifications cryptographiques
/// seront définis par le protocole d'association. Ce service ne réalise ni
/// l'association, ni l'authentification, ni le chiffrement du transport.
class PairingStorage {
  PairingStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _prefix = 'amz_pairing_v1_';

  String _key(String panelId) {
    // Identifiant canonique généré par le protocole, sans information secrète.
    if (!RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(panelId)) {
      throw ArgumentError.value(panelId, 'panelId', 'Identifiant invalide');
    }
    return '$_prefix$panelId';
  }

  /// Renvoie null si aucune association n'est enregistrée.
  /// Les erreurs du stockage sont propagées à l'appelant.
  Future<String?> read(String panelId) => _storage.read(key: _key(panelId));

  /// Enregistre une association opaque pour un seul panneau.
  Future<void> write(String panelId, String credentials) {
    if (credentials.isEmpty || credentials.length > 4096) {
      throw ArgumentError.value(
        credentials.length,
        'credentials.length',
        'Données d’association invalides',
      );
    }
    return _storage.write(key: _key(panelId), value: credentials);
  }

  /// Efface uniquement l'association locale du panneau indiqué.
  /// Cela ne révoque pas automatiquement l'accès côté panneau.
  Future<void> delete(String panelId) => _storage.delete(key: _key(panelId));
}
*/

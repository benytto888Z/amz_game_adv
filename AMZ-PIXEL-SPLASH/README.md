# AMZ PIXEL — Tesla Premium Splash Screen

Composant Flutter natif animé, sans GIF ni vidéo.

## Contenu
- `lib/amz_pixel_splash.dart` : widget du splash screen.
- `assets/images/amz_pixel_logo.png` : logo AMZ PIXEL original.
- `example_main.dart` : exemple d'intégration.
- `pubspec_asset_snippet.yaml` : déclaration de l'asset.

## 1. Copier les fichiers
Copiez `lib/amz_pixel_splash.dart` dans le dossier `lib/` de votre projet.
Copiez `assets/images/amz_pixel_logo.png` dans `assets/images/`.

## 2. Déclarer l'image dans pubspec.yaml
Sous la clé `flutter:` :

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/amz_pixel_logo.png
```

Puis lancez :
```bash
flutter pub get
```

## 3. Afficher le splash
Importez le widget :
```dart
import 'amz_pixel_splash.dart';
```

Exemple :
```dart
MaterialApp(
  debugShowCheckedModeBanner: false,
  home: AmzPixelSplashScreen(
    onFinished: () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    },
  ),
);
```

`HomePage` est votre écran d'accueil existant. Si votre application utilise
un routeur (go_router, auto_route...), remplacez la navigation de l'exemple
par la navigation correspondante.

## Paramètres
- `duration` : durée totale, 4600 ms par défaut.
- `logoAsset` : chemin de l'image du logo.
- `tagline` : slogan affiché sous le logo.
- `showCompanySignature` : afficher ou non la signature AMZ-IT.
- `onFinished` : callback obligatoire appelé à la fin.

## Notes de production
- Le splash Flutter est l'écran animé qui s'affiche après le splash natif
  du système. Pour éviter un flash blanc/noir au démarrage, configurez aussi
  un splash natif statique sombre avec `flutter_native_splash` si souhaité.
- Le code respecte le réglage système `disableAnimations` pour réduire les
  mouvements lorsque l'utilisateur le demande.
- Le widget ne se connecte pas à l'ESP32 : les opérations réseau et
  l'initialisation réelle de l'appareil doivent être gérées dans votre flux
  de démarrage applicatif.
- Vérifiez le rendu sur plusieurs tailles d'écran et sur appareils réels.

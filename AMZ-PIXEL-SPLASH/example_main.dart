import 'package:flutter/material.dart';
import 'amz_pixel_splash.dart';

void main() => runApp(const AmzPixelApp());

class AmzPixelApp extends StatelessWidget {
  const AmzPixelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: AmzPixelSplashScreen(
        duration: const Duration(milliseconds: 4600),
        onFinished: () {
          // Remplacez cette page par votre véritable écran principal.
          // Si vous utilisez un routeur, appelez ici votre navigation.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF080B11),
      body: Center(
        child: Text(
          'AMZ PIXEL — HOME',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

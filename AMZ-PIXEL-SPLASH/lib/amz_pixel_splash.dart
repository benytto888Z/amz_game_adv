import 'dart:math' as math;
import 'package:flutter/material.dart';

/// AMZ PIXEL — TESLA PREMIUM SPLASH
///
/// - Animation 100 % Flutter (aucune vidéo/GIF).
/// - Compatible Android / iOS.
/// - Utilise le logo original : assets/images/amz_pixel_logo.png.
/// - Appelle [onFinished] à la fin de la séquence.
///
/// Exemple :
/// AmzPixelSplashScreen(
///   onFinished: () => Navigator.pushReplacement(...),
/// )
class AmzPixelSplashScreen extends StatefulWidget {
  const AmzPixelSplashScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 4600),
    this.logoAsset = 'assets/images/amz_pixel_logo.png',
    this.tagline = 'LE FUTUR DE L’AFFICHAGE CONNECTÉ',
    this.showCompanySignature = true,
  });

  final VoidCallback onFinished;
  final Duration duration;
  final String logoAsset;
  final String tagline;
  final bool showCompanySignature;

  @override
  State<AmzPixelSplashScreen> createState() => _AmzPixelSplashScreenState();
}

class _AmzPixelSplashScreenState extends State<AmzPixelSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  late final AnimationController _loader = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  )..repeat();

  late final Animation<double> _logoOpacity = CurvedAnimation(
    parent: _timeline,
    curve: const Interval(0.10, 0.43, curve: Curves.easeOut),
  );

  late final Animation<double> _logoScale = Tween<double>(
    begin: .91,
    end: 1,
  ).animate(CurvedAnimation(
    parent: _timeline,
    curve: const Interval(0.08, 0.55, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _sloganOpacity = CurvedAnimation(
    parent: _timeline,
    curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
  );

  late final Animation<Offset> _sloganPosition = Tween<Offset>(
    begin: const Offset(0, .18),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _timeline,
    curve: const Interval(0.42, 0.72, curve: Curves.easeOutCubic),
  ));

  late final Animation<double> _loaderOpacity = CurvedAnimation(
    parent: _timeline,
    curve: const Interval(0.65, 0.86, curve: Curves.easeOut),
  );

  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timeline.forward();
    _timeline.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_completed) {
        _completed = true;
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timeline.dispose();
    _pulse.dispose();
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF07090D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _TeslaBackground(),
          // Vague lumineuse rouge très discrète, inspirée de l'univers Tesla.
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final t = reduceMotion ? .5 : _pulse.value;
              return Center(
                child: Container(
                  width: 260 + (t * 34),
                  height: 190 + (t * 25),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE82127)
                            .withOpacity(.045 + t * .035),
                        blurRadius: 90,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 650;
                final horizontalPadding =
                    constraints.maxWidth < 380 ? 24.0 : 34.0;

                return Column(
                  children: [
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: reduceMotion
                            ? const AlwaysStoppedAnimation(1)
                            : _logoScale,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: _LogoReveal(
                            asset: widget.logoAsset,
                            sweepAnimation: _timeline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 22 : 34),
                    SlideTransition(
                      position: _sloganPosition,
                      child: FadeTransition(
                        opacity: _sloganOpacity,
                        child: Column(
                          children: [
                            Text(
                              widget.tagline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFD7DBE2),
                                fontSize: compact ? 9 : 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: compact ? 1.5 : 2.0,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Container(
                              width: 42,
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE82127),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE82127)
                                        .withOpacity(.65),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(flex: 3),
                    FadeTransition(
                      opacity: _loaderOpacity,
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _loader,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _loader.value * math.pi * 2,
                                child: SizedBox(
                                  width: 27,
                                  height: 27,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.1,
                                    value: .76,
                                    backgroundColor:
                                        const Color(0xFF303640),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE82127),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 13),
                          const Text(
                            'INITIALISATION',
                            style: TextStyle(
                              color: Color(0xFF89919D),
                              fontSize: 8,
                              letterSpacing: 2.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    if (widget.showCompanySignature)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Text(
                          'AMZ INTERACTIVE TECHNOLOGY',
                          style: TextStyle(
                            color: const Color(0xFF68717F).withOpacity(.8),
                            fontSize: 8,
                            letterSpacing: 1.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiche le fichier de logo original avec un balayage rouge/blanc.
/// Le balayage ne modifie pas l'image et reste limité à sa zone.
class _LogoReveal extends StatelessWidget {
  const _LogoReveal({
    required this.asset,
    required this.sweepAnimation,
  });

  final String asset;
  final Animation<double> sweepAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: sweepAnimation,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(
          ((sweepAnimation.value - .28) / .36).clamp(0.0, 1.0),
        );
        return Stack(
          children: [
            Image.asset(
              asset,
              width: double.infinity,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stack) => const _LogoFallback(),
            ),
            if (t > 0 && t < 1)
              Positioned.fill(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment(-1 + 2 * t, 0),
                    widthFactor: .16,
                    child: Container(
                      width: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(.05),
                            const Color(0xFFFF5A60).withOpacity(.8),
                            Colors.white.withOpacity(.65),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE82127).withOpacity(.55),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.grid_view_rounded, color: Color(0xFFE82127), size: 42),
        SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'AMZ ',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'PIXEL',
                style: TextStyle(color: Color(0xFFE82127)),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'SMART LED CONTROL',
          style: TextStyle(
            color: Color(0xFFCAD0D8),
            fontSize: 10,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _TeslaBackground extends StatelessWidget {
  const _TeslaBackground();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _TeslaBackgroundPainter(),
      child: SizedBox.expand(),
    );
  }
}

class _TeslaBackgroundPainter extends CustomPainter {
  const _TeslaBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111925),
            Color(0xFF080B11),
            Color(0xFF05070B),
          ],
          stops: [0, .48, 1],
        ).createShader(bounds),
    );

    final topGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF26364D).withOpacity(.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * .5, size.height * .12),
        radius: size.width * .78,
      ));
    canvas.drawRect(bounds, topGlow);

    // Horizon rouge en bas de l'écran.
    final horizon = Path()
      ..moveTo(0, size.height * .84)
      ..cubicTo(
        size.width * .28,
        size.height * .79,
        size.width * .62,
        size.height * .91,
        size.width,
        size.height * .83,
      );

    canvas.drawPath(
      horizon,
      Paint()
        ..color = const Color(0xFFE82127).withOpacity(.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      horizon,
      Paint()
        ..color = const Color(0xFFE82127).withOpacity(.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Points lumineux très discrets, rappelant une matrice LED.
    final dotPaint = Paint()..color = const Color(0xFFE82127).withOpacity(.12);
    const spacing = 19.0;
    for (double y = size.height * .88; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final normalized = (y - size.height * .88) /
            (size.height * .12).clamp(1.0, double.infinity);
        final fade = (1 - normalized).clamp(0.0, 1.0);
        canvas.drawCircle(
          Offset(x + ((y ~/ spacing).isEven ? 0 : 5), y),
          1.05,
          dotPaint..color = const Color(0xFFE82127).withOpacity(.10 * fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

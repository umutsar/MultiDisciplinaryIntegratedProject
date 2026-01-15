import 'package:flutter/material.dart';

/// SplashScreen: açılışta ikon için Scale + Fade animasyonu gösterir
/// ve animasyon bitince ana ekrana yönlendirir.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _fade = Tween<double>(begin: 0, end: 1).animate(curve);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(curve);

    _controller.forward().whenComplete(() {
      if (!mounted) return;
      // Geri dönüş olmasın: replacement navigation
      Navigator.of(context).pushReplacementNamed('/root');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary.withValues(alpha: 0.16),
              scheme.secondary.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface.withValues(alpha: 0.65),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.28),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.camera_outdoor,
                  size: 54,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



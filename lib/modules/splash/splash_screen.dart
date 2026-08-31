import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/login.dart';
import '../Map/map_screen.dart';
import '../../services/api_service.dart';
import '../../widgets/app_bar.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class MooveSplashScreen extends StatefulWidget {
  final AppThemeProvider themeProvider;
  const MooveSplashScreen({super.key, required this.themeProvider});

  @override
  State<MooveSplashScreen> createState() => _MooveSplashScreenState();
}

class _MooveSplashScreenState extends State<MooveSplashScreen>
    with TickerProviderStateMixin {
  // Paleta
  static const _red = Color(0xFFB71C1C);
  static const _redDark = Color(0xFF8B0000);
  static const _redMid = Color(0xFFD32F2F);
  static const _white = Colors.white;

  // Controllers
  late final AnimationController _iconCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _subtitleCtrl;
  late final AnimationController _lineCtrl;
  late final AnimationController _dotsCtrl;
  late final AnimationController _exitCtrl;
  late final AnimationController _bgCtrl;

  // Animations
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _lineWidth;
  late final Animation<double> _exitFade;
  late final Animation<double> _bgScale;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _setupAnimations();
    _runSequence();
  }

  void _setupAnimations() {
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _bgScale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut));

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    _subtitleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _subtitleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _subtitleCtrl, curve: Curves.easeOut));

    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _lineWidth = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _lineCtrl, curve: Curves.easeOutCubic));

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
  }

  Future<void> _runSequence() async {
    FlutterNativeSplash.remove();
    _bgCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _iconCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _lineCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _textCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _subtitleCtrl.forward();

    Map<String, dynamic>? activeSession;
    try {
      activeSession = await ApiService.getSavedSession();
    } catch (_) {
      activeSession = null;
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    // Salida
    _dotsCtrl.stop();
    await _exitCtrl.forward();
    if (!mounted) return;

    // Decisión de Ruta basada en la sesión persistida
    if (activeSession != null && activeSession['success'] == true) {
      _navigateToMap(
        activeSession['usuario'] as Map<String, dynamic>,
        activeSession['roles'] as List<dynamic>? ?? [],
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(seconds: 3),
        pageBuilder: (_, _, _) =>
            LoginScreen(themeProvider: widget.themeProvider),
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  void _navigateToMap(Map<String, dynamic> usuario, List<dynamic> roles) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(seconds: 3),
        pageBuilder: (_, _, _) => MoviMap(
          themeProvider: widget.themeProvider,
          usuario: usuario,
          roles: roles,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _iconCtrl.dispose();
    _textCtrl.dispose();
    _subtitleCtrl.dispose();
    _lineCtrl.dispose();
    _dotsCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: FadeTransition(
        opacity: _exitFade,
        child: AnimatedBuilder(
          animation: _bgScale,
          builder: (_, child) =>
              Transform.scale(scale: _bgScale.value, child: child),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_redDark, _red, _redMid],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -size.width * 0.3,
                  right: -size.width * 0.2,
                  child: _DecorCircle(size: size.width * 0.8, opacity: 0.06),
                ),
                Positioned(
                  bottom: -size.width * 0.25,
                  left: -size.width * 0.15,
                  child: _DecorCircle(size: size.width * 0.7, opacity: 0.06),
                ),
                Positioned(
                  bottom: size.height * 0.15,
                  right: -size.width * 0.1,
                  child: _DecorCircle(size: size.width * 0.4, opacity: 0.04),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _iconScale,
                        child: FadeTransition(
                          opacity: _iconFade,
                          child: _BusIcon(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      AnimatedBuilder(
                        animation: _lineWidth,
                        builder: (_, _) => Container(
                          width: 120 * _lineWidth.value,
                          height: 1.5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SlideTransition(
                        position: _textSlide,
                        child: FadeTransition(
                          opacity: _textFade,
                          child: const Text(
                            'Moove',
                            style: TextStyle(
                              color: _white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: const Text(
                          'Transporte Estudiantil · UPTP',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _subtitleFade,
                    child: _LoadingDots(controller: _dotsCtrl),
                  ),
                ),
                Positioned(
                  bottom: 28,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _subtitleFade,
                    child: const Text(
                      'UPTP · Bienestar Estudiantil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BusIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
        ),
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
        ),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        const Icon(Icons.directions_bus_rounded, size: 52, color: Colors.white),
      ],
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (controller.value - i * 0.25) % 1.0;
            final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5).clamp(
              0.2,
              1.0,
            );
            final scale = (math.sin(phase * math.pi * 2) * 0.3 + 0.7).clamp(
              0.6,
              1.0,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: opacity),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1,
        ),
      ),
    );
  }
}

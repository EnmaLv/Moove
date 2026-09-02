import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
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
  late final AnimationController _lottieCtrl;
  late final AnimationController _exitCtrl;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _lottieCtrl = AnimationController(vsync: this);

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _exitFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _lottieCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSequence() async {
    final sessionFuture = ApiService.getSavedSession().catchError((_) => null);
    await _lottieCtrl.forward(from: 0.0);
    final activeSession = await sessionFuture;

    if (!mounted) return;
    await _exitCtrl.forward();

    if (!mounted) return;

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
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) =>
            LoginScreen(themeProvider: widget.themeProvider),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToMap(Map<String, dynamic> usuario, List<dynamic> roles) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) => MoviMap(
          themeProvider: widget.themeProvider,
          usuario: usuario,
          roles: roles,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C),
      body: FadeTransition(
        opacity: _exitFade,
        child: SizedBox.expand(
          child: Lottie.asset(
            'assets/animations/moove_splash.json',
            controller: _lottieCtrl,
            fit: BoxFit.cover,
            onLoaded: (composition) {
              _lottieCtrl.duration = composition.duration;
              FlutterNativeSplash.remove();
              _startSequence();
            },
          ),
        ),
      ),
    );
  }
}

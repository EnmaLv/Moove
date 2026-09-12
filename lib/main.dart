import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'modules/splash/splash_screen.dart';
import 'widgets/app_bar.dart';
import 'services/notificaciones_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      await NotificacionesService.inicializar();
      await SyncService.instance.initialize();
    }
  } catch (e) {
    debugPrint('Error durante la inicialización: $e');
  }

  final themeProvider = AppThemeProvider();
  await themeProvider.loadPrefs();

  runApp(BusApp(themeProvider: themeProvider));
}

class BusApp extends StatefulWidget {
  final AppThemeProvider themeProvider;
  const BusApp({super.key, required this.themeProvider});

  @override
  State<BusApp> createState() => _BusAppState();
}

class _BusAppState extends State<BusApp> {
  @override
  void initState() {
    super.initState();
    widget.themeProvider.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moove',
      themeMode: widget.themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: MooveSplashScreen(themeProvider: widget.themeProvider),
    );
  }
}
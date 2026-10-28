// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../Map/map_screen.dart';
import '../../widgets/app_bar.dart';

class LoginScreen extends StatefulWidget {
  final AppThemeProvider themeProvider;
  const LoginScreen({super.key, required this.themeProvider});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const colorRed = Color(0xFFB71C1C);

  // Ahora es "identificador" porque puede ser correo o cédula
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _error = 'Por favor completa todos los campos.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await ApiService.login(identifier, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MoviMap(
            themeProvider: widget.themeProvider,
            usuario: result['usuario'] as Map<String, dynamic>,
            roles: result['roles'] as List<dynamic>? ?? [],
          ),
        ),
      );
    } else {
      setState(() => _error = result['message'] ?? 'Credenciales inválidas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.themeProvider,
      builder: (context, _) {
        final isDark = widget.themeProvider.isDark;
        final colorBg =
            isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
        final colorCardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
        final colorText = isDark ? Colors.white : const Color(0xFF1A1A1A);
        final colorSubtext =
            isDark ? const Color(0xFF888888) : const Color(0xFF666666);

        final size = MediaQuery.of(context).size;
        final isWide = size.width > 768;

        return Scaffold(
          backgroundColor: colorBg,
          body: SafeArea(
            child: Stack(
              children: [
                isWide
                    ? _buildWideLayout(colorCardBg, colorText, colorSubtext, isDark)
                    : Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: _buildCard(colorText, colorSubtext, isDark),
                        ),
                      ),
                Positioned(
                  top: 16,
                  right: 20,
                  child: _LoginThemeToggle(
                    themeProvider: widget.themeProvider,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(
      Color cardBg, Color txtCol, Color subTxtCol, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: cardBg,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: _buildCard(txtCol, subTxtCol, isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Color txtCol, Color subTxtCol, bool isDark) {
    final errBg = isDark ? const Color(0xFF2C1A1A) : const Color(0xFFFFEBEE);
    final errBorderText =
        isDark ? const Color(0xFFEF5350) : const Color(0xFFC62828);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorRed,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: txtCol,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ingresa tus credenciales para continuar.',
                style: TextStyle(fontSize: 14, color: subTxtCol),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: errBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: errBorderText, width: 4),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: errBorderText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ---------- CAMBIO: correo o cédula ----------
              TextField(
                controller: _identifierCtrl,
                keyboardType: TextInputType.text, // acepta letras y números
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Correo o cédula',
                  hintText: 'Ej: usuario@uptp.edu.ve o V-12345678',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: colorRed, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                onSubmitted: (_) => _handleLogin(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: 'Introduce tu contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: subTxtCol,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: colorRed, width: 2),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: colorRed,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginThemeToggle extends StatelessWidget {
  final AppThemeProvider themeProvider;
  final bool isDark;
  static const _red = Color(0xFFB71C1C);

  const _LoginThemeToggle(
      {required this.themeProvider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        themeProvider.toggle();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? _red : const Color(0xFFE0E0E0),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 6,
              top: 5,
              child: Icon(Icons.nightlight_round,
                  size: 16, color: Colors.white),
            ),
            const Positioned(
              right: 6,
              top: 5,
              child: Icon(Icons.wb_sunny_rounded,
                  size: 16, color: Color(0xFF999999)),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              left: isDark ? 4 : 24,
              top: 3,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
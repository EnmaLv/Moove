import 'package:flutter/material.dart';
import '../../widgets/app_bar.dart';
import 'model/asistencia_pasajero_model.dart';
import 'service/asistencia_pasajero_service.dart';
import 'widgets/scanner_carnet_widget.dart';

const _asistenciaItems = [
  NavItem(
    label: 'Asistencia',
    icon: Icons.qr_code_scanner_outlined,
    activeIcon: Icons.qr_code_scanner,
  ),
];

class BusAsistenciaScreen extends StatefulWidget {
  final String? viajeIdActivo;
  final AppThemeProvider themeProvider;

  const BusAsistenciaScreen({
    super.key,
    required this.viajeIdActivo,
    required this.themeProvider,
  });

  @override
  State<BusAsistenciaScreen> createState() => _BusAsistenciaScreenState();
}

class _BusAsistenciaScreenState extends State<BusAsistenciaScreen> {
  static const _red = Color(0xFFB71C1C);

  int _currentIndex = 0;
  bool _procesando = false;
  final List<ResultadoAsistencia> _historial = [];
  final TextEditingController _cedulaManualCtrl = TextEditingController();

  @override
  void dispose() {
    _cedulaManualCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar(String cedula) async {
    if (_procesando || widget.viajeIdActivo == null) return;
    setState(() => _procesando = true);

    try {
      final resultado = await AsistenciaPasajeroService.registrarPorCedula(
        viajeId: widget.viajeIdActivo!,
        cedula: cedula,
      );
      if (!mounted) return;
      setState(() => _historial.insert(0, resultado));
    } catch (e) {
      if (!mounted) return;
      setState(() => _historial.insert(
        0,
        const ResultadoAsistencia(
          exito: false,
          mensaje: 'Error de conexión al registrar.',
        ),
      ));
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _registrarManual() {
    final cedula = _cedulaManualCtrl.text.trim();
    if (cedula.isEmpty) return;
    _cedulaManualCtrl.clear();
    _registrar(cedula);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.viajeIdActivo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Asistencia'),
          backgroundColor: _red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No tienes un viaje en curso. Inicia tu ruta desde el mapa para poder registrar asistencia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          items: _asistenciaItems,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          themeProvider: widget.themeProvider,
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Asistencia'),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: 1.3,
              child: ScannerCarnetWidget(
                activo: !_procesando,
                onDetectado: _registrar,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cedulaManualCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'O ingresa la cédula manualmente',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _registrarManual(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: _red),
                  onPressed: _procesando ? null : _registrarManual,
                  icon: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),
          ),
          if (_procesando) const LinearProgressIndicator(color: _red),
          const SizedBox(height: 8),
          Expanded(
            child: _historial.isEmpty
                ? const Center(
                    child: Text('Aún no hay registros en este viaje.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _historial.length,
                    itemBuilder: (_, i) {
                      final r = _historial[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: r.exito
                                  ? Colors.green
                                  : (r.yaRegistrado ? Colors.orange : Colors.red),
                              width: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              r.exito
                                  ? Icons.check_circle
                                  : (r.yaRegistrado ? Icons.info : Icons.error),
                              color: r.exito
                                  ? Colors.green
                                  : (r.yaRegistrado ? Colors.orange : Colors.red),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (r.nombre != null)
                                    Text(r.nombre!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(r.mensaje, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            if (r.pasajerosTotal != null)
                              Text('#${r.pasajerosTotal}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _asistenciaItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        themeProvider: widget.themeProvider,
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerCarnetWidget extends StatefulWidget {
  final void Function(String cedula) onDetectado;
  final bool activo;

  const ScannerCarnetWidget({
    super.key,
    required this.onDetectado,
    this.activo = true,
  });

  @override
  State<ScannerCarnetWidget> createState() => _ScannerCarnetWidgetState();
}

class _ScannerCarnetWidgetState extends State<ScannerCarnetWidget> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );
  DateTime? _ultimaDeteccion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _procesarDeteccion(BarcodeCapture captura) {
    if (!widget.activo) return;

    final ahora = DateTime.now();
    if (_ultimaDeteccion != null &&
        ahora.difference(_ultimaDeteccion!) < const Duration(seconds: 2)) {
      return;
    }

    final codigo = captura.barcodes.firstOrNull?.rawValue;
    if (codigo == null || codigo.trim().isEmpty) return;

    final soloNumeros = codigo.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloNumeros.isEmpty) return;

    _ultimaDeteccion = ahora;
    widget.onDetectado(soloNumeros);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MobileScanner(
        controller: _controller,
        onDetect: _procesarDeteccion,
      ),
    );
  }
}
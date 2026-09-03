import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'bus_marker_icon.dart';

class MiBusEstado {
  final LatLng? posicion;
  final double rumbo;
  final bool activo;
  final bool senalPerdida;
  final String placa;

  const MiBusEstado({
    this.posicion,
    this.rumbo = 0,
    this.activo = false,
    this.senalPerdida = false,
    this.placa = 'S/N',
  });

  MiBusEstado copyWith({
    LatLng? posicion,
    double? rumbo,
    bool? activo,
    bool? senalPerdida,
    String? placa,
  }) {
    return MiBusEstado(
      posicion: posicion ?? this.posicion,
      rumbo: rumbo ?? this.rumbo,
      activo: activo ?? this.activo,
      senalPerdida: senalPerdida ?? this.senalPerdida,
      placa: placa ?? this.placa,
    );
  }
}

/// Capa de marcador independiente para el bus del propio usuario.
/// Se redibuja SOLO cuando cambia [notifier], sin afectar ni reconstruir
/// la capa de paradas / otros buses de Firebase (que vive en otro MarkerLayer).
class MiBusMarkerLayer extends StatelessWidget {
  final ValueNotifier<MiBusEstado> notifier;
  final Color colorActivo;
  final Color colorInactivo;

  const MiBusMarkerLayer({
    super.key,
    required this.notifier,
    required this.colorActivo,
    required this.colorInactivo,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MiBusEstado>(
      valueListenable: notifier,
      builder: (context, estado, _) {
        if (estado.posicion == null) return const SizedBox.shrink();

        return MarkerLayer(
          markers: [
            Marker(
              point: estado.posicion!,
              width: 180,
              height: 140,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: estado.senalPerdida
                          ? Colors.grey.shade700
                          : (estado.activo
                                ? Colors.green.shade800
                                : colorInactivo),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      estado.senalPerdida
                          ? '${estado.placa} · Sin señal'
                          : estado.placa,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  BusMarkerIcon(
                    heading: estado.rumbo,
                    size: 120,
                    activo: estado.activo,
                    senalPerdida: estado.senalPerdida,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

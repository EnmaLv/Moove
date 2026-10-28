import 'package:latlong2/latlong.dart';

class BusEnMapa {
  final String id;
  final String placa;
  final String rutaNombre;
  final LatLng posicion;
  final bool enMovimiento;
  final int pasajeros;
  final String sede;
  final double heading;

  const BusEnMapa({
    required this.id,
    required this.placa,
    required this.rutaNombre,
    required this.posicion,
    required this.enMovimiento,
    required this.pasajeros,
    this.sede = 'UPTP',
    this.heading = 0,
  });

  factory BusEnMapa.fromFirestore(String key, Map<String, dynamic> json) {
    final lat = (json['latitud'] ?? json['lat'] ?? 0.0) as num;
    final lng = (json['longitud'] ?? json['lng'] ?? 0.0) as num;
    final heading = (json['heading'] ?? 0.0) as num;

    return BusEnMapa(
      id: key,
      placa: json['placa']?.toString() ?? json['unidad']?.toString() ?? 'S/N',
      rutaNombre: json['ruta_nombre']?.toString() ?? json['ruta']?.toString() ?? 'Sin Ruta',
      posicion: LatLng(lat.toDouble(), lng.toDouble()),
      enMovimiento: json['en_movimiento'] ?? json['enMovimiento'] ?? false,
      pasajeros: (json['pasajeros'] ?? 0) as int,
      sede: json['sede']?.toString() ?? 'Acarigua',
      heading: heading.toDouble(),
    );
  }

  factory BusEnMapa.fromJson(Map<String, dynamic> json) {
    final vehiculo = (json['vehiculo'] ?? json['vehiculo_transporte'] ?? {})
        as Map<String, dynamic>;
    final ruta = (json['bus_ruta'] ??
            json['ruta_transporte'] ??
            json['ruta'] ??
            {}) as Map<String, dynamic>;

    final rawLat = json['latitud'] ?? json['lat'] ?? json['lat_lgt'] ?? 0.0;
    final rawLng = json['longitud'] ?? json['lng'] ?? json['lng_lgt'] ?? 0.0;

    return BusEnMapa(
      id: (json['id'] ?? json['id_vjt'] ?? '').toString(),
      placa: (vehiculo['placa'] ?? vehiculo['placa_vtr'] ?? 'S/N').toString(),
      rutaNombre:
          (ruta['nombre'] ?? ruta['nombre_rtr'] ?? 'Ruta Genérica').toString(),
      posicion: LatLng(
        (rawLat as num).toDouble(),
        (rawLng as num).toDouble(),
      ),
      enMovimiento: (json['estado'] ??
              json['estado_viaje'] ??
              json['estado_viaje_vjt']) ==
          'en_curso',
      pasajeros: (json['pasajeros'] ??
              json['total_pasajeros'] ??
              json['total_pasajeros_vjt'] ??
              0) as int,
      sede: (vehiculo['sede'] ?? 'UPTP').toString(),
    );
  }
}
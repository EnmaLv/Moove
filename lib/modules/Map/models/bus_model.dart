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
    final vehiculo = json['vehiculo'] ?? {};
    final ruta = json['bus_ruta'] ?? json['ruta'] ?? {};
    final lat = (json['latitud'] ?? 0.0) as num;
    final lng = (json['longitud'] ?? 0.0) as num;

    return BusEnMapa(
      id: json['id']?.toString() ?? '',
      placa: vehiculo['placa']?.toString() ?? 'S/N',
      rutaNombre: ruta['nombre']?.toString() ?? 'Ruta Genérica',
      posicion: LatLng(lat.toDouble(), lng.toDouble()),
      enMovimiento: json['estado'] == 'en_curso',
      pasajeros: (json['pasajeros'] ?? 0) as int,
      sede: vehiculo['sede']?.toString() ?? 'UPTP',
    );
  }
}
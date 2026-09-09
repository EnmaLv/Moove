class BusViaje {
  final int id;
  final String? turno;
  final String estado;
  final String? fechaInicio;
  final String? vehiculoPlaca;
  final String? rutaNombre;
  final String? conductorNombre;

  const BusViaje({
    required this.id,
    this.turno,
    required this.estado,
    this.fechaInicio,
    this.vehiculoPlaca,
    this.rutaNombre,
    this.conductorNombre,
  });

  factory BusViaje.fromJson(Map<String, dynamic> j) => BusViaje(
    id: j['id'] as int,
    turno: j['turno'] as String?,
    estado: j['estado'] as String? ?? 'programado',
    fechaInicio: j['fecha_inicio'] as String?,
    vehiculoPlaca: j['vehiculo']?['placa'] as String?,
    rutaNombre: j['bus_ruta']?['nombre'] as String?,
    conductorNombre:
        (j['conductor']?['persona']?['nombre_persona'] as String?) ??
        (j['conductor']?['nombre'] as String?) ??
        (j['conductor']?['usuario']?['persona']?['nombre_persona']
            as String?) ??
        (j['conductor']?['usuario']?['nombre'] as String?),
  );

  bool get enCurso => estado == 'en_curso';
  bool get programado => estado == 'programado';
}

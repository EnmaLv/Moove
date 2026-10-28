class ResultadoAsistencia {
  final bool exito;
  final String mensaje;
  final String? nombre;
  final int? pasajerosTotal;
  final bool yaRegistrado;

  const ResultadoAsistencia({
    required this.exito,
    required this.mensaje,
    this.nombre,
    this.pasajerosTotal,
    this.yaRegistrado = false,
  });

  factory ResultadoAsistencia.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? {}) as Map<String, dynamic>;

    return ResultadoAsistencia(
      exito: json['success'] == true,
      mensaje: json['message']?.toString() ?? '',
      nombre: (data['nombre'] ??
              data['nombre_per'] ??
              data['nombres_per'] ??
              data['nombre_persona'])
          ?.toString(),
      pasajerosTotal: (data['pasajeros_total'] ??
              data['total_pasajeros'] ??
              data['total_pasajeros_vjt']) as int?,
      yaRegistrado: json['code'] == 'YA_REGISTRADO',
    );
  }
}
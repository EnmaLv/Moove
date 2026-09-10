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
    return ResultadoAsistencia(
      exito: json['success'] == true,
      mensaje: json['message']?.toString() ?? '',
      nombre: json['data']?['nombre']?.toString(),
      pasajerosTotal: json['data']?['pasajeros_total'] as int?,
      yaRegistrado: json['code'] == 'YA_REGISTRADO',
    );
  }
}
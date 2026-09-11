import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/api_service.dart';
import '../model/asistencia_pasajero_model.dart';
import '../../../services/sync_service.dart';

class AsistenciaPasajeroService {
  static Future<ResultadoAsistencia> registrarPorCedula({
    required String viajeId,
    required String cedula,
    int? busParadaId,
  }) async {
    final payload = {
      'metodo': 'manual',
      'cedula': cedula,
      if (busParadaId != null) 'bus_parada_id': busParadaId,
    };

    final response = await ApiService.post(
      '/viajes/$viajeId/pasajeros',
      payload,
    );

    if (response['statusCode'] == 0) {
      await SyncService.instance.enqueue(
        type: 'asistencia',
        endpoint: '/viajes/$viajeId/pasajeros',
        payload: payload,
      );

      return const ResultadoAsistencia(
        exito: true,
        mensaje: 'Asistencia guardada. Se sincronizará cuando vuelva la conexión.',
      );
    }

    final resultado = ResultadoAsistencia.fromJson(response);

    if (resultado.exito) {
      try {
        await FirebaseFirestore.instance
            .collection('buses_activos')
            .doc(viajeId)
            .update({'pasajeros': FieldValue.increment(1)});
      } catch (_) {}
    }

    return resultado;
  }

  static Future<bool> registrarPorProximidad({
    required String viajeId,
  }) async {
    final payload = {
      'metodo': 'proximidad',
    };

    final response = await ApiService.post(
      '/viajes/$viajeId/pasajeros',
      payload,
    );

    if (response['statusCode'] == 0) {
      await SyncService.instance.enqueue(
        type: 'asistencia',
        endpoint: '/viajes/$viajeId/pasajeros',
        payload: payload,
      );

      return true;
    }

    return response['success'] == true ||
        (response['statusCode'] == 409 && response['code'] == 'YA_REGISTRADO');
  }
}
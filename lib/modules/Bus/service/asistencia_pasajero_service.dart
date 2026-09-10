import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/api_service.dart';
import '../model/asistencia_pasajero_model.dart';

class AsistenciaPasajeroService {
  static Future<ResultadoAsistencia> registrarPorCedula({
    required String viajeId,
    required String cedula,
    int? busParadaId,
  }) async {
    final response = await ApiService.post('/viajes/$viajeId/pasajeros', {
      'metodo': 'manual',
      'cedula': cedula,
      if (busParadaId != null) 'bus_parada_id': busParadaId,
    });

    final resultado = ResultadoAsistencia.fromJson(response);

    if (resultado.exito) {
      try {
        await FirebaseFirestore.instance
            .collection('buses_activos')
            .doc(viajeId)
            .update({'pasajeros': FieldValue.increment(1)});
      } catch (e) {
        // No bloquea el flujo si Firestore falla; el registro real ya quedó en MySQL
      }
    }

    return resultado;
  }
}
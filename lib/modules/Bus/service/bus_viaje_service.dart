import '../../../services/api_service.dart';
import '../model/bus_viaje_model.dart';

class BusViajeService {
  static Future<List<BusViaje>> getViajesHoy() async {
    final res = await ApiService.get('/viajes/hoy');
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((j) => BusViaje.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res['message'] ?? 'Error al obtener los viajes.');
  }
}
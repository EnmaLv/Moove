import '../model/bus_vehicle_model.dart';
import '../model/bus_model.dart';
import '../model/bus_fuel_type_model.dart';
import '../../../services/api_service.dart';

class BusVehiculoService {
  static const _base = '/vehiculos';

  static Future<List<BusVehiculo>> getAll() async {
    final res = await ApiService.get(_base);
    if (res['success'] == true) {
      final rawData = res['data'];
      final List items = (rawData is Map && rawData.containsKey('data')) 
          ? rawData['data'] as List 
          : rawData as List;

      return items.map((j) => BusVehiculo.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar vehículos.');
  }

  static Future<List<BusModelo>> getModelos() async {
    final res = await ApiService.get('/modelos?estado=1');
    if (res['success'] == true) {
      return (res['data'] as List).map((j) => BusModelo.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al cargar catálogo de modelos.');
  }

  static Future<List<BusTipoCombustible>> getCombustibles() async {
    final res = await ApiService.get('/combustibles?estado=1');
    if (res['success'] == true) {
      return (res['data'] as List).map((j) => BusTipoCombustible.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al cargar catálogo de combustibles.');
  }

  static Future<List<Map<String, dynamic>>> getSedes() async {
    try {
      final res = await ApiService.get('/sedes');
      if (res['success'] == true) {
        return List<Map<String, dynamic>>.from(res['data'] as List);
      }
    } catch (_) {
      return [{'id': 1, 'nombre': 'Sede Central'}];
    }
    return [{'id': 1, 'nombre': 'Sede Central'}];
  }

  static Future<BusVehiculo> create(Map<String, dynamic> datos) async {
    final res = await ApiService.post(_base, datos);
    if (res['success'] == true) return BusVehiculo.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al registrar vehículo.');
  }

  static Future<BusVehiculo> update(int id, Map<String, dynamic> datos) async {
    final res = await ApiService.put('$_base/$id', datos);
    if (res['success'] == true) return BusVehiculo.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al actualizar vehículo.');
  }

  static Future<void> toggle(int id) async {
    final res = await ApiService.patch('$_base/$id/toggle', {});
    if (res['success'] != true) throw Exception(res['message'] ?? 'Error.');
  }

  static Future<void> delete(int id) async {
    final res = await ApiService.delete('$_base/$id');
    if (res['success'] != true) throw Exception(res['message'] ?? 'Error.');
  }
}
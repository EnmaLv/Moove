import '../model/bus_fuel_type_model.dart';
import '../../../services/api_service.dart';

class BusTipoCombustibleService {
  static const _base = '/combustibles';

  static Future<List<BusTipoCombustible>> getAll() async {
    final res = await ApiService.get(_base);
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((j) => BusTipoCombustible.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar combustibles.');
  }

  static Future<BusTipoCombustible> create(String nombre, String? descripcion) async {
    final res = await ApiService.post(_base, {
      'nombre': nombre,
      'descripcion': descripcion,
    });
    if (res['success'] == true) {
      return BusTipoCombustible.fromJson(Map<String, dynamic>.from(res['data'] as Map));
    }
    throw Exception(res['message'] ?? 'Error al crear tipo de combustible.');
  }

  static Future<BusTipoCombustible> update(int id, String nombre, String? descripcion) async {
    final res = await ApiService.put('$_base/$id', {
      'nombre': nombre,
      'descripcion': descripcion,
    });
    if (res['success'] == true) {
      return BusTipoCombustible.fromJson(Map<String, dynamic>.from(res['data'] as Map));
    }
    throw Exception(res['message'] ?? 'Error al actualizar tipo de combustible.');
  }

  static Future<void> toggle(int id) async {
    final res = await ApiService.patch('$_base/$id/toggle', {});
    if (res['success'] != true) throw Exception(res['message'] ?? 'Error.');
  }

  static Future<void> delete(int id) async {
    final res = await ApiService.delete('$_base/$id');
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Error al eliminar tipo de combustible.');
    }
  }
}
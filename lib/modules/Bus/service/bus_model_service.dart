import '../model/bus_brand_model.dart';
import '../model/bus_model.dart';
import '../../../services/api_service.dart';

class BusModeloService {
  static const _base = '/modelos';
  static const _marcas = '/marcas';

  static Future<List<BusModelo>> getAll() async {
    final res = await ApiService.get(_base);
    if (res['success'] == true && res['data'] != null) {
      // Forzamos a que sea una List<dynamic> explícita para que Dart Web no se pierda
      final List<dynamic> data = res['data'] as List<dynamic>;
      return data.map((j) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(j as Map);
        return BusModelo.fromJson(json);
      }).toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar modelos.');
  }

  static Future<List<BusMarca>> getMarcas() async {
    final res = await ApiService.get('$_marcas?estado=1');
    if (res['success'] == true && res['data'] != null) {
      final List<dynamic> data = res['data'] as List<dynamic>;
      return data.map((j) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(j as Map);
        return BusMarca.fromJson(json);
      }).toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar marcas.');
  }

  static Future<BusModelo> create(int marcaId, String nombre) async {
    final res = await ApiService.post(_base, {
      'marca_id': marcaId,
      'nombre': nombre,
    });
    if (res['success'] == true) {
      return BusModelo.fromJson(Map<String, dynamic>.from(res['data'] as Map));
    }
    throw Exception(res['message'] ?? 'Error al crear modelo.');
  }

  static Future<BusModelo> update(int id, int marcaId, String nombre) async {
    final res = await ApiService.put('$_base/$id', {
      'marca_id': marcaId,
      'nombre': nombre,
    });
    if (res['success'] == true) {
      return BusModelo.fromJson(Map<String, dynamic>.from(res['data'] as Map));
    }
    throw Exception(res['message'] ?? 'Error al actualizar modelo.');
  }

  static Future<void> toggle(int id) async {
    final res = await ApiService.patch('$_base/$id/toggle', {});
    if (res['success'] != true) throw Exception(res['message'] ?? 'Error.');
  }

  static Future<void> delete(int id) async {
    final res = await ApiService.delete('$_base/$id');
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Error al eliminar modelo.');
    }
  }
}
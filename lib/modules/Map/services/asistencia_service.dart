import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bus_model.dart';

class BusCercano {
  final String viajeId;
  final BusEnMapa bus;
  final double distanciaMetros;

  const BusCercano({
    required this.viajeId,
    required this.bus,
    required this.distanciaMetros,
  });
}

class AsistenciaService {
  static const double radioMetros = 15.0;
  static const Duration cooldown = Duration(minutes: 10);
  static const _prefsPrefix = 'asistencia_ultimo_';

  List<BusCercano> detectarBusesCercanos(
    LatLng miPosicion,
    Map<String, BusEnMapa> busesActivos,
  ) {
    final resultado = <BusCercano>[];

    busesActivos.forEach((viajeId, bus) {
      final distancia = Geolocator.distanceBetween(
        miPosicion.latitude,
        miPosicion.longitude,
        bus.posicion.latitude,
        bus.posicion.longitude,
      );

      if (distancia <= radioMetros) {
        resultado.add(
          BusCercano(viajeId: viajeId, bus: bus, distanciaMetros: distancia),
        );
      }
    });

    resultado.sort((a, b) => a.distanciaMetros.compareTo(b.distanciaMetros));
    return resultado;
  }

  Future<bool> puedeRegistrar(String viajeId) async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaMs = prefs.getInt('$_prefsPrefix$viajeId');
    if (ultimaMs == null) return true;
    final ultima = DateTime.fromMillisecondsSinceEpoch(ultimaMs);
    return DateTime.now().difference(ultima) > cooldown;
  }

  Future<void> marcarRegistrado(String viajeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_prefsPrefix$viajeId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
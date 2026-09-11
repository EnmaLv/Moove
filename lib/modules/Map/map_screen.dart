import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:moove/services/sync_service.dart';

import '../../modules/Map/models/bus_model.dart';
import '../../services/api_service.dart';
import '../Bus/bus_catalogo_screen.dart';
import '../Bus/bus_viaje_screen.dart';
import '../Bus/service/asistencia_pasajero_service.dart';
import '../auth/login.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/top_overlay.dart';
import '../../widgets/start_route_button.dart';
import 'services/osrm_streets.dart';
import 'services/tracking_service.dart';
import 'services/heading_helper.dart';
import 'widgets/bus_marker_icon.dart';
import 'widgets/mi_bus_marker_layer.dart';
import 'services/asistencia_service.dart';
import '../../services/notificaciones_service.dart';
import '../Bus/bus_asistencia_screen.dart';

class MoviMap extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final List<dynamic> roles;
  final AppThemeProvider themeProvider;

  const MoviMap({
    super.key,
    required this.usuario,
    required this.roles,
    required this.themeProvider,
  });

  @override
  State<MoviMap> createState() => _MoviMapState();
}

class _MoviMapState extends State<MoviMap> with WidgetsBindingObserver {
  static const _red = Color(0xFFB71C1C);
  num _kmInicio = 0;
  bool _dialogoFinalizarAbierto = false;

  final AsistenciaService _asistenciaService = AsistenciaService();
  StreamSubscription<Position>? _asistenciaPositionStream;
  bool _dialogoAsistenciaAbierto = false;

  int _currentIndex = 0;
  final MapController _mapController = MapController();
  final TrackingService _trackingService = TrackingService();

  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  Map<String, BusEnMapa> _busesActivosFirebase = {};

  bool _mapaListo = false;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  bool _trackingActivo = false;
  bool _cargandoRuta = false;
  String? _viajeIdActivo;
  LatLng? _miUbicacion;
  static const double _velocidadMinimaParaRotar = 0.6;
  final ValueNotifier<MiBusEstado> _miBusNotifier = ValueNotifier(
    const MiBusEstado(),
  );
  Timer? _watchdogSenal;
  static const _timeoutSenal = Duration(seconds: 20);

  LatLng _centroInicial = const LatLng(9.546987, -69.192543);

  List<Map<String, dynamic>> _paradasRuta = [];
  LatLng? _destinoFinalReal;

  int _indicePuntoActual = 0;
  List<LatLng> _rutaCalles = [];

  List<Map<String, dynamic>> _todasParadas = [];
  LatLng? _miUbicacionActual;

  static const _radioLlegada = 50.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inicializarPantalla();
    _escucharBusesEnTiempoRealFirestore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _firestoreSubscription?.cancel();
    _trackingService.detenerTracking(_viajeIdActivo);
    _watchdogSenal?.cancel();
    _miBusNotifier.dispose();
    _mapController.dispose();
    _asistenciaPositionStream?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      if (_trackingActivo && _viajeIdActivo != null) {
        _trackingService.detenerTracking(_viajeIdActivo);
      }
    }
  }

  void _escucharBusesEnTiempoRealFirestore() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('buses_activos')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;

          final Map<String, BusEnMapa> busesCargados = {};
          final ahora = DateTime.now();

          for (var doc in snapshot.docs) {
            final data = doc.data();

            final Timestamp? ultimaAct =
                data['ultima_actualizacion'] as Timestamp?;
            if (ultimaAct == null) continue;
            final diferencia = ahora.difference(ultimaAct.toDate()).inMinutes;
            if (diferencia > 3) continue;

            busesCargados[doc.id] = BusEnMapa.fromFirestore(doc.id, data);
          }

          setState(() {
            _busesActivosFirebase = busesCargados;
          });
          _actualizarElementosVisualesDelMapa();
        });
  }

  Future<void> _inicializarPantalla() async {
    await _obtenerUbicacionInicialUsuario();
    await _cargarTodasLasParadas();

    if (mounted) {
      setState(() {
        _mapaListo = true;
      });
      await _verificarYRestaurarViajeActivo();
      _iniciarMonitoreoAsistencia();
    }
  }

  Future<void> _cargarTodasLasParadas() async {
    try {
      final response = await ApiService.get('/paradas');
      final data = response['data'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _todasParadas = data.cast<Map<String, dynamic>>();
      });
      _actualizarElementosVisualesDelMapa();
    } catch (e) {
      debugPrint('Error cargando paradas: $e');
    }
  }

  Future<void> _verificarYRestaurarViajeActivo() async {
    try {
      final responseActive = await ApiService.get('/mi-viaje-activo');
      if (responseActive['data'] != null) {
        final viajeData = responseActive['data'];
        final String estadoActual = viajeData['estado'] ?? '';

        if (estadoActual == 'en_curso') {
          debugPrint("Viaje 'en_curso' detectado. Restaurando ruta...");
          await _procesarEIniciarRuta(viajeData, esRestauracion: true);
        }
      }
    } catch (e) {
      debugPrint("Error al verificar viaje activo: $e");
    }
  }

  void _iniciarMonitoreoAsistencia() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _asistenciaPositionStream?.cancel();
    _asistenciaPositionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_chequearProximidadBus);
  }

  void _chequearProximidadBus(Position pos) async {
    if (!mounted) return;

    final miPos = LatLng(pos.latitude, pos.longitude);
    if (!_trackingActivo) {
      setState(() => _miUbicacionActual = miPos);
    }

    if (_dialogoAsistenciaAbierto) return;

    final cercanos = _asistenciaService
        .detectarBusesCercanos(miPos, _busesActivosFirebase)
        .where((c) => c.viajeId != _viajeIdActivo)
        .toList();

    final candidatos = <BusCercano>[];
    for (final c in cercanos) {
      if (await _asistenciaService.puedeRegistrar(c.viajeId)) {
        candidatos.add(c);
      }
    }

    if (!mounted || candidatos.isEmpty) return;

    if (candidatos.length == 1) {
      _registrarAsistencia(candidatos.first);
    } else {
      _mostrarSelectorBusCercano(candidatos);
    }
  }

  Future<void> _registrarAsistencia(BusCercano candidato) async {
    await _asistenciaService.marcarRegistrado(candidato.viajeId);

    try {
      final registrada = await AsistenciaPasajeroService.registrarPorProximidad(
        viajeId: candidato.viajeId,
      );

      if (!mounted) return;

      if (registrada) {
        await NotificacionesService.mostrarLocal(
          titulo: 'Asistencia registrada',
          cuerpo: 'Subiste al bus ${candidato.bus.placa}',
        );
        await _incrementarPasajerosFirestore(candidato.viajeId);
      }
    } catch (e) {
      debugPrint('Error registrando asistencia: $e');
    }
  }

  Future<void> _incrementarPasajerosFirestore(String viajeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('buses_activos')
          .doc(viajeId)
          .update({'pasajeros': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('Error incrementando pasajeros en Firestore: $e');
    }
  }

  Future<void> _mostrarSelectorBusCercano(List<BusCercano> candidatos) async {
    _dialogoAsistenciaAbierto = true;

    final seleccionado = await showDialog<BusCercano>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('¿A cuál bus subiste?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: candidatos
              .map(
                (c) => ListTile(
                  title: Text(c.bus.placa),
                  subtitle: Text('${c.distanciaMetros.toStringAsFixed(0)} m'),
                  onTap: () => Navigator.pop(ctx, c),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Ninguno'),
          ),
        ],
      ),
    );

    _dialogoAsistenciaAbierto = false;

    if (seleccionado != null) {
      _registrarAsistencia(seleccionado);
    } else {
      for (final c in candidatos) {
        await _asistenciaService.marcarRegistrado(c.viajeId);
      }
    }
  }

  Future<LatLng?> _obtenerPosicionGPS() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          return LatLng(lastPosition.latitude, lastPosition.longitude);
        }
      } catch (_) {}
      if (_miUbicacion != null) return _miUbicacion;
      return null;
    }
  }

  Future<void> _obtenerUbicacionInicialUsuario() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final posLatLng = await _obtenerPosicionGPS();

      if (posLatLng != null && mounted) {
        setState(() {
          _miUbicacion = posLatLng;
          _centroInicial = posLatLng;
        });
        _actualizarMiBusEstado(posicion: posLatLng, activo: false);
        _mapController.move(posLatLng, 15.0);
      }
    } catch (e) {
      debugPrint("No se pudo obtener la ubicación GPS inicial: $e");
    }
  }

  void _mostrarInfoParada(int numero, String nombre) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$numero',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Parada $numero: $nombre',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarInfoParadaGenerica(String nombre) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _actualizarElementosVisualesDelMapa() {
    if (!mounted) return;
    final nuevosMarkers = <Marker>[];

    for (int i = 0; i < _paradasRuta.length; i++) {
      final parada = _paradasRuta[i];
      final lat = double.tryParse(
        parada['lat']?.toString() ?? parada['latitud']?.toString() ?? '',
      );
      final lng = double.tryParse(
        parada['lng']?.toString() ?? parada['longitud']?.toString() ?? '',
      );

      if (lat != null && lng != null) {
        final nombreParada = parada['nombre'] ?? 'Parada ${i + 1}';

        nuevosMarkers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 32,
            height: 32,
            child: GestureDetector(
              onTap: () => _mostrarInfoParada(i + 1, nombreParada),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    for (final parada in _todasParadas) {
      final lat = double.tryParse(parada['lat']?.toString() ?? '');
      final lng = double.tryParse(parada['lng']?.toString() ?? '');
      if (lat == null || lng == null) continue;

      final yaEstaEnRutaActiva = _paradasRuta.any((p) {
        final pLat = double.tryParse(
          p['lat']?.toString() ?? p['latitud']?.toString() ?? '',
        );
        final pLng = double.tryParse(
          p['lng']?.toString() ?? p['longitud']?.toString() ?? '',
        );
        return pLat == lat && pLng == lng;
      });
      if (yaEstaEnRutaActiva) continue;

      final nombreParada = parada['nombre']?.toString() ?? 'Parada';

      nuevosMarkers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 26,
          height: 26,
          child: GestureDetector(
            onTap: () => _mostrarInfoParadaGenerica(nombreParada),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      );
    }

    _busesActivosFirebase.forEach((id, bus) {
      if (id == _viajeIdActivo) return;

      nuevosMarkers.add(
        Marker(
          point: bus.posicion,
          width: 70,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bus.placa,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              BusMarkerIcon(
                heading: bus.heading,
                size: 32,
                activo: bus.enMovimiento,
              ),
            ],
          ),
        ),
      );
    });

    final nuevasPolylines = <Polyline>[];
    if (_trackingActivo && _rutaCalles.isNotEmpty) {
      final total = _rutaCalles.length;

      nuevasPolylines.add(
        Polyline(
          points: _rutaCalles,
          strokeWidth: 5.0,
          color: _red.withValues(alpha: 0.35),
        ),
      );

      if (_indicePuntoActual > 0) {
        nuevasPolylines.add(
          Polyline(
            points: _rutaCalles.sublist(0, _indicePuntoActual.clamp(1, total)),
            strokeWidth: 5.0,
            color: _red,
          ),
        );
      }
    }

    setState(() {
      _markers = nuevosMarkers;
      _polylines = nuevasPolylines;
    });
  }

  void _actualizarMiBusEstado({
    LatLng? posicion,
    double? rumbo,
    bool? activo,
    bool? senalPerdida,
    String? placa,
  }) {
    _miBusNotifier.value = _miBusNotifier.value.copyWith(
      posicion: posicion,
      rumbo: rumbo,
      activo: activo,
      senalPerdida: senalPerdida,
      placa: placa,
    );
  }

  void _iniciarWatchdogSenal() {
    _watchdogSenal?.cancel();
    _watchdogSenal = Timer.periodic(const Duration(seconds: 5), (_) {
      final ultima = _trackingService.ultimaActualizacion;
      if (ultima == null) return;
      final sinSenal = DateTime.now().difference(ultima) > _timeoutSenal;
      if (sinSenal != _miBusNotifier.value.senalPerdida) {
        _actualizarMiBusEstado(senalPerdida: sinSenal);
      }
    });
  }

  Future<void> _iniciarRuta() async {
    final ok = await _trackingService.solicitarPermisos();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos de ubicación requeridos')),
      );
      return;
    }

    setState(() => _cargandoRuta = true);

    try {
      final responseActive = await ApiService.get('/mi-viaje-activo');

      Map<String, dynamic>? viajeData;
      if (responseActive['data'] != null) {
        viajeData = responseActive['data'];
      }

      if (viajeData == null) {
        if (!mounted) return;
        setState(() => _cargandoRuta = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No tienes ningún viaje asignado o programado.'),
          ),
        );
        return;
      }

      await _procesarEIniciarRuta(viajeData, esRestauracion: false);
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoRuta = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al iniciar viaje: $e')));
      }
    }
  }

  Future<void> _procesarEIniciarRuta(
    Map<String, dynamic> viajeData, {
    required bool esRestauracion,
  }) async {
    final String viajeId = viajeData['id'].toString();
    final String placa = viajeData['vehiculo']?['placa'] ?? 'S/N';
    final String rutaNombre = viajeData['bus_ruta']?['nombre'] ?? 'Sin Ruta';
    final String estadoActual = viajeData['estado'] ?? 'programado';

    final List<dynamic> paradasRaw = viajeData['bus_ruta']?['paradas'] ?? [];
    final List<Map<String, dynamic>> paradasCargadas = [];
    final dynamic kmInicioRaw =
        viajeData['km_inicio'] ?? viajeData['vehiculo']?['km_actual'] ?? 0;
    _kmInicio = num.tryParse(kmInicioRaw.toString()) ?? 0;

    for (var p in paradasRaw) {
      if (p is Map<String, dynamic>) {
        paradasCargadas.add(p);
      }
    }
    if (estadoActual == 'programado' && !esRestauracion) {
      await ApiService.post('/viajes/$viajeId/iniciar', {});
    }

    final origen = await _obtenerPosicionGPS();
    if (!mounted) return;

    if (origen == null) {
      setState(() => _cargandoRuta = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo determinar tu posición GPS actual.'),
        ),
      );
      return;
    }

    final List<LatLng> secuenciaRuta = [origen];
    for (var p in paradasCargadas) {
      final lat = double.tryParse(
        p['lat']?.toString() ?? p['latitud']?.toString() ?? '',
      );
      final lng = double.tryParse(
        p['lng']?.toString() ?? p['longitud']?.toString() ?? '',
      );
      if (lat != null && lng != null) {
        secuenciaRuta.add(LatLng(lat, lng));
      }
    }

    LatLng destinoFinal = origen;
    if (secuenciaRuta.length > 1) {
      destinoFinal = secuenciaRuta.last;
    }

    final puntos = await obtenerRutaCalles(secuenciaRuta);
    if (!mounted) return;

    _viajeIdActivo = viajeId;
    _paradasRuta = paradasCargadas;
    _destinoFinalReal = destinoFinal;
    _rutaCalles = puntos;
    _trackingActivo = true;
    _miUbicacion = origen;
    _indicePuntoActual = 0;
    _cargandoRuta = false;
    _miUbicacionActual = null;

    _actualizarMiBusEstado(
      posicion: origen,
      activo: true,
      senalPerdida: false,
      placa: placa,
    );
    _iniciarWatchdogSenal();

    _actualizarElementosVisualesDelMapa();

    if (puntos.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(puntos);
      if (bounds.northEast != bounds.southWest) {
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60.0)),
        );
      } else {
        _mapController.move(puntos.first, 16.0);
      }
    }

    _trackingService.iniciarTracking(
      viajeId: viajeId,
      placa: placa,
      rutaNombre: rutaNombre,
      sede: 'UPTP',
      onCanceladoExternamente: () {
        if (!mounted || !_trackingActivo) return;
        _cancelarRuta();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El viaje fue finalizado o cancelado desde la central.',
            ),
            backgroundColor: _red,
          ),
        );
      },
      onPositionChanged: (pos) {
        if (!mounted) return;
        final nuevaPos = LatLng(pos.latitude, pos.longitude);

        double? nuevoRumbo;
        if (pos.headingAccuracy >= 0 && pos.headingAccuracy <= 60) {
          nuevoRumbo = pos.heading;
        } else if (pos.speed >= _velocidadMinimaParaRotar &&
            _miUbicacion != null) {
          nuevoRumbo = calcularBearing(_miUbicacion!, nuevaPos);
        }

        _miUbicacion = nuevaPos;
        _indicePuntoActual = _puntoMasCercano(nuevaPos);

        _actualizarMiBusEstado(
          posicion: nuevaPos,
          rumbo: nuevoRumbo,
          senalPerdida: false,
        );

        _actualizarElementosVisualesDelMapa();
        _mapController.move(nuevaPos, _mapController.camera.zoom);

        if (_destinoFinalReal != null && !_dialogoFinalizarAbierto) {
          final cercaDelFinalDelRecorrido =
              _rutaCalles.isEmpty ||
              _indicePuntoActual >= _rutaCalles.length - 5;

          final distancia = Geolocator.distanceBetween(
            nuevaPos.latitude,
            nuevaPos.longitude,
            _destinoFinalReal!.latitude,
            _destinoFinalReal!.longitude,
          );

          if (cercaDelFinalDelRecorrido && distancia <= _radioLlegada) {
            _finalizarRutaAutomatico();
          }
        }
      },
    );

    if (esRestauracion && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta restaurada automáticamente.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  double _calcularDistanciaTotalKm() {
    double totalMetros = 0;
    for (int i = 0; i < _rutaCalles.length - 1; i++) {
      totalMetros += Geolocator.distanceBetween(
        _rutaCalles[i].latitude,
        _rutaCalles[i].longitude,
        _rutaCalles[i + 1].latitude,
        _rutaCalles[i + 1].longitude,
      );
    }
    return totalMetros / 1000;
  }

  Future<void> _finalizarRutaAutomatico() async {
    if (_viajeIdActivo == null || _dialogoFinalizarAbierto) return;

    _dialogoFinalizarAbierto = true;

    final viajeId = _viajeIdActivo!;
    final distanciaKm = _calcularDistanciaTotalKm();
    final kmFin = _kmInicio + distanciaKm;

    try {
      await SyncService.instance.enqueue(
        type: 'finalizar_viaje',
        endpoint: '/viajes/$viajeId/finalizar',
        payload: {'km_fin': kmFin, 'litros_gastados': 0, 'hubo_desvio': false},
      );

      await _trackingService.detenerTracking(viajeId);
      _llegarAlDestino();

      await SyncService.instance.flush();
    } catch (e) {
      debugPrint('Error guardando finalización local: $e');
    } finally {
      _dialogoFinalizarAbierto = false;
    }
  }

  void _llegarAlDestino() {
    if (!mounted) return;
    _trackingActivo = false;
    _rutaCalles = [];
    _paradasRuta = [];
    _indicePuntoActual = 0;
    _viajeIdActivo = null;
    _watchdogSenal?.cancel();
    _actualizarMiBusEstado(activo: false, senalPerdida: false);

    _actualizarElementosVisualesDelMapa();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('¡Ruta completada e informada al sistema!'),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _cancelarRuta() {
    _trackingService.detenerTracking(_viajeIdActivo);
    _trackingActivo = false;
    _indicePuntoActual = 0;
    _rutaCalles = [];
    _paradasRuta = [];
    _viajeIdActivo = null;
    _watchdogSenal?.cancel();
    _actualizarMiBusEstado(activo: false, senalPerdida: false);
    _actualizarElementosVisualesDelMapa();
  }

  void _mostrarDialogoCancelar() {
    if (_viajeIdActivo == null) return;

    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool cargando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFF3F4F6),
                ),
              ),
              titlePadding: const EdgeInsets.all(16),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              actionsPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF991B1B).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.block,
                      color: Color(0xFF991B1B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Cancelar Viaje',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Por favor, especifique el motivo por el cual se cancela este viaje. Esta información quedará registrada en el sistema.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'MOTIVO DE LA CANCELACIÓN *',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: controller,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 5) {
                          return 'Debe ingresar al menos 5 caracteres.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Escriba aquí la razón detallada...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF111827)
                            : const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF991B1B),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        onPressed: cargando
                            ? null
                            : () => Navigator.pop(dialogContext),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF991B1B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: cargando
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;

                                final scaffoldMessenger =
                                    ScaffoldMessenger.maybeOf(context);
                                final dialogNavigator = Navigator.of(
                                  dialogContext,
                                );

                                setModalState(() => cargando = true);

                                final response = await ApiService.post(
                                  '/viajes/$_viajeIdActivo/cancelar',
                                  {
                                    'motivo_cancelacion': controller.text
                                        .trim(),
                                  },
                                );

                                setModalState(() => cargando = false);

                                if (!mounted) return;

                                if (dialogNavigator.canPop()) {
                                  dialogNavigator.pop();
                                }

                                if (response['success'] == true) {
                                  _cancelarRuta();
                                  scaffoldMessenger?.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'El viaje ha sido cancelado exitosamente.',
                                      ),
                                      backgroundColor: Color(0xFF991B1B),
                                    ),
                                  );
                                } else {
                                  scaffoldMessenger?.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response['message'] ??
                                            'No se pudo cancelar el viaje.',
                                      ),
                                      backgroundColor: Colors.black87,
                                    ),
                                  );
                                }
                              },
                        child: cargando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Confirmar',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _cerrarSesionSegura() async {
    if (_trackingActivo && _viajeIdActivo != null) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ruta en Curso'),
          content: const Text(
            'Tienes un viaje activo. Si cierras sesión, la transmisión GPS se detendrá. ¿Deseas salir?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmar != true) return;
      await _trackingService.detenerTracking(_viajeIdActivo);
    }

    await ApiService.logout();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(themeProvider: widget.themeProvider),
        ),
      );
    }
  }

  int _puntoMasCercano(LatLng pos) {
    if (_rutaCalles.isEmpty) return 0;
    const ventanaBusqueda = 40;
    final limite = (_indicePuntoActual + ventanaBusqueda).clamp(
      0,
      _rutaCalles.length - 1,
    );

    int mejor = _indicePuntoActual;
    double menorDist = double.infinity;
    for (int i = _indicePuntoActual; i <= limite; i++) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _rutaCalles[i].latitude,
        _rutaCalles[i].longitude,
      );
      if (d < menorDist) {
        menorDist = d;
        mejor = i;
      }
    }
    return mejor;
  }

  bool get _esGestion => widget.roles.any((r) {
    final slug = (r['slug'] ?? '').toString().toLowerCase();
    return slug == 'jefe-transporte' || slug == 'administrador';
  });

  bool get _esOperativo => widget.roles.any((r) {
    final slug = (r['slug'] ?? '').toString().toLowerCase();
    return slug == 'conductor' ||
        slug == 'jefe-transporte' ||
        slug == 'administrador';
  });

  bool get _puedeIniciarRuta => _esOperativo;

  String? get _rolNombre =>
      widget.roles.isEmpty ? null : widget.roles.first['nombre'] as String?;

  List<NavItem> get _navItems {
    final items = [
      const NavItem(
        label: 'Mapa',
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
      ),
    ];
    if (_esGestion) {
      items.add(
        const NavItem(
          label: 'Catalogo',
          icon: Icons.directions_bus_outlined,
          activeIcon: Icons.directions_bus,
        ),
      );
    }
    items.add(
      const NavItem(
        label: 'Viajes',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
      ),
    );
    if (_esOperativo) {
      items.add(
        const NavItem(
          label: 'Asistencia',
          icon: Icons.qr_code_scanner_outlined,
          activeIcon: Icons.qr_code_scanner,
        ),
      );
    }
    return items;
  }

  void _onNavTap(int index) {
    final item = _navItems[index];

    if (item.label == 'Mapa') {
      setState(() => _currentIndex = index);
      return;
    }

    if (item.label == 'Catalogo') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BusCatalogoScreen(themeProvider: widget.themeProvider),
        ),
      );
      return;
    }

    if (item.label == 'Viajes') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusViajeScreen(themeProvider: widget.themeProvider),
        ),
      );
      return;
    }

    if (item.label == 'Asistencia') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusAsistenciaScreen(viajeIdActivo: _viajeIdActivo),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.label}: próximamente'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _red,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPage(int index) {
    if (index == 0) return _buildMapPage();
    return Center(
      child: Text(_navItems[index].label, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget _buildMapPage() {
    if (!_mapaListo) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _red),
            SizedBox(height: 14),
            Text(
              'Inicializando sistema de mapas...',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _centroInicial, initialZoom: 15.0),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.uptp.moove',
              evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
            ),
            if (_polylines.isNotEmpty) PolylineLayer(polylines: _polylines),
            MarkerLayer(markers: _markers),
            MiBusMarkerLayer(
              notifier: _miBusNotifier,
              colorActivo: Colors.green.shade800,
              colorInactivo: _red,
            ),

            if (_miUbicacionActual != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _miUbicacionActual!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (_cargandoRuta)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Conectando viaje y calculando ruta...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!_cargandoRuta)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _trackingActivo
                ? CancelarRutaButton(onTap: _mostrarDialogoCancelar)
                : (_puedeIniciarRuta
                      ? IniciarRutaPanel(onReal: _iniciarRuta)
                      : const SizedBox.shrink()),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildPage(_currentIndex),
          if (_currentIndex == 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: TopOverlay(
                usuario: widget.usuario,
                esAdmin: _esGestion,
                busesActivos:
                    _busesActivosFirebase.length + (_trackingActivo ? 1 : 0),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        themeProvider: widget.themeProvider,
        userName: widget.usuario['nombre'] as String?,
        userRole: _rolNombre,
        onLogout: _cerrarSesionSegura,
      ),
    );
  }
}

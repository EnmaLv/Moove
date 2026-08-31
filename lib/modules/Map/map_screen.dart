import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../modules/Map/models/bus_model.dart';
import '../../services/api_service.dart';
import '../Bus/bus_catalogo_screen.dart';
import '../auth/login.dart';
import '../../widgets/app_bar.dart';
import '../../widgets/top_overlay.dart';
import '../../widgets/start_route_button.dart';
import 'services/osrm_streets.dart';
import 'services/tracking_service.dart';

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
  String _miPlaca = 'S/N';
  LatLng? _miUbicacion;
  LatLng _centroInicial = const LatLng(9.546987, -69.192543);

  List<Map<String, dynamic>> _paradasRuta = [];
  LatLng? _destinoFinalReal;

  int _indicePuntoActual = 0;
  List<LatLng> _rutaCalles = [];

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
    _mapController.dispose();
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
            if (ultimaAct != null) {
              final diferencia = ahora.difference(ultimaAct.toDate()).inMinutes;
              if (diferencia > 3) continue;
            }

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

    if (mounted) {
      setState(() {
        _mapaListo = true;
      });
      await _verificarYRestaurarViajeActivo();
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

    _busesActivosFirebase.forEach((id, bus) {
      if (id == _viajeIdActivo) return;

      nuevosMarkers.add(
        Marker(
          point: bus.posicion,
          width: 80,
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
              const Icon(Icons.directions_bus, color: Colors.blue, size: 28),
            ],
          ),
        ),
      );
    });

    if (_miUbicacion != null) {
      nuevosMarkers.add(
        Marker(
          point: _miUbicacion!,
          width: 90,
          height: 65,
          child: _buildMiBusMarkerWidget(),
        ),
      );
    }

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

  Widget _buildMiBusMarkerWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _trackingActivo ? Colors.green.shade800 : _red,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _miPlaca,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          Icons.directions_bus_filled,
          color: _trackingActivo ? Colors.green : _red,
          size: 32,
        ),
      ],
    );
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
    _miPlaca = placa;
    _paradasRuta = paradasCargadas;
    _destinoFinalReal = destinoFinal;
    _rutaCalles = puntos;
    _trackingActivo = true;
    _miUbicacion = origen;
    _indicePuntoActual = 0;
    _cargandoRuta = false;

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
      onPositionChanged: (pos) {
        if (!mounted) return;
        final nuevaPos = LatLng(pos.latitude, pos.longitude);

        _miUbicacion = nuevaPos;
        _indicePuntoActual = _puntoMasCercano(nuevaPos);

        _actualizarElementosVisualesDelMapa();
        _mapController.move(nuevaPos, _mapController.camera.zoom);

        if (_destinoFinalReal != null) {
          final distancia = Geolocator.distanceBetween(
            nuevaPos.latitude,
            nuevaPos.longitude,
            _destinoFinalReal!.latitude,
            _destinoFinalReal!.longitude,
          );

          if (distancia <= _radioLlegada) {
            _finalizarRutaEnLaravel(viajeId);
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

  Future<void> _finalizarRutaEnLaravel(String viajeId) async {
    await _trackingService.detenerTracking(viajeId);

    try {
      await ApiService.post('/viajes/$viajeId/finalizar', {
        'km_fin': 1000,
        'pasajeros': 10,
        'litros_gastados': 0,
        'hubo_desvio': false,
      });
    } catch (e) {
      debugPrint("Error finalizando en Laravel: $e");
    }

    _llegarAlDestino();
  }

  void _llegarAlDestino() {
    if (!mounted) return;
    _trackingActivo = false;
    _rutaCalles = [];
    _paradasRuta = [];
    _indicePuntoActual = 0;
    _viajeIdActivo = null;

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
    _actualizarElementosVisualesDelMapa();
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
    int mejor = _indicePuntoActual;
    double menorDist = double.infinity;
    for (int i = _indicePuntoActual; i < _rutaCalles.length; i++) {
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

  bool get _esAdmin => widget.roles.any((r) {
    final nombre = (r['nombre'] ?? '').toString().toLowerCase();
    final slug = (r['slug'] ?? '').toString().toLowerCase();
    return nombre == 'administrador' || slug == 'administrador';
  });

  String? get _rolNombre =>
      widget.roles.isEmpty ? null : widget.roles.first['nombre'] as String?;

  List<NavItem> get _navItems => _esAdmin ? _adminItems : _conductorItems;

  static const _conductorItems = [
    NavItem(label: 'Mapa', icon: Icons.map_outlined, activeIcon: Icons.map),
    NavItem(
      label: 'Agenda',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    NavItem(
      label: 'Mi Viaje',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
    ),
  ];

  static const _adminItems = [
    NavItem(label: 'Mapa', icon: Icons.map_outlined, activeIcon: Icons.map),
    NavItem(
      label: 'Catalogo',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
    ),
    NavItem(
      label: 'Rutas',
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
    ),
    NavItem(
      label: 'Agenda',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    NavItem(
      label: 'Conductores',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    NavItem(
      label: 'Mant.',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
    ),
    NavItem(
      label: 'Reportes',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
    ),
  ];

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() => _currentIndex = 0);
      return;
    }
    if (_esAdmin) {
      _abrirModuloAdmin(index);
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _abrirModuloAdmin(int index) {
    Widget? destino;
    switch (index) {
      case 1:
        destino = BusCatalogoScreen(themeProvider: widget.themeProvider);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_adminItems[index].label}: próximamente'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino!));
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
                ? CancelarRutaButton(onTap: _cancelarRuta)
                : IniciarRutaPanel(onReal: _iniciarRuta),
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
                esAdmin: _esAdmin,
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

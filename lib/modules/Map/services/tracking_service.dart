import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../services/sync_service.dart';

class TrackingService {
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _docSubscription;
  Timer? _heartbeatTimer;

  DateTime? _ultimaActualizacion;
  DateTime? get ultimaActualizacion => _ultimaActualizacion;

  Position? _ultimaPosicionConocida;

  final CollectionReference _busesRef = FirebaseFirestore.instance.collection(
    'buses_activos',
  );

  Future<bool> solicitarPermisos() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void iniciarTracking({
    required String viajeId,
    required String placa,
    required String rutaNombre,
    required String sede,
    required Function(Position pos) onPositionChanged,
    VoidCallback? onCanceladoExternamente,
  }) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _busesRef.doc(viajeId).set({
      'viaje_id': viajeId,
      'placa': placa,
      'ruta_nombre': rutaNombre,
      'sede': sede,
      'pasajeros': 0,
      'ultima_actualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _docSubscription?.cancel();
    _docSubscription = _busesRef.doc(viajeId).snapshots().listen((snapshot) {
      if (!snapshot.exists && _positionStream != null) {
        debugPrint(
          "Documento $viajeId eliminado externamente. Deteniendo GPS...",
        );
        detenerTracking(viajeId);
        onCanceladoExternamente?.call();
      }
    });

    _positionStream?.cancel();
    _heartbeatTimer?.cancel();
    
    _ultimaActualizacion = DateTime.now();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      _ultimaPosicionConocida = position;
      _ultimaActualizacion = DateTime.now();

      await _procesarYEnviarPunto(
        viajeId: viajeId,
        position: position,
        velocidadKmh: position.speed * 3.6,
        onPositionChanged: onPositionChanged,
      );
    });

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (_ultimaActualizacion == null || _ultimaPosicionConocida == null) return;

      final segundosSinMovimiento =
          DateTime.now().difference(_ultimaActualizacion!).inSeconds;

      if (segundosSinMovimiento >= 15) {
        _ultimaActualizacion = DateTime.now();

        await _procesarYEnviarPunto(
          viajeId: viajeId,
          position: _ultimaPosicionConocida!,
          velocidadKmh: 0.0,
          onPositionChanged: onPositionChanged,
        );
      }
    });
  }

  Future<void> _procesarYEnviarPunto({
    required String viajeId,
    required Position position,
    required double velocidadKmh,
    required Function(Position pos) onPositionChanged,
  }) async {
    await SyncService.instance.enqueue(
      type: 'gps',
      endpoint: '/viajes/$viajeId/gps',
      payload: {
        'local_id': const Uuid().v4(),
        'lat': position.latitude,
        'lng': position.longitude,
        'velocidad': velocidadKmh,
        'heading': position.heading,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    SyncService.instance.flush();

    onPositionChanged(position);

    _busesRef.doc(viajeId).set({
      'latitud': position.latitude,
      'longitud': position.longitude,
      'en_movimiento': velocidadKmh > 0.5,
      'heading': position.heading,
      'ultima_actualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).catchError((error) {
      debugPrint("Error Firestore: $error");
    });
  }

  Future<void> detenerTracking(String? viajeId) async {
    await _docSubscription?.cancel();
    _docSubscription = null;

    await _positionStream?.cancel();
    _positionStream = null;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    _ultimaActualizacion = null;
    _ultimaPosicionConocida = null;

    if (viajeId != null && viajeId.isNotEmpty) {
      try {
        await _busesRef.doc(viajeId).delete();
        debugPrint("Bus $viajeId removido con éxito de Firestore.");
      } catch (e) {
        debugPrint("Error al remover bus de Firestore: $e");
      }
    }
  }
}
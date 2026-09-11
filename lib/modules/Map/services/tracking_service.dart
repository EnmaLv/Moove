import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../services/sync_service.dart';

class TrackingService {
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _docSubscription;
  DateTime? _ultimaActualizacion;
  DateTime? get ultimaActualizacion => _ultimaActualizacion;

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
    _ultimaActualizacion = DateTime.now();
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) async {
          _ultimaActualizacion = DateTime.now();
          final speedKmh = position.speed * 3.6;

          // 1. Guardar en cola local con la estructura EXACTA que valida Laravel
          await SyncService.instance.enqueue(
            type: 'gps',
            endpoint: '/viajes/$viajeId/gps',
            payload: {
              'local_id': const Uuid()
                  .v4(), // Requerido por la validación de Laravel
              'lat': position.latitude,
              'lng': position.longitude,
              'velocidad': speedKmh,
              'heading': position.heading,
              'timestamp': DateTime.now()
                  .toUtc()
                  .toIso8601String(), // Campo OBLIGATORIO por Laravel
            },
          );

          // 2. Intentar vaciar cola sin congelar la ejecución del stream
          SyncService.instance.flush();

          // 3. Notificar a la interfaz la nueva posición local inmediatamente
          onPositionChanged(position);

          _busesRef
              .doc(viajeId)
              .set({
                'latitud': position.latitude,
                'longitud': position.longitude,
                'en_movimiento': position.speed > 0.5,
                'heading': position.heading,
                'ultima_actualizacion': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true))
              .catchError((error) {
                debugPrint("Error Firestore: $error");
              });
        });
  }

  Future<void> detenerTracking(String? viajeId) async {
    await _docSubscription?.cancel();
    _docSubscription = null;

    await _positionStream?.cancel();
    _positionStream = null;
    _ultimaActualizacion = null;

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

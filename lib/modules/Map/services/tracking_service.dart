import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '/../services/api_service.dart';

class TrackingService {
  StreamSubscription<Position>? _positionStream;
  final CollectionReference _busesRef =
      FirebaseFirestore.instance.collection('buses_activos');

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
  }) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      onPositionChanged(position);

      _busesRef.doc(viajeId).set({
        'viaje_id': viajeId,
        'placa': placa,
        'ruta_nombre': rutaNombre,
        'latitud': position.latitude,
        'longitud': position.longitude,
        'en_movimiento': position.speed > 0.5,
        'pasajeros': 0,
        'sede': sede,
        'ultima_actualizacion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((error) {
        debugPrint("Error Firestore: $error");
      });

      try {
        final speedKmh = position.speed * 3.6;
        await ApiService.post('/viajes/$viajeId/gps', {
          'lat': position.latitude,
          'lng': position.longitude,
          'velocidad': speedKmh,
          'heading': position.heading,
        });
      } catch (e) {
        debugPrint("Error al enviar GPS a Laravel HTTP: $e");
      }
    });
  }

  Future<void> detenerTracking(String? viajeId) async {
    await _positionStream?.cancel();
    _positionStream = null;

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
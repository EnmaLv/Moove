import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

double calcularBearing(LatLng desde, LatLng hasta) {
  final lat1 = desde.latitudeInRad;
  final lat2 = hasta.latitudeInRad;
  final dLon = (hasta.longitude - desde.longitude) * (math.pi / 180);

  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

  final bearingRad = math.atan2(y, x);
  final bearingDeg = bearingRad * (180 / math.pi);
  return (bearingDeg + 360) % 360;
}

double diferenciaAngularCorta(double desde, double hasta) {
  double diff = (hasta - desde + 180) % 360 - 180;
  return diff < -180 ? diff + 360 : diff;
}
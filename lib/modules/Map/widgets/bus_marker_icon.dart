import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BusMarkerIcon extends StatelessWidget {
  final double heading;
  final double size;
  final bool activo;
  final bool senalPerdida;
  final String assetPath;

  const BusMarkerIcon({
    super.key,
    required this.heading,
    this.size = 512,
    this.activo = true,
    this.senalPerdida = false,
    this.assetPath = 'assets/icons/Moove_Bus.svg',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: heading, end: heading),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * (3.1415926535 / 180),
          child: child,
        );
      },
      child: Opacity(
        opacity: senalPerdida ? 0.45 : (activo ? 1.0 : 0.55),
        child: ColorFiltered(
          colorFilter: senalPerdida
              ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
              : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
          child: SvgPicture.asset(assetPath, width: size, height: size),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../model/bus_vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  final BusVehiculo vehiculo;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  static const _red = Color(0xFFB71C1C);

  const VehicleCard({
    super.key,
    required this.vehiculo,
    required this.isDark,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  Color _obtenerColorEstado() {
    switch (vehiculo.estado) {
      case 'disponible':
        return const Color(0xFF2E7D32);
      case 'en_ruta':
        return const Color(0xFFEF6C00);
      case 'mantenimiento':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  String _obtenerTextoEstado() {
    switch (vehiculo.estado) {
      case 'disponible':
        return 'Disponible';
      case 'en_ruta':
        return 'En Ruta';
      case 'mantenimiento':
        return 'Mantenimiento';
      default:
        return 'Inactivo';
    }
  }

  void _mostrarDetalles(BuildContext context) {
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final estadoColor = _obtenerColorEstado();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: _red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ficha Técnica',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          vehiculo.placa,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _obtenerTextoEstado().toUpperCase(),
                      style: TextStyle(
                        color: estadoColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),

              _buildDetailRow(
                Icons.directions_car_outlined,
                'Marca y Modelo',
                '${vehiculo.marcaNombre} ${vehiculo.modeloNombre}',
              ),
              _buildDetailRow(
                Icons.calendar_today_outlined,
                'Año de fabricación',
                '${vehiculo.anio}',
              ),
              _buildDetailRow(
                Icons.color_lens_outlined,
                'Color del Vehículo',
                vehiculo.color,
              ),
              _buildDetailRow(
                Icons.groups_outlined,
                'Capacidad autorizada',
                '${vehiculo.cantidadPasajeros} Pasajeros',
              ),
              _buildDetailRow(
                Icons.local_gas_station_outlined,
                'Combustible',
                vehiculo.combustibleNombre,
              ),
              _buildDetailRow(
                Icons.opacity_outlined,
                'Capacidad del Tanque',
                '${vehiculo.capacidadTanqueLitros.toStringAsFixed(1)} Litros',
              ),
              _buildDetailRow(
                Icons.speed_outlined,
                'Rendimiento estimado',
                '${vehiculo.consumoLitrosKm.toStringAsFixed(3)} L/Km',
              ),
              _buildDetailRow(
                Icons.ev_station_outlined,
                'Bocas de Llenado',
                '${vehiculo.cantidadBocas}',
              ),
              _buildDetailRow(
                Icons.timeline,
                'Kilometraje Actual',
                '${vehiculo.kmActual.toStringAsFixed(0)} KM',
              ),
              _buildDetailRow(
                Icons.build_circle_outlined,
                'Próximo Mantenimiento',
                '${vehiculo.kmProximoMantenimiento.toStringAsFixed(0)} KM',
              ),
              _buildDetailRow(
                Icons.business_outlined,
                'Sede asignada',
                vehiculo.sedeNombre,
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cerrar Ficha',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _red.withValues(alpha: 0.6)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final estadoColor = _obtenerColorEstado();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: cardBg,
        clipBehavior: Clip
            .antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          side: vehiculo.activo
              ? BorderSide.none
              : BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          onTap: () => _mostrarDetalles(context),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: vehiculo.activo
                  ? _red.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: vehiculo.activo ? _red : Colors.grey,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  vehiculo.placa,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.5,
                    color: vehiculo.activo
                        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _obtenerTextoEstado(),
                  style: TextStyle(
                    color: estadoColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${vehiculo.marcaNombre} ${vehiculo.modeloNombre} (${vehiculo.anio})\nCapacidad: ${vehiculo.cantidadPasajeros} Pasajeros',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: vehiculo.activo ? _red : Colors.grey[300],
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: vehiculo.activo
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                color: const Color(0xFF555555),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: onDelete,
                color: _red,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'model/bus_vehicle_model.dart';
import 'model/bus_model.dart';
import 'model/bus_fuel_type_model.dart';
import 'service/bus_vehicle_service.dart';
import 'widgets/bus_vehicle_stats_bar.dart';
import 'widgets/bus_vehicle_card.dart';
import 'widgets/bus_vehicle_formsheet.dart';

class BusVehicleScreen extends StatefulWidget {
  const BusVehicleScreen({super.key});

  @override
  State<BusVehicleScreen> createState() => _BusVehicleScreenState();
}

class _BusVehicleScreenState extends State<BusVehicleScreen> {
  static const _red = Color(0xFFB71C1C);

  List<BusVehiculo> _vehiculos = [];
  List<BusVehiculo> _filtrados = [];
  List<BusModelo> _modelos = [];
  List<BusTipoCombustible> _combustibles = [];
  List<Map<String, dynamic>> _sedes = [];

  bool _cargando = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        BusVehiculoService.getAll(),
        BusVehiculoService.getModelos(),
        BusVehiculoService.getCombustibles(),
        BusVehiculoService.getSedes(),
      ]);

      if (!mounted) return;

      setState(() {
        _vehiculos = results[0] as List<BusVehiculo>;
        _modelos = results[1] as List<BusModelo>;
        _combustibles = results[2] as List<BusTipoCombustible>;
        _sedes = results[3] as List<Map<String, dynamic>>;
        _filtrados = _vehiculos;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _vehiculos.where((v) {
        return v.placa.toLowerCase().contains(q) ||
            v.modeloNombre.toLowerCase().contains(q) ||
            v.marcaNombre.toLowerCase().contains(q) ||
            v.color.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _crearOEditar({BusVehiculo? vehiculo}) async {
    if (_modelos.isEmpty || _combustibles.isEmpty) {
      _snack(
        'Asegúrese de tener marcas, modelos y combustibles cargados primero.',
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VehicleFormSheet(
        vehiculo: vehiculo,
        modelos: _modelos,
        combustibles: _combustibles,
        sedes: _sedes,
      ),
    );
    if (result == null || !mounted) return;

    try {
      if (vehiculo == null) {
        final nuevo = await BusVehiculoService.create(result);
        if (!mounted) return;
        setState(() {
          _vehiculos.add(nuevo);
          _filtrar();
        });
        _snack('Vehículo [${nuevo.placa}] registrado.', success: true);
      } else {
        final actualizado = await BusVehiculoService.update(
          vehiculo.id,
          result,
        );
        if (!mounted) return;
        setState(() {
          final i = _vehiculos.indexWhere((v) => v.id == vehiculo.id);
          if (i != -1) _vehiculos[i] = actualizado;
          _filtrar();
        });
        _snack('Vehículo actualizado con éxito.', success: true);
      }
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _toggle(BusVehiculo vehiculo) async {
    try {
      await BusVehiculoService.toggle(vehiculo.id);
      if (!mounted) return;
      setState(() {
        final i = _vehiculos.indexWhere((v) => v.id == vehiculo.id);
        if (i != -1) {
          _vehiculos[i] = vehiculo.copyWith(
            activo: !vehiculo.activo,
            estado: !vehiculo.activo ? 'disponible' : 'inactivo',
          );
        }
        _filtrar();
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _eliminar(BusVehiculo vehiculo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar Vehículo?'),
        content: Text(
          'Se removerá la placa "${vehiculo.placa}" del sistema de manera irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await BusVehiculoService.delete(vehiculo.id);
      if (!mounted) return;
      setState(() {
        _vehiculos.removeWhere((v) => v.id == vehiculo.id);
        _filtrar();
      });
      _snack('Vehículo eliminado permanentemente.', success: true);
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF2E7D32) : _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_bus_vehiculo',
        onPressed: () => _crearOEditar(),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_road_rounded),
        label: const Text(
          'Nuevo Vehículo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: _red,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por placa, modelo o marca...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          VehicleStatsBar(vehiculos: _vehiculos),
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'No hay vehículos registrados.'
                  : 'Sin resultados para la búsqueda.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: _red,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: _filtrados.length,
        itemBuilder: (_, i) => VehicleCard(
          vehiculo: _filtrados[i],
          isDark: isDark,
          onEdit: () => _crearOEditar(vehiculo: _filtrados[i]),
          onToggle: () => _toggle(_filtrados[i]),
          onDelete: () => _eliminar(_filtrados[i]),
        ),
      ),
    );
  }
}

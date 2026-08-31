import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'service/bus_fuel_type_service.dart';
import 'model/bus_fuel_type_model.dart';
import 'widgets/bus_fuel_type_stats_bar.dart';
import 'widgets/bus_fuel_type_card.dart';
import 'widgets/bus_fuel_type_formsheet.dart';
import 'package:moove/services/catalog_signal.dart';

class BusFuelTypeScreen extends StatefulWidget {
  const BusFuelTypeScreen({super.key});

  @override
  State<BusFuelTypeScreen> createState() => _BusFuelTypeScreenState();
}

class _BusFuelTypeScreenState extends State<BusFuelTypeScreen> {
  static const _red = Color(0xFFB71C1C);
  List<BusTipoCombustible> _combustibles = [];
  List<BusTipoCombustible> _filtrados = [];
  bool _cargando = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(_filtrar);
    CatalogSignal.notifier.addListener(_onCatalogChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    CatalogSignal.notifier.removeListener(_onCatalogChanged);
    super.dispose();
  }

  void _onCatalogChanged() {
    if (mounted) {
      _cargar(); 
    }
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = null; });
    try {
      final data = await BusTipoCombustibleService.getAll();
      
      // Guardián: Si la pantalla se cerró mientras cargaba la API
      if (!mounted) return;
      setState(() { _combustibles = data; _filtrados = data; });
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
      _filtrados = _combustibles.where((c) => c.nombre.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _crearOEditar({BusTipoCombustible? combustible}) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FuelTypeFormSheet(combustible: combustible),
    );
    // Guardián: Por si el modal se cierra y destruimos la pantalla al mismo tiempo
    if (result == null || !mounted) return;

    final nombre = result['nombre']!;
    final descripcion = result['descripcion']!;

    try {
      if (combustible == null) {
        final nuevo = await BusTipoCombustibleService.create(nombre, descripcion);
        if (!mounted) return; // Guardián post-API
        setState(() { _combustibles.add(nuevo); _filtrar(); });
        CatalogSignal.notifyChange();
        _snack('Tipo de combustible "${nuevo.nombre}" creado.', success: true);
      } else {
        final actualizado = await BusTipoCombustibleService.update(combustible.id, nombre, descripcion);
        if (!mounted) return; // Guardián post-API
        setState(() {
          final i = _combustibles.indexWhere((c) => c.id == combustible.id);
          if (i != -1) _combustibles[i] = actualizado;
          _filtrar();
        });
        CatalogSignal.notifyChange();
        _snack('Combustible actualizado.', success: true);
      }
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _toggle(BusTipoCombustible combustible) async {
    try {
      await BusTipoCombustibleService.toggle(combustible.id);
      if (!mounted) return; // Guardián post-API
      setState(() {
        final i = _combustibles.indexWhere((c) => c.id == combustible.id);
        if (i != -1) _combustibles[i] = combustible.copyWith(estado: !combustible.estado);
        _filtrar();
      });
      CatalogSignal.notifyChange();
      HapticFeedback.lightImpact();
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
        heroTag: 'fab_bus_fuel',
        onPressed: () => _crearOEditar(),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Combustible', style: TextStyle(fontWeight: FontWeight.w700)),
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
                hintText: 'Buscar combustible...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          FuelTypeStatsBar(combustibles: _combustibles),
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
            TextButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_gas_station_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(_searchCtrl.text.isEmpty ? 'No hay combustibles registrados.' : 'Sin resultados para "${_searchCtrl.text}".', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: _red,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filtrados.length,
        itemBuilder: (_, i) => FuelTypeCard(
          combustible: _filtrados[i],
          isDark: isDark,
          onEdit: () => _crearOEditar(combustible: _filtrados[i]),
          onToggle: () => _toggle(_filtrados[i]),
        ),
      ),
    );
  }
}
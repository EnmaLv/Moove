import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Bus/model/bus_brand_model.dart';
import '../Bus/model/bus_model.dart';
import '../Bus/service/bus_model_service.dart';
import 'widgets/bus_model_stats_bar.dart';
import 'widgets/bus_model_card.dart';
import 'widgets/bus_model_formsheet.dart';
import 'widgets/bus_model_filter_chip.dart';
import 'package:moove/services/catalog_signal.dart';

class BusModeloScreen extends StatefulWidget {
  const BusModeloScreen({super.key});

  @override
  State<BusModeloScreen> createState() => _BusModeloScreenState();
}

class _BusModeloScreenState extends State<BusModeloScreen> {
  static const _red = Color(0xFFB71C1C);

  List<BusModelo> _modelos = [];
  List<BusModelo> _filtrados = [];
  List<BusMarca> _marcas = [];
  bool _cargando = true;
  String? _error;
  String? _filtroMarcaId;
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
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        BusModeloService.getAll(),
        BusModeloService.getMarcas(),
      ]);

      if (!mounted) return;

      setState(() {
        _modelos = results[0] as List<BusModelo>;
        final marcas = results[1] as List<BusMarca>;
        _marcas = marcas.where((m) => m.estado).toList();
      });

      _filtrar();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _modelos.where((m) {
        final coincideTexto =
            m.nombre.toLowerCase().contains(q) ||
            m.marcaNombre.toLowerCase().contains(q);
        final coincideMarca =
            _filtroMarcaId == null || m.marcaId.toString() == _filtroMarcaId;
        return coincideTexto && coincideMarca;
      }).toList();
    });
  }

  void _setFiltroMarca(String? id) {
    setState(() => _filtroMarcaId = id);
    _filtrar();
  }

  Future<void> _crearOEditar({BusModelo? modelo}) async {
    if (_marcas.isEmpty) {
      _snack('Primero registra al menos una marca.');
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ModeloFormSheet(modelo: modelo, marcas: _marcas),
    );
    if (result == null || !mounted) return;

    final marcaId = result['marcaId'] as int;
    final nombre = result['nombre'] as String;

    try {
      if (modelo == null) {
        final nuevo = await BusModeloService.create(marcaId, nombre);
        if (!mounted) return;
        setState(() {
          _modelos.add(nuevo);
          _filtrar();
        });
        CatalogSignal.notifyChange();
        _snack('Modelo "${nuevo.nombre}" creado.', success: true);
      } else {
        final actualizado = await BusModeloService.update(
          modelo.id,
          marcaId,
          nombre,
        );
        if (!mounted) return;
        setState(() {
          final i = _modelos.indexWhere((m) => m.id == modelo.id);
          if (i != -1) _modelos[i] = actualizado;
          _filtrar();
        });
        CatalogSignal.notifyChange();
        _snack('Modelo actualizado.', success: true);
      }
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _toggle(BusModelo modelo) async {
    try {
      await BusModeloService.toggle(modelo.id);
      if (!mounted) return;
      setState(() {
        final i = _modelos.indexWhere((m) => m.id == modelo.id);
        if (i != -1) _modelos[i] = modelo.copyWith(estado: !modelo.estado);
        _filtrar();
      });
      CatalogSignal.notifyChange();
      HapticFeedback.lightImpact();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _eliminar(BusModelo modelo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar modelo?'),
        content: Text('Se eliminará "${modelo.nombre}" permanentemente.'),
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
      await BusModeloService.delete(modelo.id);
      if (!mounted) return;
      setState(() {
        _modelos.removeWhere((m) => m.id == modelo.id);
        _filtrar();
      });
      CatalogSignal.notifyChange();
      _snack('Modelo eliminado.', success: true);
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
        heroTag: 'fab_bus_modelo',
        onPressed: () => _crearOEditar(),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo Modelo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: _red,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar modelo o marca...',
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
                const SizedBox(height: 10),
                if (_marcas.isNotEmpty)
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FiltroChip(
                          label: 'Todas',
                          activo: _filtroMarcaId == null,
                          onTap: () => _setFiltroMarca(null),
                        ),
                        ..._marcas.map(
                          (m) => FiltroChip(
                            label: m.nombre,
                            activo: _filtroMarcaId == m.id.toString(),
                            onTap: () => _setFiltroMarca(m.id.toString()),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          StatsBar(modelos: _modelos, marcas: _marcas),

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
            Icon(Icons.car_repair_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isEmpty && _filtroMarcaId == null
                  ? 'No hay modelos registrados.'
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filtrados.length,
        itemBuilder: (_, i) => ModeloCard(
          modelo: _filtrados[i],
          isDark: isDark,
          onEdit: () => _crearOEditar(modelo: _filtrados[i]),
          onToggle: () => _toggle(_filtrados[i]),
          onDelete: () => _eliminar(_filtrados[i]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'service/bus_brand_service.dart';
import 'model/bus_brand_model.dart';
import 'widgets/bus_brand_stats_bar.dart';
import 'widgets/bus_brand_card.dart';
import 'widgets/bus_brand_formsheet.dart';
import 'package:moove/services/catalog_signal.dart';

class BusMarcaScreen extends StatefulWidget {
  const BusMarcaScreen({super.key});

  @override
  State<BusMarcaScreen> createState() => _BusMarcaScreenState();
}

class _BusMarcaScreenState extends State<BusMarcaScreen> {
  static const _red = Color(0xFFB71C1C);
  List<BusMarca> _marcas = [];
  List<BusMarca> _filtradas = [];
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
      _cargar(); // Vuelve a traer los modelos y las marcas actualizadas de la API
    }
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await BusMarcaService.getAll();
      
      // Guardián: Si destruiste la pantalla mientras cargaba la API
      if (!mounted) return;
      setState(() {
        _marcas = data;
        _filtradas = data;
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
      _filtradas = _marcas
          .where((m) => m.nombre.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _crearOEditar({BusMarca? marca}) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarcaFormSheet(marca: marca),
    );
    // Guardián: Si se cerró el modal y saliste de la pantalla al mismo tiempo
    if (result == null || !mounted) return;

    try {
      if (marca == null) {
        final nueva = await BusMarcaService.create(result);
        if (!mounted) return; // Guardián post-API
        setState(() {
          _marcas.add(nueva);
          _filtrar();
        });
        CatalogSignal.notifyChange();
        _snack('Marca "${nueva.nombre}" creada.', success: true);
      } else {
        final actualizada = await BusMarcaService.update(marca.id, result);
        if (!mounted) return; // Guardián post-API
        setState(() {
          final i = _marcas.indexWhere((m) => m.id == marca.id);
          if (i != -1) _marcas[i] = actualizada;
          _filtrar();
        });
        CatalogSignal.notifyChange();
        _snack('Marca actualizada.', success: true);
      }
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _toggle(BusMarca marca) async {
    try {
      await BusMarcaService.toggle(marca.id);
      if (!mounted) return; // Guardián post-API
      setState(() {
        final i = _marcas.indexWhere((m) => m.id == marca.id);
        if (i != -1) _marcas[i] = marca.copyWith(estado: !marca.estado);
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
        heroTag: 'fab_bus_marca',
        onPressed: () => _crearOEditar(),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nueva Marca',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: _red,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar marca...',
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

          // Estadísticas rápidas
          StatsBar(marcas: _marcas),

          // Lista
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

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

    if (_filtradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'No hay marcas registradas.'
                  : 'Sin resultados para "${_searchCtrl.text}".',
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
        itemCount: _filtradas.length,
        itemBuilder: (_, i) => MarcaCard(
          marca: _filtradas[i],
          isDark: isDark,
          onEdit: () => _crearOEditar(marca: _filtradas[i]),
          onToggle: () => _toggle(_filtradas[i]),
          onDelete: () => CatalogSignal.notifyChange(),
        ),
      ),
    );
  }
}
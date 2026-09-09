import 'package:flutter/material.dart';
import '../../widgets/app_bar.dart';
import 'model/bus_viaje_model.dart';
import 'service/bus_viaje_service.dart';

const _viajeItems = [
  NavItem(
    label: 'Cartelera',
    icon: Icons.alt_route_outlined,
    activeIcon: Icons.alt_route,
  ),
];

class BusViajeScreen extends StatefulWidget {
  final AppThemeProvider themeProvider;
  const BusViajeScreen({super.key, required this.themeProvider});

  @override
  State<BusViajeScreen> createState() => _BusViajeScreenState();
}

class _BusViajeScreenState extends State<BusViajeScreen>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFB71C1C);
  int _currentIndex = 0;
  List<BusViaje> _viajes = [];
  bool _cargando = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final data = await BusViajeService.getViajesHoy();
      if (!mounted) return;
      setState(() => _viajes = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    final enCurso = _viajes.where((v) => v.enCurso).toList();
    final programados = _viajes.where((v) => v.programado).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Cartelera de Viajes'),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelColor: Colors.white70,
          labelColor: Colors.white,
          tabs: [
            Tab(text: 'En Curso (${enCurso.length})'),
            Tab(text: 'Programados (${programados.length})'),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _red))
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(_error!),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _cargar,
                    style: ElevatedButton.styleFrom(backgroundColor: _red),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: _red,
              onRefresh: _cargar,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLista(enCurso, isDark, esEnCurso: true),
                  _buildLista(programados, isDark, esEnCurso: false),
                ],
              ),
            ),
      bottomNavigationBar: AppBottomNav(
        items: _viajeItems,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        themeProvider: widget.themeProvider,
      ),
    );
  }

  Widget _buildLista(
    List<BusViaje> lista,
    bool isDark, {
    required bool esEnCurso,
  }) {
    if (lista.isEmpty) {
      return Center(
        child: Text(
          esEnCurso
              ? 'No hay viajes en curso en este momento.'
              : 'No hay viajes programados para hoy.',
          style: TextStyle(color: Colors.grey[500]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (_, i) => _buildCard(lista[i], isDark),
    );
  }

  Widget _buildCard(BusViaje viaje, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    viaje.rutaNombre ?? 'Ruta no asignada',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: viaje.enCurso
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    viaje.enCurso ? 'EN CURSO' : 'PROGRAMADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: viaje.enCurso
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(Icons.directions_bus, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Vehículo: ${viaje.vehiculoPlaca ?? 'S/N'}',
                  style: const TextStyle(fontSize: 13),
                ),
                const Spacer(),
                if (viaje.turno != null) ...[
                  const Icon(Icons.schedule, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Turno: ${viaje.turno}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Conductor: ${viaje.conductorNombre ?? 'Sin asignar'}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

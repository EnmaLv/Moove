import 'package:flutter/material.dart';
import '../../widgets/app_bar.dart';
import 'bus_brand_screen.dart';
import 'bus_model_screen.dart';
import 'bus_fuel_type_screen.dart';

const _catalogoItems = [
  NavItem(
    label: 'Marcas',
    icon: Icons.directions_car_outlined,
    activeIcon: Icons.directions_car,
  ),
  NavItem(
    label: 'Modelos',
    icon: Icons.car_repair_outlined,
    activeIcon: Icons.car_repair,
  ),
  NavItem(
    label: 'Combustible',
    icon: Icons.local_gas_station_outlined,
    activeIcon: Icons.local_gas_station,
  ),
];

class BusCatalogoScreen extends StatefulWidget {
  final AppThemeProvider themeProvider;
  const BusCatalogoScreen({super.key, required this.themeProvider});

  @override
  State<BusCatalogoScreen> createState() => _BusCatalogoScreenState();
}

class _BusCatalogoScreenState extends State<BusCatalogoScreen> {
  static const _red = Color(0xFFB71C1C);
  int _currentIndex = 0;

  static const _titles = [
    'Marcas de Vehículo',
    'Modelos',
    'Tipo de Combustible',
  ];
  static const _subtitles = [
    'Catálogo · Marcas',
    'Catálogo · Modelos',
    'Catálogo · Combustible',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(_currentIndex),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _titles[_currentIndex],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _subtitles[_currentIndex],
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [_TabMarcas(), _TabModelos(), _TabCombustible()],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _catalogoItems,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        themeProvider: widget.themeProvider,
      ),
    );
  }
}

class _TabMarcas extends StatelessWidget {
  const _TabMarcas();
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const BusMarcaScreen()),
    );
  }
}

class _TabModelos extends StatelessWidget {
  const _TabModelos();
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const BusModeloScreen()),
    );
  }
}

class _TabCombustible extends StatelessWidget {
  const _TabCombustible();
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const BusFuelTypeScreen()),
    );
  }
}

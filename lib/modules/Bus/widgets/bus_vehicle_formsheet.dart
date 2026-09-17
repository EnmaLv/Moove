import 'package:flutter/material.dart';
import '../model/bus_vehicle_model.dart';
import '../model/bus_model.dart';
import '../model/bus_fuel_type_model.dart';

class VehicleFormSheet extends StatefulWidget {
  final BusVehiculo? vehiculo;
  final List<BusModelo> modelos;
  final List<BusTipoCombustible> combustibles;
  final List<Map<String, dynamic>> sedes;

  const VehicleFormSheet({
    super.key,
    this.vehiculo,
    required this.modelos,
    required this.combustibles,
    required this.sedes,
  });

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  static const _red = Color(0xFFB71C1C);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _placaCtrl;
  late TextEditingController _anioCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _pesoCtrl;
  late TextEditingController _pasajerosCtrl;
  late TextEditingController _bocasCtrl;
  late TextEditingController _tanqueCtrl;
  late TextEditingController _consumoCtrl;
  late TextEditingController _kmCtrl;
  late TextEditingController _kmMaintCtrl;

  BusModelo? _modeloSel;
  BusTipoCombustible? _combustibleSel;
  int? _sedeSelId;
  String? _estadoSel;

  bool get _esEditar => widget.vehiculo != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehiculo;

    _placaCtrl = TextEditingController(text: v?.placa ?? '');
    _anioCtrl = TextEditingController(text: v?.anio.toString() ?? '');
    _colorCtrl = TextEditingController(text: v?.color ?? '');
    _pesoCtrl = TextEditingController(text: v?.peso.toString() ?? '');
    _pasajerosCtrl = TextEditingController(
      text: v?.cantidadPasajeros.toString() ?? '',
    );
    _bocasCtrl = TextEditingController(
      text: v?.cantidadBocas.toString() ?? '1',
    );
    _tanqueCtrl = TextEditingController(
      text: v?.capacidadTanqueLitros.toString() ?? '',
    );
    _consumoCtrl = TextEditingController(
      text: v?.consumoLitrosKm.toString() ?? '',
    );
    _kmCtrl = TextEditingController(text: v?.kmActual.toString() ?? '0');
    _kmMaintCtrl = TextEditingController(
      text: v?.kmProximoMantenimiento.toString() ?? '',
    );

    if (_esEditar) {
      _modeloSel = widget.modelos.where((m) => m.id == v!.modeloId).firstOrNull;
      _combustibleSel = widget.combustibles
          .where((c) => c.id == v!.tipoCombustibleId)
          .firstOrNull;
      _sedeSelId = v!.sedeId;
      _estadoSel = v.estado;
    } else {
      _estadoSel = 'disponible';
      if (widget.sedes.isNotEmpty) {
        _sedeSelId = widget.sedes.first['id'] as int;
      }
    }
  }

  @override
  void dispose() {
    _placaCtrl.dispose();
    _anioCtrl.dispose();
    _colorCtrl.dispose();
    _pesoCtrl.dispose();
    _pasajerosCtrl.dispose();
    _bocasCtrl.dispose();
    _tanqueCtrl.dispose();
    _consumoCtrl.dispose();
    _kmCtrl.dispose();
    _kmMaintCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate() ||
        _modeloSel == null ||
        _combustibleSel == null ||
        _sedeSelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, rellene todos los campos obligatorios.'),
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'placa': _placaCtrl.text.trim().toUpperCase(),
      'modelo_id': _modeloSel!.id,
      'anio': int.parse(_anioCtrl.text),
      'color': _colorCtrl.text.trim(),
      'peso': int.parse(_pesoCtrl.text),
      'cantidad_pasajeros': int.parse(_pasajerosCtrl.text),
      'tipo_combustible_id': _combustibleSel!.id,
      'cantidad_cilindros': int.parse(_bocasCtrl.text),
      'capacidad_tanque_litros': double.parse(_tanqueCtrl.text),
      'consumo_litros_km': double.parse(_consumoCtrl.text),
      'km_actual': double.parse(_kmCtrl.text),
      'km_proximo_mantenimiento': double.parse(_kmMaintCtrl.text),
      'sede_id': _sedeSelId,
      'estado': _estadoSel,
    });
  }

  InputDecoration _deco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildSectionTitle('Identificación Básica'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _placaCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _deco(
                              'Placa / Patente',
                              Icons.badge_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _anioCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco(
                              'Año',
                              Icons.calendar_today_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _colorCtrl,
                            decoration: _deco(
                              'Color',
                              Icons.color_lens_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _pasajerosCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco(
                              'Pasajeros',
                              Icons.groups_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<BusModelo>(
                      initialValue:
                          _modeloSel,
                      hint: const Text('Seleccione Modelo'),
                      decoration: _deco(
                        'Modelo de Vehículo',
                        Icons.model_training,
                      ),
                      items: widget.modelos
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text('${m.marcaNombre} ${m.nombre}'),
                            ),
                          )
                          .toList(),
                      onChanged: (m) => setState(() => _modeloSel = m),
                    ),

                    const SizedBox(height: 20),
                    _buildSectionTitle('Combustible y Rendimiento'),
                    DropdownButtonFormField<BusTipoCombustible>(
                      initialValue: _combustibleSel,
                      hint: const Text('Tipo de Combustible'),
                      decoration: _deco(
                        'Combustible',
                        Icons.local_gas_station_outlined,
                      ),
                      items: widget.combustibles
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (c) => setState(() => _combustibleSel = c),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tanqueCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco(
                              'Capacidad (Lts)',
                              Icons.opacity_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _consumoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco(
                              'Consumo (L/Km)',
                              Icons.speed_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pesoCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco('Peso del Vehiculo', Icons.scale),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _bocasCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco(
                              'Cilindros',
                              Icons.engineering_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _buildSectionTitle('Odómetro y Asignación'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _kmCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco('KM Actual', Icons.timeline),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _kmMaintCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _deco(
                              'Próx. Manto (KM)',
                              Icons.build_circle_outlined,
                            ),
                            validator: (val) =>
                                val!.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      initialValue: _sedeSelId,
                      decoration: _deco('Sede', Icons.business_outlined),
                      items: widget.sedes
                          .map(
                            (s) => DropdownMenuItem(
                              value: s['id'] as int,
                              child: Text(s['nombre'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(() => _sedeSelId = id),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _estadoSel,
                      decoration: _deco(
                        'Estado Inicial',
                        Icons.traffic_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'disponible',
                          child: Text('Disponible'),
                        ),
                        DropdownMenuItem(
                          value: 'en_ruta',
                          child: Text('En Ruta'),
                        ),
                        DropdownMenuItem(
                          value: 'mantenimiento',
                          child: Text('Mantenimiento'),
                        ),
                      ],
                      onChanged: (est) => setState(() => _estadoSel = est),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _esEditar
                                  ? 'Guardar cambios'
                                  : 'Registrar vehículo',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _red,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: _red.withValues(alpha: 0.2), thickness: 1),
          ),
        ],
      ),
    );
  }
}

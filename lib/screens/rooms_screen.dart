import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/room_model.dart';
import 'package:app_geriatrico/data/repositories/room_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';

class RoomsScreen extends StatefulWidget {
  final String token;
  const RoomsScreen({super.key, required this.token});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  late final ApiService _api;
  late final RoomRepository _repo;

  List<Room> _rooms = [];
  bool _loading = true;
  String? _error;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _api  = ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token);
    _repo = RoomRepository(_api);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rooms = await _repo.getAll();
      setState(() => _rooms = rooms);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }


  void _openForm({Room? room}) {
    final numberCtrl  = TextEditingController(text: room?.number ?? '');
    final nameCtrl    = TextEditingController(text: room?.name ?? '');
    final floorCtrl   = TextEditingController(text: room?.floor ?? '');
    final capCtrl     = TextEditingController(text: room?.capacity.toString() ?? '1');
    String type   = room?.type ?? 'shared';
    String status = room?.status ?? 'available';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A0825),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // handle
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        room == null ? 'Nueva habitación' : 'Editar habitación',
                        style: const TextStyle(color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w300),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: Colors.white.withValues(alpha: 0.40), size: 18),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.06),
                      margin: const EdgeInsets.only(bottom: 16)),

                
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _field(numberCtrl, 'Número de habitación *',
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(floorCtrl, 'Piso',
                          keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 6),

                 
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _field(nameCtrl, 'Nombre (opcional)')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(capCtrl, 'Capacidad',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if ((int.tryParse(v) ?? 0) < 1) return 'Min. 1';
                            return null;
                          })),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: _dropdown<String>(
                          label: 'Tipo',
                          value: type,
                          items: const [
                            DropdownMenuItem(value: 'shared',  child: Text('Compartida')),
                            DropdownMenuItem(value: 'private', child: Text('Privada')),
                          ],
                          onChanged: (v) => setModal(() => type = v ?? 'shared'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown<String>(
                          label: 'Estado',
                          value: status,
                          items: const [
                            DropdownMenuItem(value: 'available',   child: Text('Disponible')),
                            DropdownMenuItem(value: 'maintenance', child: Text('Mantenimiento')),
                            DropdownMenuItem(value: 'inactive',    child: Text('Inactiva')),
                          ],
                          onChanged: (v) => setModal(() => status = v ?? 'available'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: saving ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setModal(() => saving = true);
                        final r = Room(
                          id:       room?.id ?? 0,
                          number:   numberCtrl.text.trim(),
                          name:     nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
                          floor:    floorCtrl.text.trim().isEmpty ? null : floorCtrl.text.trim(),
                          capacity: int.tryParse(capCtrl.text.trim()) ?? 1,
                          type:     type,
                          status:   status,
                        );
                        try {
                          if (room == null) {
                            await _repo.create(r);
                          } else {
                            await _repo.update(r);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            _load();
                            _showSnack(room == null
                                ? 'Habitación creada'
                                : 'Habitación actualizada', success: true);
                          }
                        } catch (e) {
                          setModal(() => saving = false);
                          if (mounted) {
                            _showSnack(e.toString().replaceFirst('Exception: ', ''));
                          }
                        }
                      },
                      child: saving
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(room == null ? 'Crear habitación' : 'Guardar cambios',
                              style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.w400)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  Future<void> _confirmDelete(Room room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3A0B32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        title: const Text('Eliminar habitación',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text(
          '¿Eliminar la habitación ${room.number}? Esta acción no se puede deshacer.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.50))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar',
                style: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await _repo.delete(room.id);
        _load();
        _showSnack('Habitación eliminada', success: true);
      } catch (e) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: success
          ? Colors.green.withValues(alpha: 0.85)
          : AppColors.error.withValues(alpha: 0.85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }



  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54)),
        errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65))),
        errorStyle: TextStyle(
            color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
      );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: _deco(label),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      dropdownColor: const Color(0xFF2A0825),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: _deco(label),
      items: items,
      onChanged: onChanged,
    );
  }

  

  Color _bedColor(String s) {
    switch (s) {
      case 'occupied':    return const Color(0xFFEF5350);
      case 'maintenance': return const Color(0xFFFF9800);
      default:            return Colors.green;
    }
  }

  String _bedLabel(String s) {
    switch (s) {
      case 'occupied':    return 'Ocupada';
      case 'maintenance': return 'Mant.';
      default:            return 'Libre';
    }
  }

  

  Widget _roomCard(Room room) {
    final isExpanded = _expanded.contains(room.id);
    final pct = room.totalBeds == 0
        ? 0.0
        : room.occupiedBeds / room.totalBeds;
    final ringColor = pct >= 1.0
        ? const Color(0xFFEF5350)
        : pct > 0.5
            ? const Color(0xFFFF9800)
            : Colors.green;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isExpanded
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        children: [
          
          InkWell(
            onTap: () => setState(() {
              if (isExpanded) {
                _expanded.remove(room.id);
              } else {
                _expanded.add(room.id);
              }
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Círculo de ocupación
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 38, height: 38,
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 2.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                        ),
                      ),
                      Icon(Icons.meeting_room_outlined, size: 17,
                          color: Colors.white.withValues(alpha: 0.65)),
                    ],
                  ),
                  const SizedBox(width: 12),

                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hab. ${room.number}',
                              style: const TextStyle(color: Colors.white, fontSize: 14,
                                  fontWeight: FontWeight.w400),
                            ),
                            if (room.floor != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Piso ${room.floor}',
                                    style: TextStyle(fontSize: 10,
                                        color: Colors.white.withValues(alpha: 0.50))),
                              ),
                            ],
                            const SizedBox(width: 6),
                            _typeBadge(room.type),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (room.totalBeds == 0)
                          Text('Sin camas registradas',
                              style: TextStyle(fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.30)))
                        else
                          Wrap(
                            spacing: 10,
                            children: [
                              _dot(room.availableBeds, Colors.green, 'libre'),
                              _dot(room.occupiedBeds, const Color(0xFFEF5350), 'ocupada'),
                              if (room.maintenanceBeds > 0)
                                _dot(room.maintenanceBeds, const Color(0xFFFF9800), 'mant.'),
                            ],
                          ),
                      ],
                    ),
                  ),

                  
                  InkWell(
                    onTap: () => _openForm(room: room),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(Icons.edit_outlined, size: 15,
                          color: Colors.white.withValues(alpha: 0.35)),
                    ),
                  ),
                  InkWell(
                    onTap: () => _confirmDelete(room),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(Icons.delete_outline, size: 15,
                          color: AppColors.error.withValues(alpha: 0.40)),
                    ),
                  ),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down, size: 18,
                        color: Colors.white.withValues(alpha: 0.30)),
                  ),
                ],
              ),
            ),
          ),

          
          if (isExpanded) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: room.beds.isEmpty
                  ? Text('Esta habitación no tiene camas registradas.',
                      style: TextStyle(fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.35)))
                  : Wrap(
                      spacing: 8, runSpacing: 6,
                      children: room.beds.map((bed) {
                        final c = _bedColor(bed.status);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: c.withValues(alpha: 0.30)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bed_outlined, size: 12,
                                  color: c.withValues(alpha: 0.75)),
                              const SizedBox(width: 5),
                              Text('Cama ${bed.number}',
                                  style: TextStyle(fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.80))),
                              const SizedBox(width: 4),
                              Text(_bedLabel(bed.status),
                                  style: TextStyle(fontSize: 10,
                                      color: c.withValues(alpha: 0.75))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot(int count, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('$count $label',
              style: TextStyle(fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.55))),
        ],
      );

  Widget _typeBadge(String type) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(type == 'private' ? 'Privada' : 'Compartida',
            style: TextStyle(fontSize: 9,
                color: Colors.white.withValues(alpha: 0.40))),
      );



  Widget _buildStats() {
    final total    = _rooms.length;
    final beds     = _rooms.fold(0, (s, r) => s + r.totalBeds);
    final occupied = _rooms.fold(0, (s, r) => s + r.occupiedBeds);
    final free     = _rooms.fold(0, (s, r) => s + r.availableBeds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _statCard('Hab.',     total.toString(),    Icons.meeting_room_outlined, Colors.white38),
          const SizedBox(width: 8),
          _statCard('Camas',    beds.toString(),     Icons.bed_outlined,          Colors.white38),
          const SizedBox(width: 8),
          _statCard('Ocupadas', occupied.toString(), Icons.person_rounded,         const Color(0xFFEF5350)),
          const SizedBox(width: 8),
          _statCard('Libres',   free.toString(),     Icons.check_circle_outline,  Colors.green),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 13, color: color.withValues(alpha: 0.70)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 17, color: color,
                  fontWeight: FontWeight.w300)),
              Text(label, style: TextStyle(fontSize: 9, letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.30))),
            ],
          ),
        ),
      );

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E0619), Color(0xFF2A0825), Color(0xFF1A051A)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border(bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.07))),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white.withValues(alpha: 0.65), size: 17),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('Habitaciones',
                          style: TextStyle(fontSize: 18,
                              fontWeight: FontWeight.w300, color: Colors.white)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.refresh_rounded,
                            color: Colors.white.withValues(alpha: 0.45), size: 19),
                        onPressed: _load,
                      ),
                    ],
                  ),
                ),

                if (_rooms.isNotEmpty) _buildStats(),

                // Body
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 1.5));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: AppColors.error.withValues(alpha: 0.50), size: 32),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load,
                child: const Text('Reintentar',
                    style: TextStyle(color: Colors.white60))),
          ],
        ),
      );
    }
    if (_rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.meeting_room_outlined,
                color: Colors.white.withValues(alpha: 0.12), size: 48),
            const SizedBox(height: 12),
            Text('No hay habitaciones registradas',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.30),
                    fontSize: 13)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: _rooms.length,
      itemBuilder: (_, i) => _roomCard(_rooms[i]),
    );
  }
}
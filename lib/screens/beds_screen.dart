import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/bed_model.dart';
import 'package:app_geriatrico/data/models/room_model.dart';
import 'package:app_geriatrico/data/repositories/bed_repository.dart';
import 'package:app_geriatrico/data/repositories/room_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';

/// Datos agregados de una cama con info del paciente asignado (si aplica)
class _BedInfo {
  final Bed bed;
  final String? patientName;
  final String? patientGender;
  final String? mobilityStatus;

  const _BedInfo({
    required this.bed,
    this.patientName,
    this.patientGender,
    this.mobilityStatus,
  });
}

class BedsScreen extends StatefulWidget {
  final String token;
  const BedsScreen({super.key, required this.token});

  @override
  State<BedsScreen> createState() => _BedsScreenState();
}

class _BedsScreenState extends State<BedsScreen> {
  late final BedRepository _bedRepo;
  late final RoomRepository _roomRepo;
  late final ApiService _api;

  List<_BedInfo> _beds = [];
  List<Room> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token);
    _bedRepo = BedRepository(_api);
    _roomRepo = RoomRepository(_api);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Beds y rooms son críticos — si fallan mostramos error
      final beds = await _bedRepo.getAll();
      final rooms = await _roomRepo.getAll();

      // Assignments es opcional — si falla seguimos sin info de pacientes
      final Map<int, Map<String, dynamic>> assignmentByBedId = {};
      try {
        final assignmentsResp = await _api.get('/patient-bed-assignments');
        final List rawAssignments = jsonDecode(assignmentsResp.body);
        for (final a in rawAssignments) {
          final bedId = a['bed_id'] as int?;
          final dischargeDate = a['discharge_date'];
          if (bedId != null && dischargeDate == null) {
            assignmentByBedId[bedId] = a;
          }
        }
      } catch (_) {}

      final bedInfos = beds.map((b) {
        final assignment = assignmentByBedId[b.id];
        final patient = assignment?['patient'] as Map<String, dynamic>?;
        return _BedInfo(
          bed: b,
          patientName: patient != null
              ? '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim()
              : null,
          patientGender: patient?['gender'] as String?,
          mobilityStatus: patient?['mobility_status'] as String?,
        );
      }).toList();

      // Sort: occupied first, then by room number
      bedInfos.sort((a, b) {
        if (a.bed.isOccupied && !b.bed.isOccupied) return -1;
        if (!a.bed.isOccupied && b.bed.isOccupied) return 1;
        final roomA = a.bed.room?.number ?? '';
        final roomB = b.bed.room?.number ?? '';
        return roomA.compareTo(roomB);
      });

      if (mounted) {
        setState(() {
          _beds = bedInfos;
          _rooms = rooms;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _showBedForm({_BedInfo? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A0825),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BedFormSheet(
        token: widget.token,
        api: _api,
        rooms: _rooms,
        existing: existing?.bed,
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  void _confirmDelete(_BedInfo info) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3A0B32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        title: const Text('Eliminar cama',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text(
          '¿Eliminar cama ${info.bed.bedNumber}?',
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
                style: TextStyle(color: AppColors.error.withValues(alpha: 0.85))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _bedRepo.delete(info.bed.id);
        _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error.withValues(alpha: 0.85),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

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
                _buildAppBar(),
                _buildStats(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBedForm(),
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withValues(alpha: 0.65), size: 17),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Camas',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 0.3)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.meeting_room_outlined,
                color: Colors.white.withValues(alpha: 0.45), size: 19),
            onPressed: _showRoomsManager,
            tooltip: 'Habitaciones',
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: Colors.white.withValues(alpha: 0.45), size: 19),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  void _showRoomsManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A0825),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RoomsManagerSheet(
        api: _api,
        rooms: _rooms,
        onChanged: _load,
      ),
    );
  }

  Widget _buildStats() {
    final total = _beds.length;
    final occupied = _beds.where((b) => b.bed.isOccupied).length;
    final free = total - occupied;
    final pct = total > 0 ? (occupied / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          _statCard('Total', total.toString(), Icons.bed_outlined, Colors.white38),
          const SizedBox(width: 10),
          _statCard('Ocupadas', occupied.toString(), Icons.person_rounded,
              const Color(0xFFEF5350)),
          const SizedBox(width: 10),
          _statCard('Libres', free.toString(), Icons.bed_outlined, Colors.green),
          const SizedBox(width: 10),
          _statCard('Ocupación', '$pct%', Icons.pie_chart_outline,
              const Color(0xFFFF9800)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color.withValues(alpha: 0.70)),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 18, color: color, fontWeight: FontWeight.w300)),
            Text(label,
                style: TextStyle(
                    fontSize: 9, color: Colors.white.withValues(alpha: 0.30),
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 1.5),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error.withValues(alpha: 0.50), size: 32),
            const SizedBox(height: 10),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_beds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bed_outlined, color: Colors.white.withValues(alpha: 0.12), size: 48),
            const SizedBox(height: 12),
            Text('No hay camas registradas',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.30), fontSize: 13)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      child: Column(
        children: [
          // Header row
          _tableHeader(),
          const SizedBox(height: 4),
          ..._beds.map((b) => _bedRow(b)),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _headerCell('Cama', flex: 1),
          _headerCell('Habitación', flex: 1),
          _headerCell('Paciente', flex: 2),
          _headerCell('Sexo', flex: 1),
          _headerCell('Movilidad', flex: 2),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1.2,
          color: Colors.white.withValues(alpha: 0.28),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _bedRow(_BedInfo info) {
    final isOccupied = info.bed.isOccupied;
    final genderIcon = info.patientGender?.toLowerCase() == 'femenino'
        ? Icons.female
        : info.patientGender?.toLowerCase() == 'masculino'
            ? Icons.male
            : null;
    final genderColor = info.patientGender?.toLowerCase() == 'femenino'
        ? const Color(0xFFE91E9C)
        : const Color(0xFF2196F3);

    final mobilityIcon = info.mobilityStatus == 'ambulatorio'
        ? Icons.directions_walk
        : info.mobilityStatus == 'postrado'
            ? Icons.hotel
            : Icons.accessible;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isOccupied
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOccupied
              ? Colors.white.withValues(alpha: 0.09)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Número de cama
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: info.bed.status == 'occupied'
                          ? const Color(0xFFEF5350).withValues(alpha: 0.75)
                          : info.bed.status == 'maintenance'
                              ? Colors.orange.withValues(alpha: 0.65)
                              : Colors.green.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    info.bed.bedNumber,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: isOccupied ? 0.85 : 0.45),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Habitación
            Expanded(
              flex: 1,
              child: Text(
                info.bed.room?.number ?? '—',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withValues(alpha: 0.55)),
              ),
            ),
            // Paciente
            Expanded(
              flex: 2,
              child: Text(
                info.patientName ?? '—',
                style: TextStyle(
                  fontSize: 12,
                  color: isOccupied
                      ? Colors.white.withValues(alpha: 0.80)
                      : Colors.white.withValues(alpha: 0.20),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Sexo
            Expanded(
              flex: 1,
              child: genderIcon != null
                  ? Icon(genderIcon, size: 15, color: genderColor.withValues(alpha: 0.70))
                  : Text('—',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.20))),
            ),
            // Movilidad
            Expanded(
              flex: 2,
              child: info.mobilityStatus != null
                  ? Row(
                      children: [
                        Icon(mobilityIcon,
                            size: 12, color: Colors.white.withValues(alpha: 0.38)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _mobilityLabel(info.mobilityStatus!),
                            style: TextStyle(
                                fontSize: 11, color: Colors.white.withValues(alpha: 0.50)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text('—',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.20))),
            ),
            // Acciones
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => _showBedForm(existing: info),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(Icons.edit_outlined,
                          size: 15, color: Colors.white.withValues(alpha: 0.30)),
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => _confirmDelete(info),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(Icons.delete_outline,
                          size: 15, color: AppColors.error.withValues(alpha: 0.30)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mobilityLabel(String s) {
    const map = {
      'ambulatorio': 'Ambulatorio',
      'con_ayuda': 'Con ayuda',
      'en_silla': 'Silla ruedas',
      'postrado': 'Postrado',
    };
    return map[s] ?? s;
  }
}

// ─── FORM SHEET ────────────────────────────────────────────────────────────────

class _BedFormSheet extends StatefulWidget {
  final String token;
  final ApiService api;
  final List<Room> rooms;
  final Bed? existing;
  final VoidCallback onSaved;

  const _BedFormSheet({
    required this.token,
    required this.api,
    required this.rooms,
    this.existing,
    required this.onSaved,
  });

  @override
  State<_BedFormSheet> createState() => _BedFormSheetState();
}

class _BedFormSheetState extends State<_BedFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bedNumberCtrl = TextEditingController();
  int? _selectedRoomId;
  String _status = 'available';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _bedNumberCtrl.text = widget.existing!.bedNumber;
      _selectedRoomId = widget.existing!.roomId;
      _status = widget.existing!.status;
    } else if (widget.rooms.isNotEmpty) {
      _selectedRoomId = widget.rooms.first.id;
    }
  }

  @override
  void dispose() {
    _bedNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomId == null) return;
    setState(() => _saving = true);

    final bedRepo = BedRepository(widget.api);
    try {
      final bed = Bed(
        id: widget.existing?.id ?? 0,
        roomId: _selectedRoomId!,
        bedNumber: _bedNumberCtrl.text.trim(),
        status: _status,
      );
      if (widget.existing != null) {
        await bedRepo.update(bed);
      } else {
        await bedRepo.create(bed);
      }
      widget.onSaved();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF2A0825),
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEdit ? 'Editar cama' : 'Nueva cama',
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w300,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Colors.white.withValues(alpha: 0.40), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Container(
                  height: 1, color: Colors.white.withValues(alpha: 0.06),
                  margin: const EdgeInsets.only(bottom: 20)),
              // Número de cama
              TextFormField(
                controller: _bedNumberCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                decoration: InputDecoration(
                  labelText: 'Número de cama',
                  labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40), fontSize: 13),
                  enabledBorder: UnderlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54)),
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.65)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Habitación
              widget.rooms.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.orange.withValues(alpha: 0.65)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No hay habitaciones. Cerrá este formulario y tocá el ícono de habitación en la barra superior para crear una primero.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.50)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<int>(
                      value: _selectedRoomId,
                      dropdownColor: const Color(0xFF2A0825),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Habitación',
                        labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.40),
                            fontSize: 13),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54)),
                      ),
                      items: widget.rooms
                          .map((r) => DropdownMenuItem(
                                value: r.id,
                                child: Text(
                                  'Hab. ${r.number}${r.floor != null ? ' — Piso ${r.floor}' : ''}',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRoomId = v),
                      validator: (v) =>
                          v == null ? 'Seleccioná una habitación' : null,
                    ),
              const SizedBox(height: 16),
              // Estado
              DropdownButtonFormField<String>(
                value: _status,
                dropdownColor: const Color(0xFF2A0825),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Estado',
                  labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40), fontSize: 13),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54)),
                ),
                items: const [
                  DropdownMenuItem(value: 'available',    child: Text('Disponible')),
                  DropdownMenuItem(value: 'occupied',     child: Text('Ocupada')),
                  DropdownMenuItem(value: 'maintenance',  child: Text('Mantenimiento')),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'available'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white54, strokeWidth: 1.5))
                      : Text(isEdit ? 'Guardar cambios' : 'Crear cama',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w400)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ROOMS MANAGER SHEET ───────────────────────────────────────────────────────

class _RoomsManagerSheet extends StatefulWidget {
  final ApiService api;
  final List<Room> rooms;
  final VoidCallback onChanged;

  const _RoomsManagerSheet({
    required this.api,
    required this.rooms,
    required this.onChanged,
  });

  @override
  State<_RoomsManagerSheet> createState() => _RoomsManagerSheetState();
}

class _RoomsManagerSheetState extends State<_RoomsManagerSheet> {
  late final RoomRepository _repo;
  late List<Room> _rooms;
  bool _showForm = false;
  Room? _editing;

  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '1');
  String _type = 'shared';
  String _status = 'available';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo = RoomRepository(widget.api);
    _rooms = List.from(widget.rooms);
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _nameCtrl.dispose();
    _floorCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  void _startCreate() {
    _numberCtrl.clear();
    _nameCtrl.clear();
    _floorCtrl.clear();
    _capacityCtrl.text = '1';
    setState(() {
      _type = 'shared';
      _status = 'available';
      _editing = null;
      _showForm = true;
    });
  }

  void _startEdit(Room r) {
    _numberCtrl.text = r.number;
    _nameCtrl.text = r.name ?? '';
    _floorCtrl.text = r.floor ?? '';
    _capacityCtrl.text = r.capacity.toString();
    setState(() {
      _type = r.type;
      _status = r.status;
      _editing = r;
      _showForm = true;
    });
  }

  void _cancelForm() {
    setState(() => _showForm = false);
    _numberCtrl.clear();
    _nameCtrl.clear();
    _floorCtrl.clear();
    _capacityCtrl.text = '1';
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final room = Room(
        id: _editing?.id ?? 0,
        number: _numberCtrl.text.trim(),
        name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        floor: _floorCtrl.text.trim().isEmpty ? null : _floorCtrl.text.trim(),
        capacity: int.tryParse(_capacityCtrl.text.trim()) ?? 1,
        type: _type,
        status: _status,
      );
      if (_editing != null) {
        await _repo.update(room);
      } else {
        await _repo.create(room);
      }
      final updated = await _repo.getAll();
      setState(() {
        _rooms = updated;
        _showForm = false;
        _saving = false;
      });
      _numberCtrl.clear();
      _nameCtrl.clear();
      _floorCtrl.clear();
      _capacityCtrl.text = '1';
      widget.onChanged();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _deleteRoom(Room r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3A0B32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        title: const Text('Eliminar habitación',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text('Eliminar habitación ${r.number}?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.60), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.50))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar',
                style: TextStyle(color: AppColors.error.withValues(alpha: 0.85))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.delete(r.id);
      final updated = await _repo.getAll();
      setState(() => _rooms = updated);
      widget.onChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54)),
        errorBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: AppColors.error.withValues(alpha: 0.65)),
        ),
        errorStyle: TextStyle(
            color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A0825),
          border:
              Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  Icon(Icons.meeting_room_outlined,
                      size: 17, color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 8),
                  const Text('Habitaciones',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  const Spacer(),
                  if (!_showForm)
                    TextButton.icon(
                      onPressed: _startCreate,
                      icon: Icon(Icons.add_rounded,
                          size: 15,
                          color: Colors.white.withValues(alpha: 0.65)),
                      label: Text('Nueva',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65))),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            // Formulario inline
            if (_showForm)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _editing != null ? 'Editar habitación' : 'Nueva habitación',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 10),
                      // Fila 1: Número + Piso
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _numberCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                              decoration: _inputDeco('Número de habitación *'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _floorCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _inputDeco('Piso'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Fila 2: Nombre + Capacidad
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: _inputDeco('Nombre (opcional)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _capacityCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                if ((int.tryParse(v) ?? 0) < 1) return 'Min. 1';
                                return null;
                              },
                              decoration: _inputDeco('Capacidad *'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Fila 3: Tipo + Estado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _type,
                              dropdownColor: const Color(0xFF2A0825),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _inputDeco('Tipo'),
                              items: const [
                                DropdownMenuItem(value: 'shared', child: Text('Compartida')),
                                DropdownMenuItem(value: 'private', child: Text('Privada')),
                              ],
                              onChanged: (v) => setState(() => _type = v ?? 'shared'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              dropdownColor: const Color(0xFF2A0825),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: _inputDeco('Estado'),
                              items: const [
                                DropdownMenuItem(value: 'available', child: Text('Disponible')),
                                DropdownMenuItem(value: 'maintenance', child: Text('Mantenimiento')),
                                DropdownMenuItem(value: 'inactive', child: Text('Inactiva')),
                              ],
                              onChanged: (v) => setState(() => _status = v ?? 'available'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelForm,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Colors.white.withValues(alpha: 0.50),
                                side: BorderSide(
                                    color:
                                        Colors.white.withValues(alpha: 0.15)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Cancelar',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saving ? null : _saveRoom,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryDark,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          color: Colors.white54,
                                          strokeWidth: 1.5))
                                  : Text(
                                      _editing != null ? 'Guardar' : 'Crear',
                                      style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                      Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                          margin: const EdgeInsets.only(top: 14)),
                    ],
                  ),
                ),
              ),
            // Lista de habitaciones
            Expanded(
              child: _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.meeting_room_outlined,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.10)),
                          const SizedBox(height: 10),
                          Text('No hay habitaciones todavía',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  fontSize: 13)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _startCreate,
                            child: Text('Crear la primera',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.50),
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _rooms.length,
                      itemBuilder: (ctx, i) {
                        final r = _rooms[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.60),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.meeting_room_outlined,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.60)),
                            ),
                            title: Text(
                              'Hab. ${r.number}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400),
                            ),
                            subtitle: r.floor != null
                                ? Text('Piso ${r.floor}',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                        fontSize: 11))
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _startEdit(r),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.edit_outlined,
                                        size: 15,
                                        color: Colors.white
                                            .withValues(alpha: 0.35)),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _deleteRoom(r),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.delete_outline,
                                        size: 15,
                                        color: AppColors.error
                                            .withValues(alpha: 0.35)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/bed_model.dart';
import 'package:app_geriatrico/data/models/patient_model.dart';
import 'package:app_geriatrico/data/models/room_model.dart';
import 'package:app_geriatrico/data/repositories/bed_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_bed_assignment_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_repository.dart';
import 'package:app_geriatrico/data/repositories/room_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';


class _BedInfo {
  final Bed bed;
  final String? patientName;
  final String? patientGender;
  final String? mobilityStatus;
  final int? assignmentId;   
  final int? patientId;      

  const _BedInfo({
    required this.bed,
    this.patientName,
    this.patientGender,
    this.mobilityStatus,
    this.assignmentId,
    this.patientId,
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
  late final PatientRepository _patientRepo;
  late final PatientBedAssignmentRepository _assignmentRepo;
  late final ApiService _api;

  List<_BedInfo> _beds = [];
  List<Room> _rooms = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token);
    _bedRepo       = BedRepository(_api);
    _roomRepo      = RoomRepository(_api);
    _patientRepo   = PatientRepository(_api);
    _assignmentRepo= PatientBedAssignmentRepository(_api);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final beds  = await _bedRepo.getAll();
      final rooms = await _roomRepo.getAll();

      final Map<int, Map<String, dynamic>> assignmentByBedId = {};
      try {
        final res = await _api.get('/patient-bed-assignments');
        final List raw = jsonDecode(res.body);
        for (final a in raw) {
          final bedId      = a['bed_id'] as int?;
          final releasedAt = a['released_at'];
          if (bedId != null && releasedAt == null) {
            assignmentByBedId[bedId] = a;
          }
        }
      } catch (_) {}

      final bedInfos = beds.map((b) {
        final assignment = assignmentByBedId[b.id];
        final patient = assignment?['patient'] as Map<String, dynamic>?;
        return _BedInfo(
          bed:           b,
          assignmentId:  assignment?['id'] as int?,
          patientId:     patient?['id'] as int?,
          patientName:   patient != null
              ? '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim()
              : null,
          patientGender: patient?['gender'] as String?,
          mobilityStatus:patient?['mobility_status'] as String?,
        );
      }).toList();

      bedInfos.sort((a, b) {
        if (a.bed.isOccupied && !b.bed.isOccupied) return -1;
        if (!a.bed.isOccupied && b.bed.isOccupied) return 1;
        return (a.bed.room?.number ?? '').compareTo(b.bed.room?.number ?? '');
      });

      if (mounted) {
        setState(() {
          _beds    = bedInfos;
          _rooms   = rooms;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
      }
    }
  }

 

  Future<void> _showAssignPatientSheet(_BedInfo info) async {
    
    List<Patient> available = [];

    try {
      final all = await _patientRepo.getPatients();
      
      final occupiedPatientIds = _beds
          .where((b) => b.patientId != null)
          .map((b) => b.patientId!)
          .toSet();
      available = all
          .where((p) => p.status == 'active' && !occupiedPatientIds.contains(p.id))
          .toList();
      available.sort((a, b) => a.fullName.compareTo(b.fullName));
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final searchCtrl = TextEditingController();
        List<Patient> filtered = List.from(available);

        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFF2A0825),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.bed_outlined, size: 16,
                            color: Colors.green.withValues(alpha: 0.70)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Asignar paciente',
                              style: const TextStyle(color: Colors.white, fontSize: 15,
                                  fontWeight: FontWeight.w300)),
                          Text('Cama ${info.bed.bedNumber}'
                              '${info.bed.room != null ? ' · Hab. ${info.bed.room!.number}' : ''}',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.40), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Buscador
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (q) {
                      setModalState(() {
                        filtered = available
                            .where((p) => p.fullName.toLowerCase().contains(q.toLowerCase())
                                || p.dni.contains(q))
                            .toList();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o DNI...',
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                      prefixIcon: Icon(Icons.search,
                          color: Colors.white.withValues(alpha: 0.30), size: 18),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.person_off_outlined,
                            color: Colors.white.withValues(alpha: 0.12), size: 40),
                        const SizedBox(height: 12),
                        Text('No hay pacientes activos sin cama asignada',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
                      ],
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final isFemale = p.gender.toLowerCase() == 'female';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primaryDark.withValues(alpha: 0.70),
                              child: Text(
                                p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            title: Text(p.fullName,
                                style: const TextStyle(color: Colors.white, fontSize: 13,
                                    fontWeight: FontWeight.w400)),
                            subtitle: Text('DNI: ${p.dni}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isFemale ? Icons.female : Icons.male,
                                  size: 14,
                                  color: (isFemale
                                      ? const Color(0xFFE91E9C)
                                      : const Color(0xFF2196F3))
                                      .withValues(alpha: 0.60),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    await _doAssign(info, p);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A1240),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Asignar',
                                      style: TextStyle(fontSize: 12)),
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
      },
    );
  }

  Future<void> _doAssign(_BedInfo info, Patient patient) async {
    try {
      await _assignmentRepo.assign(patient.id, info.bed.id);
      _showSnack('${patient.firstName} asignado/a a cama ${info.bed.bedNumber}',
          success: true);
      _load();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  

  Future<void> _releaseBed(_BedInfo info) async {
    if (info.assignmentId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3A0B32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        title: const Text('¿Dar de alta al paciente?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text(
          '${info.patientName ?? 'El paciente'} será dado/a de alta de la cama '
          '${info.bed.bedNumber} y la cama quedará disponible.',
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
            child: Text('Dar de alta',
                style: TextStyle(color: AppColors.error.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _assignmentRepo.release(info.assignmentId!);
      _showSnack('Cama ${info.bed.bedNumber} liberada', success: true);
      _load();
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showBedForm({_BedInfo? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A0825),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BedFormSheet(
        token: widget.token,
        api: _api,
        rooms: _rooms,
        existing: existing?.bed,
        onSaved: () { Navigator.pop(context); _load(); },
      ),
    );
  }

  Future<void> _confirmDelete(_BedInfo info) async {
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
        content: Text('¿Eliminar cama ${info.bed.bedNumber}?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 14)),
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
        if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: success
          ? Colors.green.withValues(alpha: 0.85)
          : AppColors.error.withValues(alpha: 0.85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300,
                  color: Colors.white, letterSpacing: 0.3)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _RoomsManagerSheet(api: _api, rooms: _rooms, onChanged: _load),
    );
  }

  Widget _buildStats() {
    final total    = _beds.length;
    final occupied = _beds.where((b) => b.bed.isOccupied).length;
    final free     = total - occupied;
    final pct      = total > 0 ? (occupied / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          _statCard('Total',    total.toString(),    Icons.bed_outlined,      Colors.white38),
          const SizedBox(width: 10),
          _statCard('Ocupadas', occupied.toString(), Icons.person_rounded,    const Color(0xFFEF5350)),
          const SizedBox(width: 10),
          _statCard('Libres',   free.toString(),     Icons.bed_outlined,      Colors.green),
          const SizedBox(width: 10),
          _statCard('Ocupación','$pct%',             Icons.pie_chart_outline, const Color(0xFFFF9800)),
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
            Text(value, style: TextStyle(fontSize: 18, color: color,
                fontWeight: FontWeight.w300)),
            Text(label, style: TextStyle(fontSize: 9,
                color: Colors.white.withValues(alpha: 0.30), letterSpacing: 0.5)),
          ],
        ),
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
            Icon(Icons.error_outline, color: AppColors.error.withValues(alpha: 0.50), size: 32),
            const SizedBox(height: 10),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
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
                style: TextStyle(color: Colors.white.withValues(alpha: 0.30), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      children: [
        _tableHeader(),
        const SizedBox(height: 4),
        ..._beds.map((b) => _bedRow(b)),
      ],
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
          _headerCell('Cama',       flex: 1),
          _headerCell('Habitación', flex: 1),
          _headerCell('Paciente',   flex: 2),
          _headerCell('Movilidad',  flex: 2),
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 9, letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.28), fontWeight: FontWeight.w500)),
      );

  Widget _bedRow(_BedInfo info) {
    final isOccupied = info.bed.isOccupied;
    final statusColor = info.bed.status == 'occupied'
        ? const Color(0xFFEF5350)
        : info.bed.status == 'maintenance'
            ? Colors.orange
            : Colors.green;

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
           
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor.withValues(alpha: 0.75)),
                  ),
                  const SizedBox(width: 7),
                  Text(info.bed.bedNumber,
                      style: TextStyle(fontSize: 13,
                          color: Colors.white.withValues(alpha: isOccupied ? 0.85 : 0.45),
                          fontWeight: FontWeight.w400)),
                ],
              ),
            ),
            
            Expanded(
              flex: 1,
              child: Text(info.bed.room?.number ?? '—',
                  style: TextStyle(fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55))),
            ),
            
            Expanded(
              flex: 2,
              child: Text(
                info.patientName ?? (info.bed.status == 'maintenance' ? 'Mantenimiento' : '—'),
                style: TextStyle(fontSize: 12,
                    color: isOccupied
                        ? Colors.white.withValues(alpha: 0.80)
                        : Colors.white.withValues(alpha: 0.22)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            Expanded(
              flex: 2,
              child: info.mobilityStatus != null
                  ? Row(
                      children: [
                        Icon(_mobilityIcon(info.mobilityStatus!),
                            size: 12, color: Colors.white.withValues(alpha: 0.35)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(_mobilityLabel(info.mobilityStatus!),
                              style: TextStyle(fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.50)),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    )
                  : Text('—',
                      style: TextStyle(fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.20))),
            ),
           
            SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  
                  if (!isOccupied && info.bed.status == 'available')
                    _actionBtn(
                      icon: Icons.person_add_outlined,
                      color: Colors.green,
                      tooltip: 'Asignar paciente',
                      onTap: () => _showAssignPatientSheet(info),
                    ),
                  
                  if (isOccupied && info.assignmentId != null)
                    _actionBtn(
                      icon: Icons.logout,
                      color: AppColors.error,
                      tooltip: 'Dar de alta',
                      onTap: () => _releaseBed(info),
                    ),
                  
                  _actionBtn(
                    icon: Icons.edit_outlined,
                    color: Colors.white,
                    tooltip: 'Editar',
                    onTap: () => _showBedForm(existing: info),
                  ),
                 
                  if (!isOccupied)
                    _actionBtn(
                      icon: Icons.delete_outline,
                      color: AppColors.error,
                      tooltip: 'Eliminar',
                      onTap: () => _confirmDelete(info),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: color.withValues(alpha: 0.45)),
        ),
      ),
    );
  }

  IconData _mobilityIcon(String s) {
    switch (s) {
      case 'normal':      return Icons.directions_walk;
      case 'wheelchair':  return Icons.accessible;
      case 'bedridden':   return Icons.hotel;
      default:            return Icons.directions_walk;
    }
  }

  String _mobilityLabel(String s) {
    const map = {
      'normal':     'Normal',
      'reduced':    'Reducida',
      'wheelchair': 'Silla ruedas',
      'bedridden':  'Postrado',
    };
    return map[s] ?? s;
  }
}



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
        id:        widget.existing?.id ?? 0,
        roomId:    _selectedRoomId!,
        bedNumber: _bedNumberCtrl.text.trim(),
        status:    _status,
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

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 13),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
        focusedBorder:
            const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65))),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF2A0825),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(isEdit ? 'Editar cama' : 'Nueva cama',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Colors.white.withValues(alpha: 0.40), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06),
                  margin: const EdgeInsets.only(bottom: 20)),
              TextFormField(
                controller: _bedNumberCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                decoration: _deco('Número de cama'),
              ),
              const SizedBox(height: 16),
              widget.rooms.isEmpty
                  ? Text('No hay habitaciones disponibles.',
                      style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.65), fontSize: 12))
                  : DropdownButtonFormField<int>(
                      initialValue: _selectedRoomId,
                      dropdownColor: const Color(0xFF2A0825),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _deco('Habitación'),
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
                      validator: (v) => v == null ? 'Seleccioná una habitación' : null,
                    ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: const Color(0xFF2A0825),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _deco('Estado'),
                items: const [
                  DropdownMenuItem(value: 'available',   child: Text('Disponible')),
                  DropdownMenuItem(value: 'occupied',    child: Text('Ocupada')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Mantenimiento')),
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
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white54, strokeWidth: 1.5))
                      : Text(isEdit ? 'Guardar cambios' : 'Crear cama',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _RoomsManagerSheet extends StatefulWidget {
  final ApiService api;
  final List<Room> rooms;
  final VoidCallback onChanged;

  const _RoomsManagerSheet({required this.api, required this.rooms, required this.onChanged});

  @override
  State<_RoomsManagerSheet> createState() => _RoomsManagerSheetState();
}

class _RoomsManagerSheetState extends State<_RoomsManagerSheet> {
  late final RoomRepository _repo;
  late List<Room> _rooms;
  bool _showForm = false;
  Room? _editing;

  final _formKey   = GlobalKey<FormState>();
  final _numberCtrl  = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _floorCtrl   = TextEditingController();
  final _capacityCtrl= TextEditingController(text: '1');
  String _type = 'shared';
  String _status = 'available';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _repo  = RoomRepository(widget.api);
    _rooms = List.from(widget.rooms);
  }

  @override
  void dispose() {
    _numberCtrl.dispose(); _nameCtrl.dispose();
    _floorCtrl.dispose(); _capacityCtrl.dispose();
    super.dispose();
  }

  void _startCreate() {
    _numberCtrl.clear(); _nameCtrl.clear();
    _floorCtrl.clear(); _capacityCtrl.text = '1';
    setState(() { _type = 'shared'; _status = 'available'; _editing = null; _showForm = true; });
  }

  void _startEdit(Room r) {
    _numberCtrl.text = r.number; _nameCtrl.text = r.name ?? '';
    _floorCtrl.text = r.floor ?? ''; _capacityCtrl.text = r.capacity.toString();
    setState(() { _type = r.type; _status = r.status; _editing = r; _showForm = true; });
  }

  void _cancelForm() {
    setState(() => _showForm = false);
    _numberCtrl.clear(); _nameCtrl.clear();
    _floorCtrl.clear(); _capacityCtrl.text = '1';
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
        type: _type, status: _status,
      );
      if (_editing != null) { await _repo.update(room); } else { await _repo.create(room); }
      final updated = await _repo.getAll();
      setState(() { _rooms = updated; _showForm = false; _saving = false; });
      _cancelForm();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
        title: const Text('Eliminar habitación',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text('¿Eliminar habitación ${r.number}?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.50)))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text('Eliminar',
                  style: TextStyle(color: AppColors.error.withValues(alpha: 0.85)))),
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
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65))),
        errorStyle: TextStyle(color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
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
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
              child: Row(
                children: [
                  Icon(Icons.meeting_room_outlined, size: 17,
                      color: Colors.white.withValues(alpha: 0.45)),
                  const SizedBox(width: 8),
                  const Text('Habitaciones',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300,
                          color: Colors.white)),
                  const Spacer(),
                  if (!_showForm)
                    TextButton.icon(
                      onPressed: _startCreate,
                      icon: Icon(Icons.add_rounded, size: 15,
                          color: Colors.white.withValues(alpha: 0.65)),
                      label: Text('Nueva',
                          style: TextStyle(fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.65))),
                    ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            if (_showForm)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_editing != null ? 'Editar habitación' : 'Nueva habitación',
                          style: TextStyle(fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.35), letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2,
                              child: TextFormField(
                                controller: _numberCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                                decoration: _inputDeco('Número de habitación *'),
                              )),
                          const SizedBox(width: 12),
                          Expanded(flex: 1,
                              child: TextFormField(
                                controller: _floorCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: _inputDeco('Piso'),
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2,
                              child: TextFormField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: _inputDeco('Nombre (opcional)'),
                              )),
                          const SizedBox(width: 12),
                          Expanded(flex: 1,
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
                              )),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _type,
                                dropdownColor: const Color(0xFF2A0825),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: _inputDeco('Tipo'),
                                items: const [
                                  DropdownMenuItem(value: 'shared',  child: Text('Compartida')),
                                  DropdownMenuItem(value: 'private', child: Text('Privada')),
                                ],
                                onChanged: (v) => setState(() => _type = v ?? 'shared'),
                              )),
                          const SizedBox(width: 12),
                          Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _status,
                                dropdownColor: const Color(0xFF2A0825),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: _inputDeco('Estado'),
                                items: const [
                                  DropdownMenuItem(value: 'available',    child: Text('Disponible')),
                                  DropdownMenuItem(value: 'maintenance',  child: Text('Mantenimiento')),
                                  DropdownMenuItem(value: 'inactive',     child: Text('Inactiva')),
                                ],
                                onChanged: (v) => setState(() => _status = v ?? 'available'),
                              )),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelForm,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white.withValues(alpha: 0.50),
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
                              )),
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
                                    ? const SizedBox(width: 16, height: 16,
                                        child: CircularProgressIndicator(
                                            color: Colors.white54, strokeWidth: 1.5))
                                    : Text(_editing != null ? 'Guardar' : 'Crear',
                                        style: const TextStyle(fontSize: 13)),
                              )),
                        ],
                      ),
                      Container(height: 1, color: Colors.white.withValues(alpha: 0.06),
                          margin: const EdgeInsets.only(top: 14)),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 40,
                              color: Colors.white.withValues(alpha: 0.10)),
                          const SizedBox(height: 10),
                          Text('No hay habitaciones todavía',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.30), fontSize: 13)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _startCreate,
                            child: Text('Crear la primera',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.50), fontSize: 12)),
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
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withValues(alpha: 0.60),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.meeting_room_outlined, size: 16,
                                  color: Colors.white.withValues(alpha: 0.60)),
                            ),
                            title: Text('Hab. ${r.number}',
                                style: const TextStyle(color: Colors.white, fontSize: 13,
                                    fontWeight: FontWeight.w400)),
                            subtitle: r.floor != null
                                ? Text('Piso ${r.floor}',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.35),
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
                                    child: Icon(Icons.edit_outlined, size: 15,
                                        color: Colors.white.withValues(alpha: 0.35)),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _deleteRoom(r),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.delete_outline, size: 15,
                                        color: AppColors.error.withValues(alpha: 0.35)),
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
import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/patient_model.dart';
import 'package:app_geriatrico/data/repositories/patient_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';
import 'package:app_geriatrico/screens/patient_detail_screen.dart';
import 'package:app_geriatrico/screens/patient_create_screen.dart';

class PatientsScreen extends StatefulWidget {
  final String token;
  const PatientsScreen({super.key, required this.token});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  late final PatientRepository _repo;
  List<Patient> _patients = [];
  List<Patient> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = PatientRepository(
      ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token),
    );
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _repo.getPatients();
      setState(() {
        _patients = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _patients.where((p) {
        return p.fullName.toLowerCase().contains(q) ||
            p.dni.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _openDetail(Patient p) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(patient: p, token: widget.token),
      ),
    );
    if (updated == true) _load();
  }

  void _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePatientScreen(token: widget.token),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildSearchBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.primaryDark,
        elevation: 4,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _background() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E0619), Color(0xFF2A0825), Color(0xFF1A051A)],
          ),
        ),
      );

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white.withValues(alpha: 0.65), size: 17),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Pacientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: Colors.white.withValues(alpha: 0.45), size: 19),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filter,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o DNI...',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.30), fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.30), size: 18),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.30), size: 16),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filter('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.10)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.25)),
          ),
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
            Icon(Icons.error_outline_rounded,
                color: AppColors.error.withValues(alpha: 0.60), size: 36),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50), fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text('Reintentar',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13)),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.elderly_outlined,
                color: Colors.white.withValues(alpha: 0.15), size: 48),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'No hay pacientes registrados'
                  : 'Sin resultados para "${_searchCtrl.text}"',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) => _patientCard(_filtered[i]),
    );
  }

  Widget _patientCard(Patient p) {
    final genderIcon =
        p.gender.toLowerCase() == 'female' ? Icons.female : Icons.male;  // FIX
    final genderColor = p.gender.toLowerCase() == 'female'
        ? const Color(0xFFE91E9C)
        : const Color(0xFF2196F3);  // FIX

    final statusColor = p.status == 'active'
        ? Colors.green
        : p.status == 'deceased'
            ? Colors.grey
            : AppColors.error;  // FIX

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar con inicial y género
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        AppColors.primaryDark.withValues(alpha: 0.85),
                    child: Text(
                      p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: genderColor.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF2A0825), width: 1.5),
                      ),
                      child: Icon(genderIcon,
                          size: 10, color: genderColor.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'DNI: ${p.dni}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.38)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      p.status == 'active'
                          ? 'Activo'
                          : p.status == 'deceased'
                              ? 'Fallecido'
                              : 'Inactivo',
                      style: TextStyle(
                          fontSize: 10,
                          color: statusColor.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        p.mobilityStatus == 'ambulatorio'
                            ? Icons.directions_walk
                            : Icons.accessible,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.30),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        p.mobilityStatus,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.30)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.20), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
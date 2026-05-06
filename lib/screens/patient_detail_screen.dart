import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/patient_model.dart';
import 'package:app_geriatrico/data/models/patient_contact_model.dart';
import 'package:app_geriatrico/data/models/patient_diagnosis_model.dart';
import 'package:app_geriatrico/data/models/patient_evolution_model.dart';
import 'package:app_geriatrico/data/models/medical_prescription_model.dart';
import 'package:app_geriatrico/data/models/medical_study_model.dart';
import 'package:app_geriatrico/data/repositories/patient_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_contact_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_diagnosis_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_evolution_repository.dart';
import 'package:app_geriatrico/data/repositories/medical_prescription_repository.dart';
import 'package:app_geriatrico/data/repositories/medical_study_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  final String token;

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.token,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  late final PatientRepository _patientRepo;
  late final PatientContactRepository _contactRepo;
  late final PatientDiagnosisRepository _diagnosisRepo;
  late final PatientEvolutionRepository _evolutionRepo;
  late final MedicalPrescriptionRepository _prescriptionRepo;
  late final MedicalStudyRepository _studyRepo;

  late Patient _patient;
  late TabController _tabController;

  bool _isEditing = false;
  bool _saving = false;

  // Personal data controllers
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _dni;
  late TextEditingController _birthDate;
  late TextEditingController _admissionDate;
  late TextEditingController _emergencyPhone;
  late TextEditingController _notes;
  late String _gender;
  late String _bloodType;
  late String _mobilityStatus;
  late String _dependencyLevel;
  late String _status;

  // Clinical data
  List<PatientContact> _contacts = [];
  List<PatientDiagnosis> _diagnoses = [];
  List<PatientEvolution> _evolutions = [];
  List<MedicalPrescription> _prescriptions = [];
  List<MedicalStudy> _studies = [];

  bool _loadingClinical = false;

  // Evolution filters
  String? _filterSpecialty;
  String? _filterDateFrom;
  String? _filterDateTo;

  final _formKey = GlobalKey<FormState>();

  static const _genders = ['female', 'male', 'other'];  // FIX: valores del backend
  static const _mobilityOptions = ['normal', 'reduced', 'wheelchair', 'bedridden'];  // FIX: valores del backend
  static const _dependencyOptions = ['low', 'medium', 'high'];  // FIX: valores del backend
  static const _statusOptions = ['active', 'inactive', 'deceased'];  // FIX: 'discharged' no existe, es 'deceased'
  static const _bloodTypes = ['', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2 && !_loadingClinical) {
        _loadClinicalData();
      }
    });

    final api = ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token);
    _patientRepo = PatientRepository(api);
    _contactRepo = PatientContactRepository(api);
    _diagnosisRepo = PatientDiagnosisRepository(api);
    _evolutionRepo = PatientEvolutionRepository(api);
    _prescriptionRepo = MedicalPrescriptionRepository(api);
    _studyRepo = MedicalStudyRepository(api);

    _initControllers();
    _loadContacts();
  }

  void _initControllers() {
    _firstName = TextEditingController(text: _patient.firstName);
    _lastName = TextEditingController(text: _patient.lastName);
    _dni = TextEditingController(text: _patient.dni);
    _birthDate = TextEditingController(text: _patient.birthDate ?? '');
    _admissionDate = TextEditingController(text: _patient.admissionDate ?? '');
    _emergencyPhone = TextEditingController(text: _patient.emergencyPhone ?? '');
    _notes = TextEditingController(text: _patient.notes ?? '');
    _gender = _patient.gender;  // OK: viene del backend
    _bloodType = _patient.bloodType ?? '';
    _mobilityStatus = _patient.mobilityStatus;
    _dependencyLevel = _patient.dependencyLevel;
    _status = _patient.status;
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [
      _firstName, _lastName, _dni, _birthDate,
      _admissionDate, _emergencyPhone, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _contactRepo.getByPatient(_patient.id);
      if (mounted) setState(() => _contacts = contacts);
    } catch (_) {}
  }

  Future<void> _loadClinicalData() async {
    if (_loadingClinical) return;
    setState(() => _loadingClinical = true);
    try {
      final results = await Future.wait([
        _diagnosisRepo.getByPatient(_patient.id),
        _evolutionRepo.getByPatient(_patient.id),
        _prescriptionRepo.getByPatient(_patient.id),
        _studyRepo.getByPatient(_patient.id),
      ]);
      if (mounted) {
        setState(() {
          _diagnoses = results[0] as List<PatientDiagnosis>;
          _evolutions = (results[1] as List<PatientEvolution>)
            ..sort((a, b) {
              final da = DateTime.tryParse(a.recordedAt ?? '') ?? DateTime(0);
              final db = DateTime.tryParse(b.recordedAt ?? '') ?? DateTime(0);
              return db.compareTo(da); // newest first
            });
          _prescriptions = results[2] as List<MedicalPrescription>;
          _studies = results[3] as List<MedicalStudy>;
          _loadingClinical = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClinical = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final updated = Patient(
        id: _patient.id,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        dni: _dni.text.trim(),
        birthDate: _birthDate.text.isEmpty ? null : _birthDate.text,
        gender: _gender,
        bloodType: _bloodType.isEmpty ? null : _bloodType,
        admissionDate: _admissionDate.text.isEmpty ? null : _admissionDate.text,
        mobilityStatus: _mobilityStatus,
        dependencyLevel: _dependencyLevel,
        emergencyPhone: _emergencyPhone.text.trim().isEmpty ? null : _emergencyPhone.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        status: _status,
        contacts: _patient.contacts,
      );
      await _patientRepo.updatePatient(updated);
      setState(() {
        _patient = updated;
        _isEditing = false;
        _saving = false;
      });
      if (mounted) _showSnack('Paciente actualizado', success: true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3A0B32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        title: const Text('Eliminar paciente',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text(
          '¿Estás seguro que querés eliminar a ${_patient.fullName}?',
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
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await _patientRepo.deletePatient(_patient.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
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

  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime initial = DateTime.now();
    if (ctrl.text.isNotEmpty) {
      try {
        initial = DateTime.parse(ctrl.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4A1240),
            surface: Color(0xFF2A0825),
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF2A0825)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => ctrl.text = picked.toIso8601String().split('T').first);
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
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPersonalTab(),
                        _buildContactTab(),
                        _buildClinicalTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_saving)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 1.5),
              ),
            ),
        ],
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
            onPressed: () => Navigator.pop(context, false),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'Editar paciente' : _patient.fullName,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w300, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: Colors.white.withValues(alpha: 0.55), size: 19),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initControllers();
                });
              },
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withValues(alpha: 0.50)),
              child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
            ),
            TextButton(
              onPressed: _save,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Guardar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final genderIcon = _patient.gender.toLowerCase() == 'female'
        ? Icons.female
        : Icons.male;  // FIX
    final genderColor = _patient.gender.toLowerCase() == 'female'
        ? const Color(0xFFE91E9C)
        : const Color(0xFF2196F3);  // FIX

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryDark.withValues(alpha: 0.85),
                child: Text(
                  _patient.firstName.isNotEmpty
                      ? _patient.firstName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: genderColor.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2A0825), width: 1.5),
                  ),
                  child: Icon(genderIcon, size: 11, color: genderColor),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patient.fullName,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.white, fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 2),
                Text(
                  'DNI: ${_patient.dni}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.38)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusBadge(_patient.status),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _patient.mobilityStatus == 'ambulatorio'
                        ? Icons.directions_walk
                        : Icons.accessible,
                    size: 11,
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    _labelFor(_patient.mobilityStatus),
                    style: TextStyle(
                        fontSize: 10, color: Colors.white.withValues(alpha: 0.30)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'active'
        ? Colors.green
        : status == 'deceased'
            ? Colors.grey
            : AppColors.error;  // FIX
    final label =
        status == 'active' ? 'Activo' : status == 'deceased' ? 'Fallecido' : 'Inactivo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color.withValues(alpha: 0.85), fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white.withValues(alpha: 0.03),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primaryLight,
        indicatorWeight: 2,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.38),
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
        tabs: const [
          Tab(text: 'Datos personales'),
          Tab(text: 'Familiar a cargo'),
          Tab(text: 'Historia clínica'),
        ],
      ),
    );
  }

  // ─── TAB 1: DATOS PERSONALES ───────────────────────────────────────────────

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _buildSection('Identificación', [
                _fieldRow('Nombre', _firstName, required: true),
                _fieldRow('Apellido', _lastName, required: true),
                _fieldRow('DNI', _dni, required: true, keyboardType: TextInputType.number),
                _fieldRow('Fecha de nacimiento', _birthDate, isDate: true),
                _dropdownRow('Género', _gender, _genders, (v) => setState(() => _gender = v!)),
                _dropdownRow('Grupo sanguíneo', _bloodType, _bloodTypes,
                    (v) => setState(() => _bloodType = v ?? ''),
                    isLast: true),
              ]),
              const SizedBox(height: 14),
              _buildSection('Internación', [
                _fieldRow('Fecha de ingreso', _admissionDate, isDate: true),
                _dropdownRow('Movilidad', _mobilityStatus, _mobilityOptions,
                    (v) => setState(() => _mobilityStatus = v!)),
                _dropdownRow('Dependencia', _dependencyLevel, _dependencyOptions,
                    (v) => setState(() => _dependencyLevel = v!)),
                _dropdownRow('Estado', _status, _statusOptions,
                    (v) => setState(() => _status = v!),
                    isLast: true),
              ]),
              const SizedBox(height: 14),
              _buildSection('Contacto y notas', [
                _fieldRow('Tel. de emergencia', _emergencyPhone,
                    keyboardType: TextInputType.phone),
                _fieldRow('Notas', _notes, maxLines: 3, isLast: true),
              ]),
              if (!_isEditing) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error.withValues(alpha: 0.70)),
                    label: Text('Eliminar paciente',
                        style: TextStyle(
                            color: AppColors.error.withValues(alpha: 0.70), fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.25)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TAB 2: FAMILIAR A CARGO ───────────────────────────────────────────────

  Widget _buildContactTab() {
    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline,
                color: Colors.white.withValues(alpha: 0.15), size: 44),
            const SizedBox(height: 12),
            Text('Sin contactos registrados',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (ctx, i) => _contactCard(_contacts[i]),
    );
  }

  Widget _contactCard(PatientContact c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryDark.withValues(alpha: 0.70),
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${c.name} ${c.lastName ?? ''}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)),
                      if (c.relationship != null)
                        Text(c.relationship!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          _infoRow('DNI', c.dni ?? '—'),
          _infoRow('Teléfono', c.phone),
          if (c.email != null) _infoRow('Email', c.email!),
          if (c.address != null) _infoRow('Dirección', c.address!, isLast: true),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: value == '—'
                        ? Colors.white.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.75)),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  // ─── TAB 3: HISTORIA CLÍNICA ───────────────────────────────────────────────

  Widget _buildClinicalTab() {
    if (_loadingClinical) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 1.5),
      );
    }
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white.withValues(alpha: 0.02),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFF9C4E8A),
              indicatorWeight: 1.5,
              labelColor: Colors.white.withValues(alpha: 0.85),
              unselectedLabelColor: Colors.white.withValues(alpha: 0.30),
              labelStyle: const TextStyle(fontSize: 11, letterSpacing: 0.3),
              tabs: [
                _clinicalTabItem(Icons.biotech_outlined, 'Diagnósticos', _diagnoses.length),
                _clinicalTabItem(Icons.history_edu_outlined, 'Evoluciones', _evolutions.length),
                _clinicalTabItem(Icons.medication_outlined, 'Medicamentos', _prescriptions.length),
                _clinicalTabItem(Icons.science_outlined, 'Estudios', _studies.length),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDiagnosisTab(),
                _buildEvolutionTab(),
                _buildPrescriptionTab(),
                _buildStudiesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Tab _clinicalTabItem(IconData icon, String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(count.toString(),
                  style: const TextStyle(fontSize: 9, color: Colors.white60)),
            ),
          ],
        ],
      ),
    );
  }

  // DIAGNÓSTICOS
  Widget _buildDiagnosisTab() {
    if (_diagnoses.isEmpty) return _emptyState('Sin diagnósticos registrados', Icons.biotech_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _diagnoses.length,
      itemBuilder: (ctx, i) {
        final d = _diagnoses[i];
        return _clinicalCard(
          icon: Icons.biotech_outlined,
          accentColor: const Color(0xFF7C4DFF),
          title: d.diagnosis,
          subtitle: d.notes,
          date: d.diagnosedAt,
          professional: d.professional != null
              ? '${d.professional!.name} ${d.professional!.lastName ?? ''}'
              : null,
        );
      },
    );
  }

  // EVOLUCIONES
  Widget _buildEvolutionTab() {
    final filtered = _evolutions.where((e) {
      if (_filterSpecialty != null && _filterSpecialty!.isNotEmpty) {
        final specs = e.professional?.specialties.map((s) => s.name) ?? [];
        if (!specs.contains(_filterSpecialty)) return false;
      }
      if (_filterDateFrom != null && _filterDateFrom!.isNotEmpty) {
        final from = DateTime.tryParse(_filterDateFrom!);
        final ev = DateTime.tryParse(e.recordedAt ?? '');
        if (from != null && ev != null && ev.isBefore(from)) return false;
      }
      if (_filterDateTo != null && _filterDateTo!.isNotEmpty) {
        final to = DateTime.tryParse(_filterDateTo!);
        final ev = DateTime.tryParse(e.recordedAt ?? '');
        if (to != null && ev != null && ev.isAfter(to)) return false;
      }
      return true;
    }).toList();

    // Collect all specialties from evolutions
    final allSpecialties = <String>{};
    for (final ev in _evolutions) {
      for (final sp in ev.professional?.specialties ?? []) {
        allSpecialties.add(sp.name);
      }
    }

    return Column(
      children: [
        // Filter bar
        if (allSpecialties.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Todas', null, allSpecialties),
                  ...allSpecialties.map((s) => _filterChip(s, s, allSpecialties)),
                ],
              ),
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState('Sin evoluciones registradas', Icons.history_edu_outlined)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final ev = filtered[i];
                    final specs = ev.professional?.specialties
                            .map((s) => s.name)
                            .join(', ') ?? '';
                    return _evolutionCard(ev, specs);
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value, Set<String> all) {
    final isSelected = _filterSpecialty == value;
    return GestureDetector(
      onTap: () => setState(() => _filterSpecialty = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDark.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: isSelected ? 0.90 : 0.45))),
      ),
    );
  }

  Widget _evolutionCard(PatientEvolution ev, String specialties) {
    final date = _formatDate(ev.recordedAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.30)),
                  ),
                  child: Text(date,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF64B5F6), fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                if (specialties.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(specialties,
                        style: TextStyle(
                            fontSize: 10, color: Colors.white.withValues(alpha: 0.65))),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(ev.evolution,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.80),
                    height: 1.5)),
          ),
          if (ev.professional != null) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 12, color: Colors.white.withValues(alpha: 0.28)),
                  const SizedBox(width: 5),
                  Text(
                    '${ev.professional!.name} ${ev.professional!.lastName ?? ''}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.40)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // MEDICAMENTOS
  Widget _buildPrescriptionTab() {
    if (_prescriptions.isEmpty) {
      return _emptyState('Sin medicamentos recetados', Icons.medication_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _prescriptions.length,
      itemBuilder: (ctx, i) {
        final p = _prescriptions[i];
        return _prescriptionCard(p);
      },
    );
  }

  Widget _prescriptionCard(MedicalPrescription p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medication_outlined,
                      size: 18, color: Colors.green.withValues(alpha: 0.70)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.medication?.name ?? 'Medicamento',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white, fontWeight: FontWeight.w400),
                      ),
                      if (p.medication?.presentation != null)
                        Text(p.medication!.presentation!,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.35))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            const SizedBox(height: 10),
            Row(
              children: [
                _pillBadge(Icons.scale_outlined, 'Dosis: ${p.dose}'),
                const SizedBox(width: 8),
                _pillBadge(Icons.schedule_outlined, p.frequency),
              ],
            ),
            if (p.route != null) ...[
              const SizedBox(height: 6),
              _pillBadge(Icons.route_outlined, 'Vía: ${p.route}'),
            ],
            if (p.instructions != null && p.instructions!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(p.instructions!,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.40),
                      fontStyle: FontStyle.italic)),
            ],
            if (p.professional != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 11, color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(width: 4),
                  Text(
                    '${p.professional!.name} ${p.professional!.lastName ?? ''}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pillBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.45)),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
        ],
      ),
    );
  }

  // ESTUDIOS
  Widget _buildStudiesTab() {
    if (_studies.isEmpty) return _emptyState('Sin estudios registrados', Icons.science_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _studies.length,
      itemBuilder: (ctx, i) {
        final s = _studies[i];
        return _clinicalCard(
          icon: Icons.science_outlined,
          accentColor: const Color(0xFFFF6F00),
          title: s.studyType,
          subtitle: s.conclusion,
          date: s.performedAt,
          professional: s.professional != null
              ? '${s.professional!.name} ${s.professional!.lastName ?? ''}'
              : null,
        );
      },
    );
  }

  Widget _clinicalCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    String? subtitle,
    String? date,
    String? professional,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: accentColor.withValues(alpha: 0.75)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white, fontWeight: FontWeight.w400)),
                ),
                if (date != null)
                  Text(_formatDate(date),
                      style: TextStyle(
                          fontSize: 10, color: Colors.white.withValues(alpha: 0.35))),
              ],
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.60), height: 1.5)),
            ],
            if (professional != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 11, color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(width: 4),
                  Text(professional,
                      style: TextStyle(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.10), size: 44),
          const SizedBox(height: 10),
          Text(msg,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30), fontSize: 13)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadClinicalData,
            icon: Icon(Icons.refresh, size: 14, color: Colors.white.withValues(alpha: 0.35)),
            label: Text('Recargar',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ─── SHARED FORM HELPERS ───────────────────────────────────────────────────

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.30),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          ...rows,
        ],
      ),
    );
  }

  Widget _fieldRow(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    bool isDate = false,
    bool isLast = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: _isEditing
          ? TextFormField(
              controller: ctrl,
              keyboardType: isDate ? TextInputType.datetime : keyboardType,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              readOnly: isDate,
              onTap: isDate ? () => _pickDate(ctrl) : null,
              validator: required
                  ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
                  : null,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                suffixIcon: isDate
                    ? Icon(Icons.calendar_today_outlined,
                        size: 15, color: Colors.white.withValues(alpha: 0.30))
                    : null,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
                errorBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65)),
                ),
                errorStyle: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
              ),
            )
          : Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
                ),
                Expanded(
                  child: Text(
                    ctrl.text.isEmpty ? '—' : ctrl.text,
                    style: TextStyle(
                        fontSize: 13,
                        color: ctrl.text.isEmpty
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.80)),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dropdownRow(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged, {
    bool isLast = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: _isEditing ? 4 : 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: _isEditing
          ? DropdownButtonFormField<String>(
              value: value.isEmpty ? null : value,
              dropdownColor: const Color(0xFF2A0825),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
              ),
              items: options
                  .map((o) => DropdownMenuItem(
                        value: o.isEmpty ? null : o,
                        child: Text(o.isEmpty ? '—' : _labelFor(o),
                            style: TextStyle(
                                color: Colors.white.withValues(
                                    alpha: o.isEmpty ? 0.35 : 0.85),
                                fontSize: 13)),
                      ))
                  .toList(),
              onChanged: onChanged,
            )
          : Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
                ),
                Expanded(
                  child: Text(
                    value.isEmpty ? '—' : _labelFor(value),
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.80)),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  // FIX: etiquetas actualizadas para valores del backend (inglés → español)
  String _labelFor(String o) {
    const labels = {
      'female':     'Femenino',
      'male':       'Masculino',
      'other':      'Otro',
      'normal':     'Normal',
      'reduced':    'Reducida',
      'wheelchair': 'Silla de ruedas',
      'bedridden':  'Postrado',
      'low':        'Dependencia baja',
      'medium':     'Dependencia media',
      'high':       'Dependencia alta',
      'active':     'Activo',
      'inactive':   'Inactivo',
      'deceased':   'Fallecido',
    };
    return labels[o] ?? o;
  }
}
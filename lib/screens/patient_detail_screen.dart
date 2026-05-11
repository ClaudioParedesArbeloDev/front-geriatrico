// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/bed_model.dart';
import 'package:app_geriatrico/data/models/employee_model.dart';
import 'package:app_geriatrico/data/models/patient_model.dart';
import 'package:app_geriatrico/data/models/patient_bed_assignment_model.dart';
import 'package:app_geriatrico/data/models/patient_contact_model.dart';
import 'package:app_geriatrico/data/models/patient_diagnosis_model.dart';
import 'package:app_geriatrico/data/models/patient_evolution_model.dart';
import 'package:app_geriatrico/data/models/medical_prescription_model.dart';
import 'package:app_geriatrico/data/models/medical_study_model.dart';
import 'package:app_geriatrico/data/repositories/bed_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_bed_assignment_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_contact_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_diagnosis_repository.dart';
import 'package:app_geriatrico/data/repositories/patient_evolution_repository.dart';
import 'package:app_geriatrico/data/repositories/medical_prescription_repository.dart';
import 'package:app_geriatrico/data/repositories/medical_study_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';
import 'package:app_geriatrico/data/repositories/medication_repository.dart';
import 'package:app_geriatrico/data/models/medication_model.dart';
import 'package:app_geriatrico/data/models/cie10_model.dart';
import 'package:app_geriatrico/data/repositories/cie10_repository.dart';
import 'package:app_geriatrico/data/models/allergy_model.dart';
import 'package:app_geriatrico/data/repositories/allergy_repository.dart';

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
  late final ApiService _api;
  late final PatientRepository _patientRepo;
  late final PatientContactRepository _contactRepo;
  late final PatientDiagnosisRepository _diagnosisRepo;
  late final PatientEvolutionRepository _evolutionRepo;
  late final MedicalPrescriptionRepository _prescriptionRepo;
  late final MedicalStudyRepository _studyRepo;
  late final BedRepository _bedRepo;
  late final PatientBedAssignmentRepository _assignmentRepo;
  late final AllergyRepository _allergyRepo;

  late Patient _patient;
  late TabController _tabController;

 
  Employee? _currentUser;


  PatientBedAssignment? _currentAssignment;
  List<Bed> _availableBeds = [];
  bool _loadingBeds = false;

  bool _isEditing = false;
  bool _saving = false;

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

  List<PatientContact> _contacts = [];
  List<PatientDiagnosis> _diagnoses = [];
  List<PatientEvolution> _evolutions = [];
  List<MedicalPrescription> _prescriptions = [];
  List<MedicalStudy> _studies = [];
  List<Allergy> _allergies = [];

  bool _loadingClinical = false;

  String? _filterSpecialty;

  final _formKey = GlobalKey<FormState>();

  static const _genders         = ['female', 'male', 'other'];
  static const _mobilityOptions = ['normal', 'reduced', 'wheelchair', 'bedridden'];
  static const _dependencyOptions = ['low', 'medium', 'high'];
  static const _statusOptions   = ['active', 'inactive', 'deceased'];
  static const _bloodTypes      = ['', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];


  static const _allEvolutionTypes = ['medical', 'nursing', 'kinesiology', 'nutrition', 'social', 'general'];
  static const _roleToTypes = {
    'admin':         ['medical', 'nursing', 'kinesiology', 'nutrition', 'social', 'general'],
    'doctor':        ['medical', 'general'],
    'nurse':         ['nursing', 'general'],
    'kinesiologist': ['kinesiology', 'general'],
    'nutritionist':  ['nutrition', 'general'],
    'social_worker': ['social', 'general'],
  };

  List<String> get _allowedEvolutionTypes {
    if (_currentUser == null) return _allEvolutionTypes;
    for (final role in _currentUser!.roles) {
      final types = _roleToTypes[role.name];
      if (types != null) return types;
    }
    return ['general'];
  }

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

    _api = ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token);
    _patientRepo      = PatientRepository(_api);
    _contactRepo      = PatientContactRepository(_api);
    _diagnosisRepo    = PatientDiagnosisRepository(_api);
    _evolutionRepo    = PatientEvolutionRepository(_api);
    _prescriptionRepo = MedicalPrescriptionRepository(_api);
    _studyRepo        = MedicalStudyRepository(_api);
    _bedRepo          = BedRepository(_api);
    _assignmentRepo   = PatientBedAssignmentRepository(_api);
    _allergyRepo      = AllergyRepository(_api);

    _initControllers();
    _loadCurrentUser();
    _loadContacts();
    _currentAssignment = _patient.currentBedAssignment;
  }

  void _initControllers() {
    _firstName     = TextEditingController(text: _patient.firstName);
    _lastName      = TextEditingController(text: _patient.lastName);
    _dni           = TextEditingController(text: _patient.dni);
    _birthDate     = TextEditingController(text: _patient.birthDate ?? '');
    _admissionDate = TextEditingController(text: _patient.admissionDate ?? '');
    _emergencyPhone= TextEditingController(text: _patient.emergencyPhone ?? '');
    _notes         = TextEditingController(text: _patient.notes ?? '');
    _gender           = _patient.gender;
    _bloodType        = _patient.bloodType ?? '';
    _mobilityStatus   = _patient.mobilityStatus;
    _dependencyLevel  = _patient.dependencyLevel;
    _status           = _patient.status;
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [_firstName, _lastName, _dni, _birthDate,
                     _admissionDate, _emergencyPhone, _notes]) {
      c.dispose();
    }
    super.dispose();
  }


  Future<void> _loadCurrentUser() async {
    try {
      final res = await _api.get('/user');
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (mounted) setState(() => _currentUser = Employee.fromJson(json));
    } catch (e) {
      debugPrint('No se pudo cargar usuario actual: $e');
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _contactRepo.getByPatient(_patient.id);
      if (mounted) setState(() => _contacts = contacts);
    } catch (_) {}
  }

  Future<void> _loadAvailableBeds() async {
    setState(() => _loadingBeds = true);
    try {
      final all = await _bedRepo.getAll();
      if (mounted) {
        setState(() {
          _availableBeds = all.where((b) => b.status == 'available').toList();
          _loadingBeds = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBeds = false);
    }
  }

  Future<void> _releaseBed() async {
    if (_currentAssignment == null) return;
    final confirm = await _confirmDialog(
      '¿Dar de alta de la cama?',
      'Se liberará la cama ${_currentAssignment!.bed?.bedNumber ?? ''} y quedará disponible.',
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await _assignmentRepo.release(_currentAssignment!.id);
      final updated = await _patientRepo.getPatient(_patient.id);
      if (mounted) {
        setState(() {
          _patient = updated;
          _currentAssignment = null;
          _saving = false;
        });
        _showSnack('Cama liberada correctamente', success: true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showAssignBedSheet() async {
    await _loadAvailableBeds();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    Icon(Icons.bed_outlined,
                        color: Colors.white.withValues(alpha: 0.55), size: 18),
                    const SizedBox(width: 10),
                    Text('Asignar cama a ${_patient.firstName}',
                        style: const TextStyle(color: Colors.white, fontSize: 15,
                            fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
              if (_loadingBeds)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 1.5),
                )
              else if (_availableBeds.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.bed_outlined,
                          color: Colors.white.withValues(alpha: 0.15), size: 40),
                      const SizedBox(height: 12),
                      Text('No hay camas disponibles',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 13)),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.5),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _availableBeds.length,
                    itemBuilder: (_, i) {
                      final bed = _availableBeds[i];
                      final roomLabel = bed.room != null
                          ? 'Hab. ${bed.room!.number}'
                              '${bed.room!.floor != null ? ' · Piso ${bed.room!.floor}' : ''}'
                          : 'Sin habitación';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.bed_outlined, size: 20,
                                color: Colors.green.withValues(alpha: 0.70)),
                          ),
                          title: Text('Cama ${bed.bedNumber}',
                              style: const TextStyle(color: Colors.white, fontSize: 14,
                                  fontWeight: FontWeight.w400)),
                          subtitle: Text(roomLabel,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.40),
                                  fontSize: 11)),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              setState(() => _saving = true);
                              try {
                                final assignment = await _assignmentRepo.assign(
                                    _patient.id, bed.id);
                                final updated = await _patientRepo.getPatient(_patient.id);
                                if (mounted) {
                                  setState(() {
                                    _patient = updated;
                                    _currentAssignment = assignment;
                                    _saving = false;
                                  });
                                  _showSnack('Cama ${bed.bedNumber} asignada', success: true);
                                }
                              } catch (e) {
                                setState(() => _saving = false);
                                if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A1240),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Asignar', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
        _allergyRepo.getByPatient(_patient.id),
      ]);
      if (mounted) {
        setState(() {
          _diagnoses    = results[0] as List<PatientDiagnosis>;
          _evolutions   = (results[1] as List<PatientEvolution>)
            ..sort((a, b) {
              final da = DateTime.tryParse(a.recordedAt ?? '') ?? DateTime(0);
              final db = DateTime.tryParse(b.recordedAt ?? '') ?? DateTime(0);
              return db.compareTo(da);
            });
          _prescriptions = results[2] as List<MedicalPrescription>;
          _studies       = results[3] as List<MedicalStudy>;
          _allergies     = results[4] as List<Allergy>;
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
        firstName:      _firstName.text.trim(),
        lastName:       _lastName.text.trim(),
        dni:            _dni.text.trim(),
        birthDate:      _birthDate.text.isEmpty ? null : _birthDate.text,
        gender:         _gender,
        bloodType:      _bloodType.isEmpty ? null : _bloodType,
        admissionDate:  _admissionDate.text.isEmpty ? null : _admissionDate.text,
        mobilityStatus: _mobilityStatus,
        dependencyLevel:_dependencyLevel,
        emergencyPhone: _emergencyPhone.text.trim().isEmpty ? null : _emergencyPhone.text.trim(),
        notes:          _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        status:         _status,
        contacts:       _patient.contacts,
      );
      await _patientRepo.updatePatient(updated);
      setState(() { _patient = updated; _isEditing = false; _saving = false; });
      if (mounted) _showSnack('Paciente actualizado', success: true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete() async {
    final confirm = await _confirmDialog(
      '¿Eliminar paciente?',
      '¿Estás seguro que querés eliminar a ${_patient.fullName}?',
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



  void _showAddContactSheet({PatientContact? editing}) {
    final isEdit = editing != null;
    final name         = TextEditingController(text: editing?.name ?? '');
    final lastName     = TextEditingController(text: editing?.lastName ?? '');
    final dni          = TextEditingController(text: editing?.dni ?? '');
    final relationship = TextEditingController(text: editing?.relationship ?? '');
    final phone        = TextEditingController(text: editing?.phone ?? '');
    final email        = TextEditingController(text: editing?.email ?? '');
    final address      = TextEditingController(text: editing?.address ?? '');
    bool isPrimary     = editing?.isPrimary ?? false;
    bool saving        = false;
    final formKey      = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFF2A0825),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Icon(isEdit ? Icons.edit_outlined : Icons.person_add_outlined,
                          color: Colors.white.withValues(alpha: 0.55), size: 18),
                      const SizedBox(width: 10),
                      Text(isEdit ? 'Editar familiar' : 'Agregar familiar a cargo',
                          style: const TextStyle(color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.w300)),
                      const Spacer(),
                      if (saving)
                        const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                      else
                        TextButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            setModalState(() => saving = true);
                            try {
                              final data = {
                                'patient_id':   _patient.id,
                                'name':         name.text.trim(),
                                'last_name':    lastName.text.trim().isEmpty ? null : lastName.text.trim(),
                                'dni':          dni.text.trim().isEmpty ? null : dni.text.trim(),
                                'relationship': relationship.text.trim().isEmpty ? null : relationship.text.trim(),
                                'phone':        phone.text.trim(),
                                'email':        email.text.trim().isEmpty ? null : email.text.trim(),
                                'address':      address.text.trim().isEmpty ? null : address.text.trim(),
                                'is_primary':   isPrimary,
                              };
                              if (isEdit) {
                                await _contactRepo.update(editing.id, data);
                              } else {
                                await _contactRepo.create(data);
                              }
                              if (mounted) {
                                // ignore: duplicate_ignore
                                // ignore: use_build_context_synchronously
                                Navigator.pop(ctx);
                                await _loadContacts();
                                _showSnack(isEdit ? 'Familiar actualizado' : 'Familiar agregado', success: true);
                              }
                            } catch (e) {
                              setModalState(() => saving = false);
                              _showSnack(e.toString().replaceFirst('Exception: ', ''));
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                // Formulario
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          _sheetRow('Nombre *', name, required: true),
                          _sheetRow('Apellido', lastName),
                          _sheetRow('DNI', dni, keyboard: TextInputType.number),
                          _sheetRow('Parentesco', relationship,
                              hint: 'Ej: Hijo/a, Cónyuge, Hermano/a'),
                          _sheetRow('Teléfono *', phone,
                              required: true, keyboard: TextInputType.phone),
                          _sheetRow('Email', email, keyboard: TextInputType.emailAddress),
                          _sheetRow('Dirección', address),
                          const SizedBox(height: 12),
                          // Toggle responsable principal
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_border_rounded, size: 16,
                                    color: isPrimary
                                        ? Colors.amber.withValues(alpha: 0.75)
                                        : Colors.white.withValues(alpha: 0.30)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Responsable principal',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.80),
                                              fontSize: 13)),
                                      Text('Contacto de emergencia prioritario',
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.30),
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isPrimary,
                                  onChanged: (v) => setModalState(() => isPrimary = v),
                                  activeThumbColor: Colors.amber,
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteContact(PatientContact c) async {
    final confirm = await _confirmDialog(
      '¿Eliminar familiar?',
      '¿Querés eliminar a ${c.fullName} de los contactos?',
    );
    if (confirm != true) return;
    try {
      await _contactRepo.delete(c.id);
      await _loadContacts();
      if (mounted) _showSnack('Familiar eliminado', success: true);
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _setPrimaryContact(PatientContact c) async {
    try {
      await _contactRepo.setPrimary(c.id);
      await _loadContacts();
      if (mounted) _showSnack('${c.name} marcado como responsable principal', success: true);
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }



  void _showAddEvolutionSheet() {
    final evolutionCtrl = TextEditingController();
    final allowed       = _allowedEvolutionTypes;
    String selectedType = allowed.first;
    bool saving         = false;
    final formKey       = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      Icon(Icons.history_edu_outlined,
                          color: Colors.white.withValues(alpha: 0.55), size: 18),
                      const SizedBox(width: 10),
                      const Text('Nueva evolución',
                          style: TextStyle(color: Colors.white, fontSize: 16,
                              fontWeight: FontWeight.w300)),
                      const Spacer(),
                      if (saving)
                        const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                      else
                        TextButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (_currentUser == null) {
                              _showSnack('No se pudo identificar al profesional');
                              return;
                            }
                            setModalState(() => saving = true);
                            try {
                              await _evolutionRepo.create({
                                'patient_id':  _patient.id,
                                'user_id':     _currentUser!.id,
                                'type':        selectedType,
                                'evolution':   evolutionCtrl.text.trim(),
                                'recorded_at': DateTime.now().toIso8601String(),
                              });
                              if (mounted) {
                                Navigator.pop(ctx);
                               
                                setState(() => _loadingClinical = false);
                                await _loadClinicalData();
                                _showSnack('Evolución registrada', success: true);
                              }
                            } catch (e) {
                              setModalState(() => saving = false);
                              _showSnack(e.toString().replaceFirst('Exception: ', ''));
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
                Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.65),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selector de tipo
                          Text('Tipo de evolución',
                              style: TextStyle(fontSize: 11, letterSpacing: 1,
                                  color: Colors.white.withValues(alpha: 0.35))),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allowed.map((type) {
                              final sel = selectedType == type;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedType = type),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? AppColors.primaryDark.withValues(alpha: 0.85)
                                        : Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: sel
                                          ? Colors.white.withValues(alpha: 0.22)
                                          : Colors.white.withValues(alpha: 0.10),
                                    ),
                                  ),
                                  child: Text(_evolutionTypeLabel(type),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(alpha: sel ? 0.90 : 0.45))),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          // Texto de evolución
                          Text('Evolución *',
                              style: TextStyle(fontSize: 11, letterSpacing: 1,
                                  color: Colors.white.withValues(alpha: 0.35))),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: evolutionCtrl,
                            maxLines: 6,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'El texto de evolución es requerido' : null,
                            decoration: InputDecoration(
                              hintText: 'Describí el estado del paciente, observaciones, indicaciones...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.20), fontSize: 13),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.04),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.white38)),
                              errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65))),
                              contentPadding: const EdgeInsets.all(14),
                            ),
                          ),
                          // Info del profesional
                          if (_currentUser != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline, size: 13,
                                      color: Colors.white.withValues(alpha: 0.30)),
                                  const SizedBox(width: 8),
                                  Text('Registrado por: ${_currentUser!.name} ${_currentUser!.lastName ?? ''}',
                                      style: TextStyle(fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.40))),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }



  String _evolutionTypeLabel(String type) {
    const labels = {
      'medical':    'Médica',
      'nursing':    'Enfermería',
      'kinesiology':'Kinesiología',
      'nutrition':  'Nutrición',
      'social':     'Social',
      'general':    'General',
    };
    return labels[type] ?? type;
  }

  Future<bool?> _confirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF3A0B32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text(message,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.60), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.50))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar',
                style: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }


  void _showAddDiagnosisSheet({PatientDiagnosis? editing}) {
    final isEdit = editing != null;

    final diagCtrl  = TextEditingController(text: editing?.diagnosis ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    final dateCtrl  = TextEditingController();

  
    final cie10SearchCtrl = TextEditingController();
    Cie10Code? selectedCie10;
    List<Cie10Code> cie10Results = [];
    bool loadingCie10 = false;

 
    if (isEdit && editing.cie10Code != null) {
      selectedCie10 = Cie10Code(
        id: 0,
        code: editing.cie10Code!,
        description: editing.cie10Label ?? editing.cie10Code!,
      );
    }

   
    if (isEdit && editing.diagnosedAt != null) {
      dateCtrl.text = _formatDate(editing.diagnosedAt);
    }

    bool saving    = false;
    final formKey  = GlobalKey<FormState>();
    final cie10Repo = Cie10Repository(_api);

    
    Future<void> searchCie10(String q, StateSetter set) async {
      if (q.length < 2) { set(() => cie10Results = []); return; }
      set(() => loadingCie10 = true);
      try {
        final results = await cie10Repo.search(q);
        set(() { cie10Results = results; loadingCie10 = false; });
      } catch (_) {
        set(() => loadingCie10 = false);
      }
    }

   
    Future<void> createCie10(StateSetter set) async {
      final codeCtrl = TextEditingController(text: cie10SearchCtrl.text.toUpperCase());
      final descCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: const Color(0xFF3A0B32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          title: const Text('Nuevo código CIE-10',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Código (Ej: K59.0)',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Descripción / Patología',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancelar',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45))),
            ),
            TextButton(
              onPressed: () async {
                if (codeCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                try {
                  final created = await cie10Repo.create(
                      codeCtrl.text.trim(), descCtrl.text.trim());
                  if (context.mounted) {
                    Navigator.pop(dCtx);
                    set(() {
                      selectedCie10 = created;
                      cie10Results  = [];
                      cie10SearchCtrl.clear();
                    });
                  }
                } catch (e) {
                  _showSnack(e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Crear',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    
    Future<void> editCie10(Cie10Code c, StateSetter set) async {
      final codeCtrl = TextEditingController(text: c.code);
      final descCtrl = TextEditingController(text: c.description);
      await showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: const Color(0xFF3A0B32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          title: Text('Editar ${c.code}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 16)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Código',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Descripción',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancelar',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45))),
            ),
            TextButton(
              onPressed: () async {
                try {
                  
                  if (c.id > 0) {
                    final updated = await cie10Repo.update(c.id,
                        code: codeCtrl.text.trim(),
                        description: descCtrl.text.trim());
                    set(() => selectedCie10 = updated);
                  } else {
                    set(() => selectedCie10 = Cie10Code(
                        id: 0,
                        code: codeCtrl.text.trim().toUpperCase(),
                        description: descCtrl.text.trim()));
                  }
                  if (context.mounted) Navigator.pop(dCtx);
                } catch (e) {
                  _showSnack(e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Guardar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

   
    Future<void> deleteCie10(Cie10Code c, StateSetter set) async {
      final confirm = await _confirmDialog(
        '¿Eliminar código ${c.code}?',
        'Se eliminará del catálogo. Los diagnósticos existentes no se verán afectados.',
      );
      if (confirm != true) return;
      try {
        if (c.id > 0) await cie10Repo.delete(c.id);
        set(() { selectedCie10 = null; cie10SearchCtrl.clear(); });
      } catch (e) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(children: [
                  Icon(Icons.biotech_outlined,
                      color: Colors.white.withValues(alpha: 0.55), size: 18),
                  const SizedBox(width: 10),
                  Text(isEdit ? 'Editar diagnóstico' : 'Nuevo diagnóstico',
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w300)),
                  const Spacer(),
                  if (saving)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                  else
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        setModalState(() => saving = true);
                        try {
                          final data = {
                            'patient_id':  _patient.id,
                            if (_currentUser != null) 'user_id': _currentUser!.id,
                            'diagnosis':   diagCtrl.text.trim(),
                            if (selectedCie10 != null) 'cie10_code': selectedCie10!.code,
                            if (selectedCie10 != null) 'cie10_label': selectedCie10!.description,
                            if (notesCtrl.text.trim().isNotEmpty)
                              'notes': notesCtrl.text.trim(),
                            if (dateCtrl.text.isNotEmpty)
                              'diagnosed_at': _displayToIso(dateCtrl.text),
                          };
                          if (isEdit) {
                            await _diagnosisRepo.update(editing.id, data);
                          } else {
                            await _diagnosisRepo.create(data);
                          }
                          if (mounted) {
                            Navigator.pop(ctx);
                            await _loadClinicalData();
                            _showSnack(
                              isEdit ? 'Diagnóstico actualizado' : 'Diagnóstico registrado',
                              success: true,
                            );
                          }
                        } catch (e) {
                          setModalState(() => saving = false);
                          _showSnack(e.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                    ),
                ]),
              ),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                   
                      _sheetRow('Diagnóstico *', diagCtrl, required: true),

                     
                      Text('Código CIE-10',
                          style: TextStyle(fontSize: 11, letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.35))),
                      const SizedBox(height: 8),

                      if (selectedCie10 != null) ...[
                       
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF7C4DFF).withValues(alpha: 0.30)),
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C4DFF).withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(selectedCie10!.code,
                                  style: const TextStyle(
                                      color: Color(0xFFBB99FF),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(selectedCie10!.description,
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.80),
                                      fontSize: 13)),
                            ),
                            
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 16,
                                  color: Colors.white.withValues(alpha: 0.45)),
                              onPressed: () => editCie10(selectedCie10!, setModalState),
                              tooltip: 'Editar código',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                         
                            IconButton(
                              icon: Icon(Icons.delete_outline, size: 16,
                                  color: AppColors.error.withValues(alpha: 0.60)),
                              onPressed: () => deleteCie10(selectedCie10!, setModalState),
                              tooltip: 'Eliminar del catálogo',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ]),
                        ),
                       
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: Icon(Icons.swap_horiz, size: 14,
                                color: Colors.white.withValues(alpha: 0.40)),
                            label: Text('Cambiar código',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.40),
                                    fontSize: 12)),
                            onPressed: () => setModalState(() {
                              selectedCie10 = null;
                              cie10Results  = [];
                              cie10SearchCtrl.clear();
                            }),
                          ),
                        ),
                      ] else ...[
                       
                        TextField(
                          controller: cie10SearchCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Buscar por código o patología...',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                            prefixIcon: loadingCie10
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 1.2, color: Colors.white38)))
                                : Icon(Icons.search, size: 18,
                                    color: Colors.white.withValues(alpha: 0.35)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18))),
                            focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54)),
                          ),
                          onChanged: (v) => searchCie10(v, setModalState),
                        ),

                        
                        if (cie10Results.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A0B32),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                            ),
                            child: Column(
                              children: cie10Results.map((c) => ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(c.code,
                                      style: const TextStyle(
                                          color: Color(0xFFBB99FF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600)),
                                ),
                                title: Text(c.description,
                                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                                onTap: () => setModalState(() {
                                  selectedCie10 = c;
                                  cie10Results  = [];
                                  cie10SearchCtrl.clear();
                                }),
                              )).toList(),
                            ),
                          ),

                        
                        if (cie10SearchCtrl.text.length >= 2 && cie10Results.isEmpty && !loadingCie10)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GestureDetector(
                              onTap: () => createCie10(setModalState),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.10),
                                      style: BorderStyle.solid),
                                ),
                                child: Row(children: [
                                  Icon(Icons.add_circle_outline, size: 16,
                                      color: Colors.white.withValues(alpha: 0.50)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Crear código "${cie10SearchCtrl.text.toUpperCase()}"',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.60),
                                        fontSize: 13),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 16),

                     
                      _sheetRow('Notas / Observaciones', notesCtrl),

                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextFormField(
                          controller: dateCtrl,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Fecha del diagnóstico',
                            labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                            suffixIcon: Icon(Icons.calendar_today_outlined, size: 15,
                                color: Colors.white.withValues(alpha: 0.30)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18))),
                            focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54)),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                              builder: (ctx, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF4A1240),
                                      surface: Color(0xFF2A0825)),
                                  dialogTheme: const DialogThemeData(
                                      backgroundColor: Color(0xFF2A0825)),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setModalState(() {
                                dateCtrl.text =
                                    '${picked.day.toString().padLeft(2, '0')}/'
                                    '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                              });
                            }
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  void _showAddPrescriptionSheet() {
    final doseCtrl         = TextEditingController();
    final freqCtrl         = TextEditingController();
    final routeCtrl        = TextEditingController();
    final instructionsCtrl = TextEditingController();
    final searchCtrl       = TextEditingController();
    final startCtrl        = TextEditingController();
    final endCtrl          = TextEditingController();
    final searchFocus      = FocusNode();

    List<Medication> meds   = [];
    Medication? selectedMed;
    bool loadingMeds        = false;
    bool saving             = false;
    final formKey           = GlobalKey<FormState>();
    final repo              = MedicationRepository(_api);

    Future<void> searchMeds(String q, StateSetter set) async {
      if (q.trim().length < 2) {
        set(() => meds = []);
        return;
      }
      set(() => loadingMeds = true);
      try {
        final results = await repo.getAll(search: q.trim());
        set(() { meds = results; loadingMeds = false; });
      } catch (_) {
        set(() => loadingMeds = false);
      }
      Future.delayed(Duration.zero, () {
        if (!searchFocus.hasFocus) searchFocus.requestFocus();
      });
    }

    Future<void> showCreateDialog(StateSetter set) async {
      final nameCtrl  = TextEditingController(text: searchCtrl.text.trim());
      final labCtrl   = TextEditingController();
      final presCtrl  = TextEditingController();
      final princCtrl = TextEditingController();

      InputDecoration dialogInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.20))),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54)),
      );

      await showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
          backgroundColor: const Color(0xFF3A0B32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          title: const Text('Nuevo medicamento',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: dialogInput('Nombre comercial *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: princCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: dialogInput('Principio activo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: dialogInput('Laboratorio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: presCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: dialogInput('Presentación'),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx),
              child: Text('Cancelar',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45))),
            ),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  final created = await repo.create({
                    'nombre_comercial': nameCtrl.text.trim(),
                    if (princCtrl.text.trim().isNotEmpty)
                      'principio_activo': princCtrl.text.trim(),
                    if (labCtrl.text.trim().isNotEmpty)
                      'laboratorio': labCtrl.text.trim(),
                    if (presCtrl.text.trim().isNotEmpty)
                      'presentacion': presCtrl.text.trim(),
                    'porcentaje': 70,
                  });
                  if (context.mounted) {
                    Navigator.pop(dCtx);
                    set(() {
                      selectedMed = created;
                      meds        = [];
                      searchCtrl.clear();
                    });
                    _showSnack('Medicamento creado', success: true);
                  }
                } catch (e) {
                  _showSnack(e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Crear',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    Future<void> pickDate(TextEditingController ctrl, StateSetter set) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        builder: (ctx, child) => Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
                primary: Color(0xFF4A1240), surface: Color(0xFF2A0825)),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF2A0825)),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        set(() {
          ctrl.text =
              '${picked.day.toString().padLeft(2, '0')}/'
              '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final hasQuery  = searchCtrl.text.trim().length >= 2;
          final noResults = !loadingMeds && meds.isEmpty && hasQuery;

          return Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFF2A0825),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(children: [
                  Icon(Icons.medication_outlined,
                      color: Colors.white.withValues(alpha: 0.55), size: 18),
                  const SizedBox(width: 10),
                  const Text('Nueva prescripción',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w300)),
                  const Spacer(),
                  if (saving)
                    const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                  else
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.white),
                      child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        if (selectedMed == null) {
                          _showSnack('Seleccioná un medicamento');
                          return;
                        }
                        setModalState(() => saving = true);
                        try {
                          await _prescriptionRepo.create({
                            'patient_id':    _patient.id,
                            'medication_id': selectedMed!.id,
                            if (_currentUser != null) 'user_id': _currentUser!.id,
                            'dose':      doseCtrl.text.trim(),
                            'frequency': freqCtrl.text.trim(),
                            if (routeCtrl.text.trim().isNotEmpty)
                              'route': routeCtrl.text.trim(),
                            if (instructionsCtrl.text.trim().isNotEmpty)
                              'instructions': instructionsCtrl.text.trim(),
                            if (startCtrl.text.isNotEmpty)
                              'start_date': _displayToIso(startCtrl.text),
                            if (endCtrl.text.isNotEmpty)
                              'end_date': _displayToIso(endCtrl.text),
                            'is_active': true,
                          });
                          if (mounted) {
                            searchFocus.dispose();
                            Navigator.pop(ctx);
                            await _loadClinicalData();
                            _showSnack('Prescripción registrada', success: true);
                          }
                        } catch (e) {
                          setModalState(() => saving = false);
                          _showSnack(e.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                    ),
                ]),
              ),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.72),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                     
                      Text('Medicamento *',
                          style: TextStyle(fontSize: 11, letterSpacing: 0.8,
                              color: Colors.white.withValues(alpha: 0.35))),
                      const SizedBox(height: 8),

                      if (selectedMed != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                          ),
                          child: Row(children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green.withValues(alpha: 0.70), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(selectedMed!.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  if (selectedMed!.presentation != null)
                                    Text(selectedMed!.presentation!,
                                        style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.40),
                                            fontSize: 11)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setModalState(() {
                                selectedMed = null;
                                searchCtrl.clear();
                                meds = [];
                              }),
                              child: Icon(Icons.close, size: 16,
                                  color: Colors.white.withValues(alpha: 0.40)),
                            ),
                          ]),
                        ),
                      ] else ...[
                      
                        TextField(
                          controller: searchCtrl,
                          focusNode: searchFocus,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre, principio activo...',
                            hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
                            prefixIcon: loadingMeds
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 1.2, color: Colors.white38)))
                                : Icon(Icons.search, size: 18,
                                    color: Colors.white.withValues(alpha: 0.35)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18))),
                            focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54)),
                          ),
                          onChanged: (v) => searchMeds(v, setModalState),
                        ),

                        
                        if (meds.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A0B32),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10)),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: meds.length,
                              itemBuilder: (_, i) {
                                final med = meds[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(med.name,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 13)),
                                  subtitle: med.subtitle.isNotEmpty
                                      ? Text(med.subtitle,
                                          style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.40),
                                              fontSize: 11))
                                      : null,
                                  onTap: () => setModalState(() {
                                    selectedMed = med;
                                    meds = [];
                                    searchCtrl.clear();
                                  }),
                                );
                              },
                            ),
                          ),
                        ],

                        
                        if (noResults) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => showCreateDialog(setModalState),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12)),
                              ),
                              child: Row(children: [
                                Icon(Icons.add_circle_outline,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.55)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Crear "${searchCtrl.text.trim()}"',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.70),
                                        fontSize: 13),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),
                      _sheetRow('Dosis *', doseCtrl, required: true, hint: 'Ej: 500mg'),
                      _sheetRow('Frecuencia *', freqCtrl, required: true, hint: 'Ej: Cada 8 horas'),
                      _sheetRow('Vía de administración', routeCtrl, hint: 'Ej: Oral, Subcutánea'),
                      _sheetRow('Instrucciones', instructionsCtrl, hint: 'Indicaciones adicionales'),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: startCtrl,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Fecha de inicio',
                            labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                            suffixIcon: Icon(Icons.calendar_today_outlined, size: 15,
                                color: Colors.white.withValues(alpha: 0.30)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18))),
                            focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54)),
                          ),
                          onTap: () => pickDate(startCtrl, setModalState),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextFormField(
                          controller: endCtrl,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Fecha de fin (opcional)',
                            labelStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                            suffixIcon: Icon(Icons.calendar_today_outlined, size: 15,
                                color: Colors.white.withValues(alpha: 0.30)),
                            enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.18))),
                            focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white54)),
                          ),
                          onTap: () => pickDate(endCtrl, setModalState),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    ).whenComplete(() => searchFocus.dispose());
  }

  
  void _showAddStudySheet() {
    final typeCtrl       = TextEditingController();
    final conclusionCtrl = TextEditingController();
    final dateCtrl       = TextEditingController();
    bool saving          = false;
    final formKey        = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF2A0825),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(children: [
                Icon(Icons.science_outlined,
                    color: Colors.white.withValues(alpha: 0.55), size: 18),
                const SizedBox(width: 10),
                const Text('Nuevo estudio',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w300)),
                const Spacer(),
                if (saving)
                  const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white38))
                else
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      setModalState(() => saving = true);
                      try {
                        await _studyRepo.create({
                          'patient_id': _patient.id,
                          if (_currentUser != null) 'user_id': _currentUser!.id,
                          'study_type': typeCtrl.text.trim(),
                          if (conclusionCtrl.text.trim().isNotEmpty)
                            'conclusion': conclusionCtrl.text.trim(),
                          if (dateCtrl.text.isNotEmpty)
                            'performed_at': _displayToIso(dateCtrl.text),
                        });
                        if (mounted) {
                         
                          Navigator.pop(ctx);
                          await _loadClinicalData();
                          _showSnack('Estudio registrado', success: true);
                        }
                      } catch (e) {
                        setModalState(() => saving = false);
                        _showSnack(e.toString().replaceFirst('Exception: ', ''));
                      }
                    },
                  ),
              ]),
            ),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.07)),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.60),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(children: [
                    _sheetRow('Tipo de estudio *', typeCtrl,
                        required: true, hint: 'Ej: Radiografía, Análisis de sangre'),
                    _sheetRow('Conclusión / Resultado', conclusionCtrl,
                        hint: 'Resultado o hallazgos del estudio'),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextFormField(
                        controller: dateCtrl,
                        readOnly: true,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Fecha de realización',
                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                          suffixIcon: Icon(Icons.calendar_today_outlined, size: 15,
                              color: Colors.white.withValues(alpha: 0.30)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
                          focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white54)),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                            builder: (ctx, child) => Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFF4A1240), surface: Color(0xFF2A0825)),
                                dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF2A0825)),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) {
                            setModalState(() {
                              dateCtrl.text =
                                  '${picked.day.toString().padLeft(2, '0')}/'
                                  '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                            });
                          }
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  
  static String? _displayToIso(String display) {
    if (display.isEmpty) return null;
    try {
      final parts = display.split('/');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
      }
    } catch (_) {}
    return null;
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
      try { initial = DateTime.parse(ctrl.text); } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4A1240), surface: Color(0xFF2A0825)),
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
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: Colors.white),
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
              onPressed: () => setState(() { _isEditing = false; _initControllers(); }),
              style: TextButton.styleFrom(foregroundColor: Colors.white.withValues(alpha: 0.50)),
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
    final isFemale = _patient.gender.toLowerCase() == 'female';
    final genderIcon  = isFemale ? Icons.female : Icons.male;
    final genderColor = isFemale ? const Color(0xFFE91E9C) : const Color(0xFF2196F3);

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
                  _patient.firstName.isNotEmpty ? _patient.firstName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 18, height: 18,
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
                Text(_patient.fullName,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w400)),
                const SizedBox(height: 2),
                Text('DNI: ${_patient.dni}',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
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
                        ? Icons.directions_walk : Icons.accessible,
                    size: 11, color: Colors.white.withValues(alpha: 0.30),
                  ),
                  const SizedBox(width: 3),
                  Text(_labelFor(_patient.mobilityStatus),
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.30))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'active' ? Colors.green
        : status == 'deceased' ? Colors.grey : AppColors.error;
    final label = status == 'active' ? 'Activo'
        : status == 'deceased' ? 'Fallecido' : 'Inactivo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500)),
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
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.3),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
        tabs: const [
          Tab(text: 'Datos personales'),
          Tab(text: 'Familiar a cargo'),
          Tab(text: 'Historia clínica'),
        ],
      ),
    );
  }

 

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              
              _buildBedCard(),
              const SizedBox(height: 14),
              _buildSection('Identificación', [
                _fieldRow('Nombre',            _firstName,    required: true),
                _fieldRow('Apellido',          _lastName,     required: true),
                _fieldRow('DNI',               _dni,          required: true, keyboardType: TextInputType.number),
                _fieldRow('Fecha de nacimiento',_birthDate,   isDate: true),
                _dropdownRow('Género',         _gender, _genders,        (v) => setState(() => _gender = v!)),
                _dropdownRow('Grupo sanguíneo',_bloodType, _bloodTypes,  (v) => setState(() => _bloodType = v ?? ''), isLast: true),
              ]),
              const SizedBox(height: 14),
              _buildSection('Internación', [
                _fieldRow('Fecha de ingreso',  _admissionDate, isDate: true),
                _dropdownRow('Movilidad',      _mobilityStatus, _mobilityOptions, (v) => setState(() => _mobilityStatus = v!)),
                _dropdownRow('Dependencia',    _dependencyLevel, _dependencyOptions, (v) => setState(() => _dependencyLevel = v!)),
                _dropdownRow('Estado',         _status, _statusOptions, (v) => setState(() => _status = v!), isLast: true),
              ]),
              const SizedBox(height: 14),
              _buildSection('Contacto y notas', [
                _fieldRow('Tel. de emergencia', _emergencyPhone, keyboardType: TextInputType.phone),
                _fieldRow('Notas', _notes, maxLines: 3, isLast: true),
              ]),
              if (!_isEditing) ...[
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity, height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error.withValues(alpha: 0.70)),
                    label: Text('Eliminar paciente',
                        style: TextStyle(color: AppColors.error.withValues(alpha: 0.70), fontSize: 13)),
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

 

  Widget _buildContactTab() {
    return Stack(
      children: [
        _contacts.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.family_restroom_outlined,
                        color: Colors.white.withValues(alpha: 0.12), size: 48),
                    const SizedBox(height: 12),
                    Text('Sin familiares registrados',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35), fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('Tocá + para agregar un familiar a cargo',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.20), fontSize: 11)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _contacts.length,
                itemBuilder: (ctx, i) => _contactCard(_contacts[i]),
              ),
        
        Positioned(
          right: 16, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'fab_contact',
            backgroundColor: const Color(0xFF4A1240),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: () => _showAddContactSheet(),
            child: const Icon(Icons.person_add_outlined, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _contactCard(PatientContact c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.isPrimary
              ? Colors.amber.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryDark.withValues(alpha: 0.70),
                  child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c.fullName,
                              style: const TextStyle(color: Colors.white, fontSize: 14,
                                  fontWeight: FontWeight.w400)),
                          if (c.isPrimary) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star_rounded, size: 13,
                                color: Colors.amber.withValues(alpha: 0.70)),
                          ],
                        ],
                      ),
                      if (c.relationship != null)
                        Text(c.relationship!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.40), fontSize: 11)),
                    ],
                  ),
                ),
                
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 18, color: Colors.white.withValues(alpha: 0.35)),
                  color: const Color(0xFF3A0B32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  onSelected: (action) {
                    if (action == 'edit')    _showAddContactSheet(editing: c);
                    if (action == 'primary') _setPrimaryContact(c);
                    if (action == 'delete')  _deleteContact(c);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 15,
                            color: Colors.white.withValues(alpha: 0.60)),
                        const SizedBox(width: 10),
                        Text('Editar', style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80), fontSize: 13)),
                      ]),
                    ),
                    if (!c.isPrimary)
                      PopupMenuItem(
                        value: 'primary',
                        child: Row(children: [
                          Icon(Icons.star_border_rounded, size: 15,
                              color: Colors.amber.withValues(alpha: 0.60)),
                          const SizedBox(width: 10),
                          Text('Marcar como responsable',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.80), fontSize: 13)),
                        ]),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, size: 15,
                            color: AppColors.error.withValues(alpha: 0.70)),
                        const SizedBox(width: 10),
                        Text('Eliminar', style: TextStyle(
                            color: AppColors.error.withValues(alpha: 0.80), fontSize: 13)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          _infoRow('Teléfono', c.phone),
          if (c.dni != null)    _infoRow('DNI',       c.dni!),
          if (c.email != null)  _infoRow('Email',     c.email!),
          if (c.address != null) _infoRow('Dirección', c.address!, isLast: true),
          if (c.address == null && c.email == null && c.dni == null)
            _infoRow('', '', isLast: true),
        ],
      ),
    );
  }

 

  Widget _buildClinicalTab() {
    if (_loadingClinical) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 1.5));
    }
    return DefaultTabController(
      length: 5,
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
                _clinicalTabItem(Icons.biotech_outlined,      'Diagnósticos', _diagnoses.length),
                _clinicalTabItem(Icons.history_edu_outlined,  'Evoluciones',  _evolutions.length),
                _clinicalTabItem(Icons.medication_outlined,   'Medicamentos', _prescriptions.length),
                _clinicalTabItem(Icons.science_outlined,      'Estudios',     _studies.length),
                _clinicalTabItem(Icons.warning_amber_outlined,'Alergias',     _allergies.length),
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
                _buildAllergyTab(),
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

  Widget _buildDiagnosisTab() {
    return Stack(
      children: [
        _diagnoses.isEmpty
            ? _emptyState('Sin diagnósticos registrados', Icons.biotech_outlined,
                subtitle: 'Tocá + para agregar un diagnóstico')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                itemCount: _diagnoses.length,
                itemBuilder: (ctx, i) => _diagnosisCard(_diagnoses[i]),
              ),
        Positioned(
          right: 16, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'fab_diagnosis',
            backgroundColor: const Color(0xFF4A1240),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _showAddDiagnosisSheet,
            child: const Icon(Icons.add, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _diagnosisCard(PatientDiagnosis d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.biotech_outlined, size: 17,
                  color: Color(0xFF9C6FFF)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.diagnosis,
                    style: const TextStyle(fontSize: 13, color: Colors.white,
                        fontWeight: FontWeight.w400)),
                if (d.cie10Code != null) ...[
                  const SizedBox(height: 5),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(d.cie10Code!,
                          style: const TextStyle(
                              color: Color(0xFFBB99FF), fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (d.cie10Label != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(d.cie10Label!,
                            style: TextStyle(fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.45)),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ]),
                ],
              ]),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 17,
                  color: Colors.white.withValues(alpha: 0.30)),
              color: const Color(0xFF3A0B32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
              onSelected: (action) async {
                if (action == 'edit') {
                  _showAddDiagnosisSheet(editing: d);
                } else if (action == 'delete') {
                  final confirm = await _confirmDialog(
                    'Eliminar diagnóstico?',
                    'Se eliminará permanentemente.',
                  );
                  if (confirm == true) {
                    try {
                      await _diagnosisRepo.delete(d.id);
                      await _loadClinicalData();
                      _showSnack('Diagnóstico eliminado', success: true);
                    } catch (e) {
                      _showSnack(e.toString().replaceFirst('Exception: ', ''));
                    }
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_outlined, size: 15,
                        color: Colors.white.withValues(alpha: 0.60)),
                    const SizedBox(width: 10),
                    Text('Editar', style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.80), fontSize: 13)),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 15,
                        color: AppColors.error.withValues(alpha: 0.70)),
                    const SizedBox(width: 10),
                    Text('Eliminar', style: TextStyle(
                        color: AppColors.error.withValues(alpha: 0.80), fontSize: 13)),
                  ]),
                ),
              ],
            ),
          ]),
        ),
        if (d.notes != null && d.notes!.isNotEmpty) ...[
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Text(d.notes!,
                style: TextStyle(fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55), height: 1.5)),
          ),
        ],
        if (d.diagnosedAt != null || d.professional != null) ...[
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
            child: Row(children: [
              if (d.diagnosedAt != null) ...[
                Icon(Icons.calendar_today_outlined, size: 11,
                    color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(width: 4),
                Text(_formatDate(d.diagnosedAt),
                    style: TextStyle(fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35))),
              ],
              const Spacer(),
              if (d.professional != null) ...[
                Icon(Icons.person_outline, size: 11,
                    color: Colors.white.withValues(alpha: 0.25)),
                const SizedBox(width: 4),
                Text(
                  '${d.professional!.name} ${d.professional!.lastName ?? ""}',
                  style: TextStyle(fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.35))),
              ],
            ]),
          ),
        ],
      ]),
    );
  }


  Widget _buildEvolutionTab() {
    final filtered = _evolutions.where((e) {
      if (_filterSpecialty != null && _filterSpecialty!.isNotEmpty) {
        final specs = e.professional?.specialties.map((s) => s.name) ?? [];
        if (!specs.contains(_filterSpecialty)) return false;
      }
      return true;
    }).toList();

    final allSpecialties = <String>{};
    for (final ev in _evolutions) {
      for (final sp in ev.professional?.specialties ?? []) {
        allSpecialties.add(sp.name);
      }
    }

    return Stack(
      children: [
        Column(
          children: [
            if (allSpecialties.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('Todas', null),
                      ...allSpecialties.map((s) => _filterChip(s, s)),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? _emptyState('Sin evoluciones registradas', Icons.history_edu_outlined,
                      subtitle: 'Tocá + para registrar una nueva evolución')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final ev = filtered[i];
                        final specs = ev.professional?.specialties
                                .map((s) => s.name).join(', ') ?? '';
                        return _evolutionCard(ev, specs);
                      },
                    ),
            ),
          ],
        ),
        // FAB — agregar evolución
        Positioned(
          right: 16, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'fab_evolution',
            backgroundColor: const Color(0xFF4A1240),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _showAddEvolutionSheet,
            child: const Icon(Icons.add, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
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
                // Tipo de evolución
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_evolutionTypeLabel(ev.type),
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF1565C0).withValues(alpha: 0.30)),
                  ),
                  child: Text(date,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64B5F6),
                          fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                if (specialties.isNotEmpty)
                  Text(specialties,
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.30))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(ev.evolution,
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.80),
                    height: 1.5)),
          ),
          if (ev.professional != null) ...[
            Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.white.withValues(alpha: 0.28)),
                  const SizedBox(width: 5),
                  Text('${ev.professional!.name} ${ev.professional!.lastName ?? ''}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.40))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionTab() {
    return Stack(
      children: [
        _prescriptions.isEmpty
            ? _emptyState('Sin medicamentos recetados', Icons.medication_outlined,
                subtitle: 'Tocá + para agregar una prescripción')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                itemCount: _prescriptions.length,
                itemBuilder: (ctx, i) => _prescriptionCard(_prescriptions[i]),
              ),
        Positioned(
          right: 16, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'fab_prescription',
            backgroundColor: const Color(0xFF4A1240),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _showAddPrescriptionSheet,
            child: const Icon(Icons.add, size: 24),
          ),
        ),
      ],
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
                  child: Icon(Icons.medication_outlined, size: 18,
                      color: Colors.green.withValues(alpha: 0.70)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.medication?.name ?? 'Medicamento',
                          style: const TextStyle(fontSize: 14, color: Colors.white,
                              fontWeight: FontWeight.w400)),
                      if (p.medication?.presentation != null)
                        Text(p.medication!.presentation!,
                            style: TextStyle(fontSize: 11,
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
                _pillBadge(Icons.scale_outlined,    'Dosis: ${p.dose}'),
                const SizedBox(width: 8),
                _pillBadge(Icons.schedule_outlined, p.frequency),
              ],
            ),
            if (p.route != null) ...[
              const SizedBox(height: 6),
              _pillBadge(Icons.route_outlined, 'Vía: ${p.route}'),
            ],
            if (p.professional != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 11, color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(width: 4),
                  Text('${p.professional!.name} ${p.professional!.lastName ?? ''}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
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
          Text(text, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.65))),
        ],
      ),
    );
  }

  Widget _buildStudiesTab() {
    return Stack(
      children: [
        _studies.isEmpty
            ? _emptyState('Sin estudios registrados', Icons.science_outlined,
                subtitle: 'Tocá + para agregar un estudio')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
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
                        ? '\${s.professional!.name} \${s.professional!.lastName ?? ''}' : null,
                  );
                },
              ),
        Positioned(
          right: 16, bottom: 20,
          child: FloatingActionButton(
            heroTag: 'fab_study',
            backgroundColor: const Color(0xFF4A1240),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _showAddStudySheet,
            child: const Icon(Icons.add, size: 24),
          ),
        ),
      ],
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
                      style: const TextStyle(fontSize: 13, color: Colors.white,
                          fontWeight: FontWeight.w400)),
                ),
                if (date != null)
                  Text(_formatDate(date),
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35))),
              ],
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.60), height: 1.5)),
            ],
            if (professional != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 11, color: Colors.white.withValues(alpha: 0.25)),
                  const SizedBox(width: 4),
                  Text(professional,
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.38))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg, IconData icon, {String? subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.10), size: 44),
          const SizedBox(height: 10),
          Text(msg, style: TextStyle(color: Colors.white.withValues(alpha: 0.30), fontSize: 13)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(
                color: Colors.white.withValues(alpha: 0.18), fontSize: 11)),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadClinicalData,
            icon: Icon(Icons.refresh, size: 14, color: Colors.white.withValues(alpha: 0.35)),
            label: Text('Recargar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
          ),
        ],
      ),
    );
  }

 

  Widget _buildBedCard() {
    final assigned = _currentAssignment != null;
    final bed = _currentAssignment?.bed;
    final room = bed?.room;

    return Container(
      decoration: BoxDecoration(
        color: assigned
            ? Colors.green.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: assigned
              ? Colors.green.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: (assigned ? Colors.green : Colors.white)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                assigned ? Icons.bed_rounded : Icons.bed_outlined,
                size: 22,
                color: (assigned ? Colors.green : Colors.white)
                    .withValues(alpha: assigned ? 0.75 : 0.30),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: assigned
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cama ${bed!.bedNumber}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400)),
                        if (room != null)
                          Text(
                            'Hab. ${room.number}'
                            '${room.floor != null ? ' · Piso ${room.floor}' : ''}',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.45),
                                fontSize: 11),
                          ),
                      ],
                    )
                  : Text('Sin cama asignada',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 14)),
            ),
            assigned
                ? OutlinedButton.icon(
                    onPressed: _isEditing ? null : _releaseBed,
                    icon: Icon(Icons.logout, size: 14,
                        color: AppColors.error.withValues(alpha: 0.65)),
                    label: Text('Dar de alta',
                        style: TextStyle(
                            color: AppColors.error.withValues(alpha: 0.70),
                            fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.25)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: _isEditing ? null : _showAssignBedSheet,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Asignar', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A1240),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

 

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
            child: Text(title.toUpperCase(),
                style: TextStyle(fontSize: 10, letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.30), fontWeight: FontWeight.w500)),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          ...rows,
        ],
      ),
    );
  }

  Widget _fieldRow(String label, TextEditingController ctrl, {
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
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                suffixIcon: isDate
                    ? Icon(Icons.calendar_today_outlined, size: 15,
                        color: Colors.white.withValues(alpha: 0.30)) : null,
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
                errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65))),
                errorStyle: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
              ),
            )
          : Row(
              children: [
                SizedBox(width: 140,
                    child: Text(label,
                        style: TextStyle(fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.38)))),
                Expanded(
                  child: Text(ctrl.text.isEmpty ? '—' : ctrl.text,
                      style: TextStyle(fontSize: 13,
                          color: ctrl.text.isEmpty
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.80)),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> options,
      ValueChanged<String?> onChanged, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: _isEditing ? 4 : 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: _isEditing
          ? DropdownButtonFormField<String>(
              initialValue: value.isEmpty ? null : value,
              dropdownColor: const Color(0xFF2A0825),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54)),
              ),
              items: options.map((o) => DropdownMenuItem(
                    value: o.isEmpty ? null : o,
                    child: Text(o.isEmpty ? '—' : _labelFor(o),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: o.isEmpty ? 0.35 : 0.85),
                            fontSize: 13)),
                  )).toList(),
              onChanged: onChanged,
            )
          : Row(
              children: [
                SizedBox(width: 140,
                    child: Text(label,
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.38)))),
                Expanded(
                  child: Text(value.isEmpty ? '—' : _labelFor(value),
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.80)),
                      textAlign: TextAlign.end),
                ),
              ],
            ),
    );
  }


  Widget _sheetRow(String label, TextEditingController ctrl, {
    bool required = false,
    TextInputType? keyboard,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
            : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.20), fontSize: 12),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
          focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white54)),
          errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65))),
          errorStyle: TextStyle(color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
      child: Row(
        children: [
          SizedBox(width: 110,
              child: Text(label,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)))),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 13,
                    color: value == '—'
                        ? Colors.white.withValues(alpha: 0.20)
                        : Colors.white.withValues(alpha: 0.75)),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

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

  // ─── TAB ALERGIAS ───────────────────────────────────────────────────────────

  Widget _buildAllergyTab() {
    return Stack(
      children: [
        _allergies.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 44, color: Colors.green.withValues(alpha: 0.25)),
                    const SizedBox(height: 12),
                    Text('Sin alergias registradas',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 13)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                itemCount: _allergies.length,
                itemBuilder: (_, i) => _allergyCard(_allergies[i]),
              ),

        // FAB agregar
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'fab_allergy',
            mini: true,
            backgroundColor: AppColors.primaryDark,
            onPressed: _showAddAllergySheet,
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _allergyCard(Allergy allergy) {
    final severityColor = _severityColor(allergy.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning_amber_outlined,
              size: 18, color: severityColor.withValues(alpha: 0.80)),
        ),
        title: Text(allergy.name,
            style: const TextStyle(color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w400)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(allergy.severityLabel,
                      style: TextStyle(fontSize: 10,
                          color: severityColor.withValues(alpha: 0.90))),
                ),
              ],
            ),
            if (allergy.reaction != null && allergy.reaction!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('Reacción: ${allergy.reaction}',
                  style: TextStyle(fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45))),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _showEditAllergySheet(allergy),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.edit_outlined, size: 15,
                    color: Colors.white.withValues(alpha: 0.35)),
              ),
            ),
            InkWell(
              onTap: () => _removeAllergy(allergy),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.delete_outline, size: 15,
                    color: AppColors.error.withValues(alpha: 0.40)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'severe':   return const Color(0xFFEF5350);
      case 'moderate': return const Color(0xFFFF9800);
      default:         return const Color(0xFF4CAF50);
    }
  }

  // ── Agregar alergia ────────────────────────────────────────────────────────

  Future<void> _showAddAllergySheet() async {
    // Cargar catálogo existente
    List<Allergy> catalog = [];
    try {
      catalog = await _allergyRepo.getAll();
      final assignedIds = _allergies.map((a) => a.id).toSet();
      catalog = catalog.where((a) => !assignedIds.contains(a.id)).toList();
    } catch (_) {}

    if (!mounted) return;

    // Estado del sheet
    Allergy? selected;          // alergia existente seleccionada
    bool creatingNew = false;   // modo "nueva alergia"
    String severity  = 'moderate';
    final searchCtrl    = TextEditingController();
    final newNameCtrl   = TextEditingController();
    final newDescCtrl   = TextEditingController();
    final reactionCtrl  = TextEditingController();
    List<Allergy> filtered = List.from(catalog);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          // Si está en modo nueva alergia, muestra un formulario de creación
          final content = creatingNew
              ? _newAllergyForm(
                  nameCtrl:    newNameCtrl,
                  descCtrl:    newDescCtrl,
                  reactionCtrl:reactionCtrl,
                  severity:    severity,
                  saving:      saving,
                  onSeverity:  (v) => setModal(() => severity = v),
                  onBack:      () => setModal(() { creatingNew = false; newNameCtrl.clear(); newDescCtrl.clear(); }),
                  onSave: () async {
                    if (newNameCtrl.text.trim().isEmpty) return;
                    setModal(() => saving = true);
                    try {
                      // 1. Crear la alergia en el catálogo
                      final created = await _allergyRepo.create({
                        'name': newNameCtrl.text.trim(),
                        if (newDescCtrl.text.trim().isNotEmpty)
                          'description': newDescCtrl.text.trim(),
                      });
                      // 2. Asignarla al paciente
                      await _allergyRepo.assignToPatient(
                        _patient.id,
                        allergyId: created.id,
                        severity:  severity,
                        reaction:  reactionCtrl.text.trim().isEmpty
                            ? null : reactionCtrl.text.trim(),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        await _loadClinicalData();
                        _showSnack('Alergia creada y agregada', success: true);
                      }
                    } catch (e) {
                      setModal(() => saving = false);
                      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
                    }
                  },
                )
              : _selectAllergyForm(
                  catalog:      catalog,
                  filtered:     filtered,
                  selected:     selected,
                  searchCtrl:   searchCtrl,
                  reactionCtrl: reactionCtrl,
                  severity:     severity,
                  saving:       saving,
                  onSearch: (q) => setModal(() {
                    filtered = catalog
                        .where((a) => a.name.toLowerCase().contains(q.toLowerCase()))
                        .toList();
                  }),
                  onSelect:     (a) => setModal(() => selected = a),
                  onSeverity:   (v) => setModal(() => severity = v),
                  onCreateNew:  () => setModal(() { creatingNew = true; searchCtrl.clear(); }),
                  onSave: (saving || selected == null) ? null : () async {
                    setModal(() => saving = true);
                    try {
                      await _allergyRepo.assignToPatient(
                        _patient.id,
                        allergyId: selected!.id,
                        severity:  severity,
                        reaction:  reactionCtrl.text.trim().isEmpty
                            ? null : reactionCtrl.text.trim(),
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        await _loadClinicalData();
                        _showSnack('Alergia agregada', success: true);
                      }
                    } catch (e) {
                      setModal(() => saving = false);
                      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
                    }
                  },
                );

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A0825),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: content,
            ),
          );
        },
      ),
    );
  }

  // ── Formulario: seleccionar del catálogo ───────────────────────────────────

  Widget _selectAllergyForm({
    required List<Allergy> catalog,
    required List<Allergy> filtered,
    required Allergy? selected,
    required TextEditingController searchCtrl,
    required TextEditingController reactionCtrl,
    required String severity,
    required bool saving,
    required ValueChanged<String> onSearch,
    required ValueChanged<Allergy> onSelect,
    required ValueChanged<String> onSeverity,
    required VoidCallback onCreateNew,
    required VoidCallback? onSave,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle + título
        Center(
          child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Row(
          children: [
            const Text('Agregar alergia',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w300)),
            const Spacer(),
            // Botón "nueva"
            TextButton.icon(
              onPressed: onCreateNew,
              icon: Icon(Icons.add, size: 14,
                  color: Colors.white.withValues(alpha: 0.55)),
              label: Text('Nueva',
                  style: TextStyle(fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55))),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Buscador
        TextField(
          controller: searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          onChanged: onSearch,
          decoration: InputDecoration(
            hintText: 'Buscar en el catálogo...',
            hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.25), fontSize: 13),
            prefixIcon: Icon(Icons.search,
                color: Colors.white.withValues(alpha: 0.30), size: 18),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white30)),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
        const SizedBox(height: 6),

        // Lista catálogo
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 160),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        searchCtrl.text.isEmpty
                            ? 'No hay más alergias en el catálogo.'
                            : 'No se encontró "${searchCtrl.text}".',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onCreateNew,
                        icon: const Icon(Icons.add_circle_outline,
                            size: 14, color: Colors.white54),
                        label: const Text('Crear nueva alergia',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final a = filtered[i];
                    final isSel = selected?.id == a.id;
                    return InkWell(
                      onTap: () => onSelect(a),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryDark.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? Colors.white.withValues(alpha: 0.20)
                                : Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(a.name,
                                  style: TextStyle(
                                      color: Colors.white.withValues(
                                          alpha: isSel ? 0.90 : 0.60),
                                      fontSize: 13)),
                            ),
                            if (isSel)
                              Icon(Icons.check, size: 14,
                                  color: Colors.white.withValues(alpha: 0.60)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 10),

        // Severidad
        Text('Severidad',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 11)),
        const SizedBox(height: 6),
        Row(children: [
          _severityChip('mild',     'Leve',     const Color(0xFF4CAF50), severity, onSeverity),
          const SizedBox(width: 8),
          _severityChip('moderate', 'Moderada', const Color(0xFFFF9800), severity, onSeverity),
          const SizedBox(width: 8),
          _severityChip('severe',   'Grave',    const Color(0xFFEF5350), severity, onSeverity),
        ]),
        const SizedBox(height: 10),

        // Reacción
        TextField(
          controller: reactionCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Reacción (opcional)',
            labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 18),

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
            onPressed: onSave,
            child: saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Agregar alergia',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
          ),
        ),
      ],
    );
  }

  // ── Formulario: crear nueva alergia en el catálogo ─────────────────────────

  Widget _newAllergyForm({
    required TextEditingController nameCtrl,
    required TextEditingController descCtrl,
    required TextEditingController reactionCtrl,
    required String severity,
    required bool saving,
    required ValueChanged<String> onSeverity,
    required VoidCallback onBack,
    required VoidCallback onSave,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: Icon(Icons.arrow_back_ios_new,
                  size: 15, color: Colors.white.withValues(alpha: 0.55)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            const Text('Nueva alergia',
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w300)),
          ],
        ),
        const SizedBox(height: 14),

        // Nombre (requerido)
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Nombre de la alergia *',
            labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 8),

        // Descripción (opcional)
        TextField(
          controller: descCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Descripción (opcional)',
            labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 14),

        // Severidad para este paciente
        Text('Severidad para este paciente',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 11)),
        const SizedBox(height: 6),
        Row(children: [
          _severityChip('mild',     'Leve',     const Color(0xFF4CAF50), severity, onSeverity),
          const SizedBox(width: 8),
          _severityChip('moderate', 'Moderada', const Color(0xFFFF9800), severity, onSeverity),
          const SizedBox(width: 8),
          _severityChip('severe',   'Grave',    const Color(0xFFEF5350), severity, onSeverity),
        ]),
        const SizedBox(height: 10),

        // Reacción
        TextField(
          controller: reactionCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Reacción (opcional)',
            labelStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54)),
          ),
        ),
        const SizedBox(height: 18),

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
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Crear y agregar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
          ),
        ),
      ],
    );
  }

  // ── Editar alergia ─────────────────────────────────────────────────────────

  Future<void> _showEditAllergySheet(Allergy allergy) async {
    String severity = allergy.severity ?? 'moderate';
    final reactionCtrl = TextEditingController(text: allergy.reaction ?? '');
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('Editar — ${allergy.name}',
                    style: const TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w300)),
                const SizedBox(height: 16),

                Text('Severidad',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40), fontSize: 11)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _severityChip('mild',     'Leve',     const Color(0xFF4CAF50), severity, (v) => setModal(() => severity = v)),
                    const SizedBox(width: 8),
                    _severityChip('moderate', 'Moderada', const Color(0xFFFF9800), severity, (v) => setModal(() => severity = v)),
                    const SizedBox(width: 8),
                    _severityChip('severe',   'Grave',    const Color(0xFFEF5350), severity, (v) => setModal(() => severity = v)),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: reactionCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Reacción',
                    labelStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.18))),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54)),
                  ),
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
                      setModal(() => saving = true);
                      try {
                        await _allergyRepo.updatePatientAllergy(
                          _patient.id,
                          allergy.id,
                          severity: severity,
                          reaction: reactionCtrl.text.trim().isEmpty
                              ? null
                              : reactionCtrl.text.trim(),
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          await _loadClinicalData();
                          _showSnack('Alergia actualizada', success: true);
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
                        : const Text('Guardar cambios',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w400)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Eliminar alergia ───────────────────────────────────────────────────────

  Future<void> _removeAllergy(Allergy allergy) async {
    final ok = await _confirmDialog(
      'Eliminar alergia',
      '¿Quitar "${allergy.name}" del registro de este paciente?',
    );
    if (ok != true) return;
    try {
      await _allergyRepo.removeFromPatient(_patient.id, allergy.id);
      await _loadClinicalData();
      _showSnack('Alergia eliminada', success: true);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _severityChip(
    String value,
    String label,
    Color color,
    String current,
    ValueChanged<String> onTap,
  ) {
    final sel = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? color.withValues(alpha: 0.20) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? color.withValues(alpha: 0.60) : Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: sel ? color : Colors.white.withValues(alpha: 0.45))),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/patient_model.dart';
import 'package:app_geriatrico/data/repositories/patient_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';

class CreatePatientScreen extends StatefulWidget {
  final String token;
  const CreatePatientScreen({super.key, required this.token});

  @override
  State<CreatePatientScreen> createState() => _CreatePatientScreenState();
}

class _CreatePatientScreenState extends State<CreatePatientScreen> {
  late final PatientRepository _repo;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final _firstName      = TextEditingController();
  final _lastName       = TextEditingController();
  final _dni            = TextEditingController();
  final _birthDate      = TextEditingController();
  final _admissionDate  = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _notes          = TextEditingController();

  // FIX: los valores deben coincidir exactamente con los enums del backend
  // Backend: gender -> 'male' | 'female' | 'other'
  String _gender          = 'female';
  String _bloodType       = '';
  // Backend: mobility_status -> 'normal' | 'reduced' | 'wheelchair' | 'bedridden'
  String _mobilityStatus  = 'normal';
  // Backend: dependency_level -> 'low' | 'medium' | 'high'
  String _dependencyLevel = 'low';
  // Backend: status -> 'active' | 'inactive' | 'deceased'
  String _status          = 'active';

  // FIX: valores en inglés para que el backend los acepte
  static const _genders          = ['female', 'male', 'other'];
  static const _bloodTypes       = ['', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const _mobilityOptions  = ['normal', 'reduced', 'wheelchair', 'bedridden'];
  static const _dependencyOptions = ['low', 'medium', 'high'];
  static const _statusOptions    = ['active', 'inactive', 'deceased'];

  @override
  void initState() {
    super.initState();
    _repo = PatientRepository(
      ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token),
    );
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _dni, _birthDate, _admissionDate, _emergencyPhone, _notes]) {
      c.dispose();
    }
    super.dispose();
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
          colorScheme: const ColorScheme.dark(primary: Color(0xFF4A1240), surface: Color(0xFF2A0825)),
          dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF2A0825)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => ctrl.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final patient = Patient(
        id: 0,
        firstName:      _firstName.text.trim(),
        lastName:       _lastName.text.trim(),
        dni:            _dni.text.trim(),
        birthDate:      _birthDate.text.isEmpty ? null : _birthDate.text,
        gender:         _gender,
        bloodType:      _bloodType.isEmpty ? null : _bloodType,
        admissionDate:  _admissionDate.text.isEmpty ? null : _admissionDate.text,
        mobilityStatus: _mobilityStatus,
        dependencyLevel: _dependencyLevel,
        emergencyPhone: _emergencyPhone.text.trim().isEmpty ? null : _emergencyPhone.text.trim(),
        notes:          _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        status:         _status,
        contacts:       [],
      );
      await _repo.createPatient(patient);
      if (mounted) {
        _showSnack('Paciente creado exitosamente', success: true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context, true);
      }
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
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: const EdgeInsets.all(18),
                          children: [
                            _buildSection('Datos personales', [
                              _fieldRow('Nombre *', _firstName, required: true),
                              _fieldRow('Apellido *', _lastName, required: true),
                              _fieldRow('DNI *', _dni, required: true, keyboardType: TextInputType.number),
                              _fieldRow('Fecha de nacimiento', _birthDate, isDate: true),
                              _dropdownRow('Género', _gender, _genders, (v) => setState(() => _gender = v!)),
                              _dropdownRow('Grupo sanguíneo', _bloodType, _bloodTypes,
                                  (v) => setState(() => _bloodType = v ?? ''), isLast: true),
                            ]),
                            const SizedBox(height: 14),
                            _buildSection('Internación', [
                              _fieldRow('Fecha de ingreso', _admissionDate, isDate: true),
                              _dropdownRow('Movilidad', _mobilityStatus, _mobilityOptions,
                                  (v) => setState(() => _mobilityStatus = v!)),
                              _dropdownRow('Nivel de dependencia', _dependencyLevel, _dependencyOptions,
                                  (v) => setState(() => _dependencyLevel = v!)),
                              _dropdownRow('Estado', _status, _statusOptions,
                                  (v) => setState(() => _status = v!), isLast: true),
                            ]),
                            const SizedBox(height: 14),
                            _buildSection('Contacto de emergencia', [
                              _fieldRow('Teléfono de emergencia', _emergencyPhone, keyboardType: TextInputType.phone),
                              _fieldRow('Notas', _notes, maxLines: 3, isLast: true),
                            ]),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Guardar paciente',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.3)),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
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
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withValues(alpha: 0.65), size: 17),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Nuevo paciente',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: 0.3)),
        ],
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
    bool required = false, bool isDate = false, bool isLast = false,
    TextInputType? keyboardType, int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isDate ? TextInputType.datetime : keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        readOnly: isDate,
        onTap: isDate ? () => _pickDate(ctrl) : null,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
          suffixIcon: isDate
              ? Icon(Icons.calendar_today_outlined, size: 15, color: Colors.white.withValues(alpha: 0.30))
              : null,
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
          errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65))),
          errorStyle: TextStyle(color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
        ),
      ),
    );
  }

  Widget _dropdownRow(String label, String value, List<String> options,
      ValueChanged<String?> onChanged, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: DropdownButtonFormField<String>(
        value: value.isEmpty ? null : value,
        dropdownColor: const Color(0xFF2A0825),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18))),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
        ),
        items: options.map((o) => DropdownMenuItem(
          value: o.isEmpty ? null : o,
          child: Text(o.isEmpty ? '—' : _labelForOption(o),
              style: TextStyle(color: Colors.white.withValues(alpha: o.isEmpty ? 0.35 : 0.85), fontSize: 13)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // FIX: etiquetas en español para los valores en inglés que va al backend
  String _labelForOption(String o) {
    const labels = {
      // género
      'female':    'Femenino',
      'male':      'Masculino',
      'other':     'Otro',
      // movilidad
      'normal':    'Normal',
      'reduced':   'Reducida',
      'wheelchair':'Silla de ruedas',
      'bedridden': 'Postrado',
      
      'low':       'Baja',
      'medium':    'Media',
      'high':      'Alta',
      
      'active':    'Activo',
      'inactive':  'Inactivo',
      'deceased':  'Fallecido',
    };
    return labels[o] ?? o;
  }
}
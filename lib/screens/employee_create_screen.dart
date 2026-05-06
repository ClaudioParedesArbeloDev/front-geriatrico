import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/role_model.dart';
import 'package:app_geriatrico/data/models/specialty_model.dart';
import 'package:app_geriatrico/data/repositories/employee_repository.dart';

class CreateEmployeeScreen extends StatefulWidget {
  final String token;

  const CreateEmployeeScreen({super.key, required this.token});

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  late final EmployeeRepository _repo;
  late final Dio _dio;

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _obscurePassword = true;

  List<Role> _allRoles = [];
  final Set<int> _selectedRoleIds = {};

  List<Specialty> _allSpecialties = [];
  final Set<int> _selectedSpecialtyIds = {};

  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _dni = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _birthDate = TextEditingController();

  final _employeeCode = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _hireDate = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _repo = EmployeeRepository(widget.token);
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    ));
    _loadRoles();
    _loadSpecialties();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _lastName, _email, _password, _dni,
      _phone, _address, _birthDate, _employeeCode,
      _licenseNumber, _hireDate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final roles = await _repo.getRoles();
      if (mounted) setState(() => _allRoles = roles);
    } catch (e) {
      debugPrint('Error cargando roles: $e');
    }
  }

  Future<void> _loadSpecialties() async {
    try {
      final res = await _dio.get('/specialties');
      final list = (res.data as List)
          .map((s) => Specialty.fromJson(s as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _allSpecialties = list);
    } catch (e) {
      debugPrint('Error cargando especialidades: $e');
    }
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
      firstDate: DateTime(1920),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF4A1240),
            surface: Color(0xFF2A0825),
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF2A0825),
          ),
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
      final data = {
        'name': _name.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'dni': _dni.text.trim().isEmpty ? null : _dni.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'birth_date': _birthDate.text.isEmpty ? null : _birthDate.text,
        'employee_code': _employeeCode.text.trim().isEmpty ? null : _employeeCode.text.trim(),
        'license_number': _licenseNumber.text.trim().isEmpty ? null : _licenseNumber.text.trim(),
        'hire_date': _hireDate.text.isEmpty ? null : _hireDate.text,
        'is_active': _isActive,
        'roles': _selectedRoleIds.toList(),
      };

      // Crear el empleado y obtener el objeto devuelto con su ID
      final created = await _repo.create(data);

      // Asignar especialidades si se seleccionaron
      if (_selectedSpecialtyIds.isNotEmpty) {
        try {
          await _dio.put(
            '/users/${created.id}/specialties',
            data: {'specialty_ids': _selectedSpecialtyIds.toList()},
            options: Options(headers: {'Content-Type': 'application/json'}),
          );
        } catch (e) {
          debugPrint('Error asignando especialidades: $e');
          // No bloqueamos el flujo — el empleado ya fue creado
        }
      }

      if (mounted) {
        _showSnack('Empleado creado exitosamente', success: true);
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: success
            ? Colors.green.withValues(alpha: 0.85)
            : AppColors.error.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) => Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth > 700 ? 720 : double.infinity,
                        ),
                        child: Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.all(18),
                            children: [
                              _buildSection('Datos personales', [
                                _fieldRow('Nombre', _name, required: true),
                                _fieldRow('Apellido', _lastName, required: true),
                                _fieldRow('DNI', _dni),
                                _fieldRow('Fecha de nacimiento', _birthDate, isDate: true),
                                _fieldRow('Email', _email,
                                    required: true,
                                    keyboardType: TextInputType.emailAddress),
                                _fieldRow('Teléfono', _phone,
                                    keyboardType: TextInputType.phone),
                                _fieldRow('Dirección', _address, isLast: true),
                              ]),
                              const SizedBox(height: 14),
                              _buildSection('Contraseña', [
                                _passwordRow(),
                              ]),
                              const SizedBox(height: 14),
                              _buildSection('Datos laborales', [
                                _fieldRow('Código de empleado', _employeeCode),
                                _fieldRow('N° de licencia', _licenseNumber),
                                _fieldRow('Fecha de ingreso', _hireDate, isDate: true),
                                _buildActiveRow(isLast: true),
                              ]),
                              const SizedBox(height: 14),
                              _buildRolesSection(),
                              const SizedBox(height: 14),
                              _buildSpecialtiesSection(),
                              const SizedBox(height: 28),
                              _buildSaveButton(),
                              const SizedBox(height: 24),
                            ],
                          ),
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
                child: CircularProgressIndicator(
                    color: Colors.white54, strokeWidth: 1.5),
              ),
            ),
        ],
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
            onPressed: () => Navigator.pop(context, false),
          ),
          Icon(Icons.person_add_outlined,
              color: Colors.white.withValues(alpha: 0.50), size: 19),
          const SizedBox(width: 10),
          const Text(
            'Nuevo empleado',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _saving ? null : _save,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Guardar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isDate ? TextInputType.datetime : keyboardType,
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
            borderSide: BorderSide(color: Colors.white54),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65)),
          ),
          errorStyle: TextStyle(
              color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
        ),
      ),
    );
  }

  Widget _passwordRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: _password,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Campo requerido';
          if (v.length < 6) return 'Mínimo 6 caracteres';
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.40), fontSize: 12),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error.withValues(alpha: 0.65)),
          ),
          errorStyle: TextStyle(
              color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildActiveRow({bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Text('Estado',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.65))),
          const Spacer(),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: Colors.green,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
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
            child: Text('ROLES',
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.30),
                    fontWeight: FontWeight.w500)),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _allRoles.isEmpty
                ? Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1, color: Colors.white24),
                      ),
                      const SizedBox(width: 10),
                      Text('Cargando roles...',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.28),
                              fontSize: 13)),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allRoles.map((role) {
                      final sel = _selectedRoleIds.contains(role.id);
                      return FilterChip(
                        label: Text(role.displayName,
                            style: TextStyle(
                                fontSize: 12,
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55))),
                        selected: sel,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedRoleIds.add(role.id);
                          } else {
                            _selectedRoleIds.remove(role.id);
                          }
                        }),
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        selectedColor: const Color(0xFF4A1240).withValues(alpha: 0.90),
                        checkmarkColor: Colors.white70,
                        side: BorderSide(
                          color: sel
                              ? Colors.white.withValues(alpha: 0.22)
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                        showCheckmark: true,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection() {
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
            child: Row(
              children: [
                Text('ESPECIALIDADES',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.30),
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('Opcional',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.20),
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _allSpecialties.isEmpty
                ? Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 1, color: Colors.white24),
                      ),
                      const SizedBox(width: 10),
                      Text('Cargando especialidades...',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.28),
                              fontSize: 13)),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allSpecialties.map((spec) {
                      final sel = _selectedSpecialtyIds.contains(spec.id);
                      return FilterChip(
                        avatar: sel
                            ? Icon(Icons.check_circle_outline,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.75))
                            : Icon(Icons.add_circle_outline,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.30)),
                        label: Text(spec.name,
                            style: TextStyle(
                                fontSize: 12,
                                color: sel
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.50))),
                        selected: sel,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _selectedSpecialtyIds.add(spec.id);
                          } else {
                            _selectedSpecialtyIds.remove(spec.id);
                          }
                        }),
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        selectedColor: const Color(0xFF7C3E6A).withValues(alpha: 0.85),
                        checkmarkColor: Colors.transparent,
                        side: BorderSide(
                          color: sel
                              ? const Color(0xFF9C4E8A).withValues(alpha: 0.40)
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A1240),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        child: const Text(
          'Crear empleado',
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3),
        ),
      ),
    );
  }
}
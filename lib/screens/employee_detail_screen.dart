import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/employee_model.dart';
import 'package:app_geriatrico/data/models/role_model.dart';
import 'package:app_geriatrico/data/models/specialty_model.dart';
import 'package:app_geriatrico/data/repositories/employee_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final Employee employee;
  final String token;

  const EmployeeDetailScreen({
    super.key,
    required this.employee,
    required this.token,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late final EmployeeRepository _repo;
  late Employee _emp;

  bool _isEditing = false;
  bool _saving = false;

  List<Role> _allRoles = [];
  List<Specialty> _allSpecialties = [];
  late Set<int> _selectedRoleIds;
  late Set<int> _selectedSpecialtyIds;

  late TextEditingController _name;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _dni;
  late TextEditingController _phone;
  late TextEditingController _address;
  late TextEditingController _employeeCode;
  late TextEditingController _licenseNumber;
  late TextEditingController _birthDate;
  late TextEditingController _hireDate;
  late bool _isActive;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // FIX: EmployeeRepository ahora recibe ApiService
    _repo = EmployeeRepository(
      ApiService(baseUrl: ApiConfig.baseUrl, token: widget.token),
    );
    _emp = widget.employee;
    _initControllers();
    _loadRoles();
    _loadAllSpecialties();
  }

  void _initControllers() {
    _name = TextEditingController(text: _emp.name);
    _lastName = TextEditingController(text: _emp.lastName);
    _email = TextEditingController(text: _emp.email);
    _dni = TextEditingController(text: _emp.dni ?? '');
    _phone = TextEditingController(text: _emp.phone ?? '');
    _address = TextEditingController(text: _emp.address ?? '');
    _employeeCode = TextEditingController(text: _emp.employeeCode ?? '');
    _licenseNumber = TextEditingController(text: _emp.licenseNumber ?? '');
    _birthDate = TextEditingController(text: _emp.birthDate ?? '');
    _hireDate = TextEditingController(text: _emp.hireDate ?? '');
    _isActive = _emp.isActive;
    _selectedRoleIds = _emp.roles.map((r) => r.id).toSet();
    _selectedSpecialtyIds = _emp.specialties.map((s) => s.id).toSet();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _lastName, _email, _dni, _phone,
      _address, _employeeCode, _licenseNumber, _birthDate, _hireDate,
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

  Future<void> _loadAllSpecialties() async {
    try {
      // FIX: usa _repo.getSpecialties() en lugar de Dio directo
      final list = await _repo.getSpecialties();
      if (mounted) setState(() => _allSpecialties = list);
    } catch (e) {
      debugPrint('Error cargando especialidades: $e');
    }
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        for (final c in [
          _name, _lastName, _email, _dni, _phone,
          _address, _employeeCode, _licenseNumber, _birthDate, _hireDate,
        ]) {
          c.dispose();
        }
        _initControllers();
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'name': _name.text.trim(),
        'last_name': _lastName.text.trim(),
        'email': _email.text.trim(),
        'dni': _dni.text.trim().isEmpty ? null : _dni.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'employee_code': _employeeCode.text.trim().isEmpty ? null : _employeeCode.text.trim(),
        'license_number': _licenseNumber.text.trim().isEmpty ? null : _licenseNumber.text.trim(),
        'birth_date': _birthDate.text.trim().isEmpty ? null : _birthDate.text.trim(),
        'hire_date': _hireDate.text.trim().isEmpty ? null : _hireDate.text.trim(),
        'is_active': _isActive,
      };

      final updated = await _repo.update(_emp.id, data, _selectedRoleIds.toList());

      // FIX: usa _repo.replaceSpecialties() en lugar de Dio directo
      try {
        await _repo.replaceSpecialties(_emp.id, _selectedSpecialtyIds.toList());
      } catch (e) {
        debugPrint('Error actualizando especialidades: $e');
      }

      final finalEmployee = updated.copyWith(
        specialties: _allSpecialties
            .where((s) => _selectedSpecialtyIds.contains(s.id))
            .toList(),
      );

      setState(() {
        _emp = finalEmployee;
        _isEditing = false;
        _saving = false;
        _initControllers();
      });

      if (mounted) _showSnack('Empleado actualizado', success: true);
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
        title: const Text('Eliminar empleado',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
        content: Text(
          '¿Estás seguro que querés eliminar a ${_emp.fullName}?\nEsta acción no se puede deshacer.',
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
      await _repo.delete(_emp.id);
      if (mounted) Navigator.pop(context, true);
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
      setState(() {
        ctrl.text = picked.toIso8601String().split('T').first;
      });
    }
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
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildSection('Datos personales', [
                                _fieldRow('Nombre', _name, required: true),
                                _fieldRow('Apellido', _lastName, required: true),
                                _fieldRow('DNI', _dni),
                                _fieldRow('Fecha de nacimiento', _birthDate, isDate: true),
                                _fieldRow('Email', _email,
                                    required: true, keyboardType: TextInputType.emailAddress),
                                _fieldRow('Teléfono', _phone, keyboardType: TextInputType.phone),
                                _fieldRow('Dirección', _address, isLast: true),
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
                              if (!_isEditing) ...[
                                const SizedBox(height: 28),
                                _buildDeleteButton(),
                              ],
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
                child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 1.5),
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
          Expanded(
            child: Text(
              _isEditing ? 'Editar empleado' : _emp.fullName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  color: Colors.white.withValues(alpha: 0.55), size: 19),
              onPressed: _toggleEdit,
              tooltip: 'Editar',
            )
          else ...[
            TextButton(
              onPressed: _toggleEdit,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF4A1240).withValues(alpha: 0.90),
            child: Text(
              _emp.initials,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _emp.fullName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _emp.email,
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.40)),
                ),
                if (_emp.specialties.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _emp.specialties
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3E6A).withValues(alpha: 0.40),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s.name,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white.withValues(alpha: 0.65),
                                      letterSpacing: 0.3)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          _statusBadge(_emp.isActive),
        ],
      ),
    );
  }

  Widget _statusBadge(bool active) {
    final color = active ? Colors.green : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: _isEditing
          ? TextFormField(
              controller: ctrl,
              keyboardType: isDate ? TextInputType.datetime : keyboardType,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              readOnly: isDate,
              onTap: isDate ? () => _pickDate(ctrl) : null,
              validator: required
                  ? (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null
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
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54),
                ),
                errorBorder: UnderlineInputBorder(
                  borderSide:
                      BorderSide(color: AppColors.error.withValues(alpha: 0.65)),
                ),
                errorStyle: TextStyle(
                    color: AppColors.error.withValues(alpha: 0.80), fontSize: 11),
              ),
            )
          : Row(
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.38)),
                  ),
                ),
                Expanded(
                  child: Text(
                    ctrl.text.isEmpty ? '—' : ctrl.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: ctrl.text.isEmpty
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.80),
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
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
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Text(
            'Estado',
            style: TextStyle(
                fontSize: _isEditing ? 13 : 12,
                color: Colors.white.withValues(alpha: _isEditing ? 0.65 : 0.38)),
          ),
          const Spacer(),
          _isEditing
              ? Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor: Colors.green,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                )
              : _statusBadge(_emp.isActive),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    final showChips = _isEditing && _allRoles.isNotEmpty;
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
            child: showChips
                ? Wrap(
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
                  )
                : _emp.roles.isEmpty
                    ? Text('Sin roles asignados',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28), fontSize: 13))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _emp.roles
                            .map((r) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A1240)
                                        .withValues(alpha: 0.80),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Text(r.displayName,
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 12)),
                                ))
                            .toList(),
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
                Icon(Icons.medical_services_outlined,
                    size: 13, color: Colors.white.withValues(alpha: 0.20)),
              ],
            ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: !_isEditing
                ? _emp.specialties.isEmpty
                    ? Text('Sin especialidades asignadas',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.28),
                            fontSize: 13))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _emp.specialties
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3E6A)
                                        .withValues(alpha: 0.70),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.medical_services_outlined,
                                          size: 11,
                                          color: Colors.white.withValues(alpha: 0.55)),
                                      const SizedBox(width: 5),
                                      Text(s.name,
                                          style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.80),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      )
                : _allSpecialties.isEmpty
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
                                  color: Colors.white.withValues(alpha: 0.25),
                                  fontSize: 12)),
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

  Widget _buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _delete,
        icon: Icon(Icons.delete_outline_rounded,
            size: 18, color: AppColors.error.withValues(alpha: 0.70)),
        label: Text(
          'Eliminar empleado',
          style: TextStyle(
              color: AppColors.error.withValues(alpha: 0.70), fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';
import 'package:app_geriatrico/data/models/employee_model.dart';
import 'package:app_geriatrico/data/repositories/employee_repository.dart';
import 'package:app_geriatrico/services/api_services.dart';
import 'package:app_geriatrico/screens/employee_detail_screen.dart';
import 'package:app_geriatrico/screens/employee_create_screen.dart';

class EmployeesScreen extends StatefulWidget {
  final String token;

  const EmployeesScreen({super.key, required this.token});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late final EmployeeRepository _repo;
  List<Employee> _employees = [];
  List<Employee> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // FIX: EmployeeRepository ahora recibe ApiService, no el token directo
    _repo = EmployeeRepository(
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
      final list = await _repo.getAll();
      setState(() {
        _employees = list;
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
      _filtered = _employees.where((e) {
        return e.fullName.toLowerCase().contains(q) ||
            e.email.toLowerCase().contains(q) ||
            e.roles.any((r) => r.displayName.toLowerCase().contains(q));
      }).toList();
    });
  }

  void _openDetail(Employee emp) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailScreen(
          employee: emp,
          token: widget.token,
        ),
      ),
    );
    if (updated == true) _load();
  }

  void _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEmployeeScreen(token: widget.token),
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
                Expanded(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth > 700 ? 860 : double.infinity,
                          ),
                          child: Column(
                            children: [
                              _buildSearchBar(),
                              Expanded(child: _buildBody()),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: const Color(0xFF4A1240),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        tooltip: 'Nuevo empleado',
        child: const Icon(Icons.person_add_outlined, size: 22),
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
          Icon(Icons.people_outline,
              color: Colors.white.withValues(alpha: 0.50), size: 19),
          const SizedBox(width: 10),
          const Text(
            'Empleados',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w300,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          if (_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: Colors.white.withValues(alpha: 0.40),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.refresh_rounded,
                  color: Colors.white.withValues(alpha: 0.50), size: 20),
              onPressed: _load,
              tooltip: 'Actualizar',
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filter,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o rol...',
          hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.30), fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.white.withValues(alpha: 0.35), size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: Colors.white.withValues(alpha: 0.35), size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filter('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
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
            Icon(Icons.wifi_off_rounded,
                color: Colors.white.withValues(alpha: 0.25), size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(foregroundColor: Colors.white54),
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
            Icon(Icons.people_outline,
                color: Colors.white.withValues(alpha: 0.15), size: 56),
            const SizedBox(height: 14),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'Sin resultados para "${_searchCtrl.text}"'
                  : 'No hay empleados registrados',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 80),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildCard(Employee emp) {
    return GestureDetector(
      onTap: () => _openDetail(emp),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF4A1240).withValues(alpha: 0.90),
                child: Text(
                  emp.initials,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            emp.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        if (!emp.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'Inactivo',
                              style: TextStyle(
                                  color: AppColors.error.withValues(alpha: 0.75),
                                  fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      emp.email,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.38),
                          fontSize: 11),
                    ),
                    if (emp.roles.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: emp.roles
                            .map((r) => _roleChip(r.displayName))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Colors.white.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF4A1240).withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70), fontSize: 11),
        ),
      );
}
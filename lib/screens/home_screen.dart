import 'package:flutter/material.dart';
import 'package:app_geriatrico/data/repositories/auth_repository.dart';
import 'package:app_geriatrico/core/app_colors.dart';

import 'package:app_geriatrico/screens/employees_screen.dart';
import 'package:app_geriatrico/screens/patients_screen.dart';
import 'package:app_geriatrico/screens/beds_screen.dart';
import 'package:app_geriatrico/screens/rooms_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Módulo de menú
// ─────────────────────────────────────────────────────────────────────────────
class _NavModule {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _NavModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Módulos por rol
// ─────────────────────────────────────────────────────────────────────────────
const _adminModules = [
  _NavModule(
    id: 'pacientes',
    title: 'Pacientes',
    subtitle: 'Gestión de residentes',
    icon: Icons.elderly_outlined,
    accent: Color(0xFF9C5BB5),
  ),
  _NavModule(
    id: 'familiares',
    title: 'Familiares',
    subtitle: 'Contactos a cargo',
    icon: Icons.family_restroom_outlined,
    accent: Color(0xFF5B8FB5),
  ),
  _NavModule(
    id: 'personal',
    title: 'Personal',
    subtitle: 'Empleados y profesionales',
    icon: Icons.badge_outlined,
    accent: Color(0xFF5BB57A),
  ),
  _NavModule(
    id: 'habitaciones',
    title: 'Habitaciones',
    subtitle: 'Cuartos del establecimiento',
    icon: Icons.door_front_door_outlined,
    accent: Color(0xFF5BB5B0),
  ),
  _NavModule(
    id: 'camas',
    title: 'Camas',
    subtitle: 'Control de ocupación',
    icon: Icons.bed_outlined,
    accent: Color(0xFFB55B5B),
  ),
];

const _profesionalModules = [
  _NavModule(
    id: 'mis_pacientes',
    title: 'Mis Pacientes',
    subtitle: 'Residentes a cargo',
    icon: Icons.elderly_outlined,
    accent: Color(0xFF9C5BB5),
  ),
  _NavModule(
    id: 'evoluciones',
    title: 'Evoluciones',
    subtitle: 'Notas clínicas',
    icon: Icons.assignment_outlined,
    accent: Color(0xFF5B8FB5),
  ),
  _NavModule(
    id: 'prescripciones',
    title: 'Prescripciones',
    subtitle: 'Medicación activa',
    icon: Icons.medication_outlined,
    accent: Color(0xFF5BB57A),
  ),
  _NavModule(
    id: 'estudios',
    title: 'Estudios',
    subtitle: 'Resultados e informes',
    icon: Icons.science_outlined,
    accent: Color(0xFFB5875B),
  ),
  _NavModule(
    id: 'signos_vitales',
    title: 'Signos Vitales',
    subtitle: 'Registro de constantes',
    icon: Icons.monitor_heart_outlined,
    accent: Color(0xFFB55B5B),
  ),
];

const _empleadoModules = [
  _NavModule(
    id: 'pacientes',
    title: 'Pacientes',
    subtitle: 'Ver residentes',
    icon: Icons.elderly_outlined,
    accent: Color(0xFF9C5BB5),
  ),
  _NavModule(
    id: 'camas',
    title: 'Camas',
    subtitle: 'Estado de camas',
    icon: Icons.bed_outlined,
    accent: Color(0xFFB55B5B),
  ),
];

const _familiarModules = [
  _NavModule(
    id: 'mi_familiar',
    title: 'Mi Familiar',
    subtitle: 'Estado y evolución',
    icon: Icons.favorite_outline_rounded,
    accent: Color(0xFF9C5BB5),
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final String userName;
  final String token;
  final List<String> roles; // e.g. ['admin'], ['medico','enfermero'], ['familiar']

  const HomeScreen({
    super.key,
    required this.userName,
    required this.token,
    this.roles = const [],
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── helpers ───────────────────────────────────────────────────────────────
  bool get _isAdmin => widget.roles.contains('admin');
  bool get _isFamiliar => widget.roles.contains('familiar');
  bool get _isProfesional =>
      widget.roles.any((r) => ['medico', 'enfermero', 'profesional'].contains(r));

  String get _roleLabel {
    if (_isAdmin) return 'Administrador';
    if (_isProfesional) return 'Profesional';
    if (_isFamiliar) return 'Familiar';
    return 'Empleado';
  }

  List<_NavModule> get _modules {
    if (_isAdmin) return _adminModules;
    if (_isProfesional) return _profesionalModules;
    if (_isFamiliar) return _familiarModules;
    return _empleadoModules;
  }

  // ── nav items for sidebar (desktop) ─────────────────────────────────────
  List<_NavModule> get _sidebarItems => _modules;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final success = await AuthRepository().logout(widget.token);
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Error al cerrar sesión'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    }
  }

  // ── navigate to module ────────────────────────────────────────────────────
  void _navigate(_NavModule module) {
    Widget? screen;

    switch (module.id) {
      case 'pacientes':
      case 'mis_pacientes':
        screen = PatientsScreen(token: widget.token);
        break;
      case 'habitaciones':
        screen = RoomsScreen(token: widget.token);
        break;
      case 'camas':
        screen = BedsScreen(token: widget.token);
        break;
      case 'personal':
        screen = EmployeesScreen(token: widget.token);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Módulo "${module.title}" próximamente'),
          backgroundColor: AppColors.primaryDark.withValues(alpha: 0.92),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ));
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: LayoutBuilder(
        builder: (ctx, constraints) =>
            constraints.maxWidth > 900 ? _desktop() : _mobile(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DESKTOP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _desktop() {
    return Scaffold(
      body: Stack(
        children: [
          _background(),
          Row(children: [
            _sidebar(),
            Expanded(child: _mainContent()),
          ]),
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

  // ── Sidebar ───────────────────────────────────────────────────────────────
  Widget _sidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A1240), Color(0xFF3A0B32), Color(0xFF2A0825)],
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Column(children: [
        const SizedBox(height: 28),
        // Logo + nombre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ],
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.85), width: 1.5),
              ),
              padding: const EdgeInsets.all(7),
              child: Image.asset('assets/images/LogoCarlota.png',
                  fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Residencia',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.45),
                            letterSpacing: 1.5)),
                    const Text('Carlota',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: 1)),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _divider(),
        const SizedBox(height: 12),
        // Rol badge
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shield_outlined,
                  size: 11, color: Colors.white.withValues(alpha: 0.50)),
              const SizedBox(width: 5),
              Text(
                _roleLabel,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.5),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _sectionLabel('MENÚ'),
        const SizedBox(height: 6),
        // Items dinámicos
        ..._sidebarItems.asMap().entries.map((e) {
          final index = e.key;
          final mod = e.value;
          return _sidebarItem(mod.icon, mod.title, index,
              accent: mod.accent, onTap: () => _navigate(mod));
        }),
        const Spacer(),
        _divider(),
        const SizedBox(height: 4),
        _sidebarItem(Icons.logout_rounded, 'Cerrar sesión', -1,
            onTap: _logout),
        const SizedBox(height: 20),
      ]),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white.withValues(alpha: 0.08),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.30),
                  fontWeight: FontWeight.w500)),
        ),
      );

  Widget _sidebarItem(
    IconData icon,
    String title,
    int index, {
    VoidCallback? onTap,
    Color? accent,
  }) {
    final isSelected = _selectedIndex == index && index != -1;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected
            ? (accent ?? Colors.white).withValues(alpha: 0.12)
            : Colors.transparent,
        border: isSelected
            ? Border.all(
                color: (accent ?? Colors.white).withValues(alpha: 0.20))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon,
            size: 20,
            color: isSelected
                ? (accent ?? Colors.white)
                : Colors.white.withValues(alpha: 0.50)),
        title: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w400 : FontWeight.w300,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.50),
                letterSpacing: 0.2)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          if (onTap != null) {
            onTap();
            return;
          }
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _mainContent() => Column(children: [
        _topBar(),
        Expanded(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: _dashboard())),
      ]);

  Widget _topBar() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.07)),
          ),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bienvenido de vuelta',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.3)),
            const SizedBox(height: 2),
            Text(widget.userName,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                    letterSpacing: 0.5)),
          ]),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
              const SizedBox(width: 6),
              Text('En línea',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65))),
            ]),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(Icons.person_outline_rounded,
                color: Colors.white.withValues(alpha: 0.75), size: 18),
          ),
        ]),
      );

  // ── Dashboard grid ────────────────────────────────────────────────────────
  Widget _dashboard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Panel principal',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w200,
                      color: Colors.white,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Seleccioná un módulo para continuar',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.40))),
              Container(
                width: 40,
                height: 1,
                color: Colors.white.withValues(alpha: 0.20),
                margin: const EdgeInsets.symmetric(vertical: 18),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _modules.length,
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (_, i) => _moduleCard(_modules[i]),
              ),
            ]),
      ),
    );
  }

  Widget _moduleCard(_NavModule mod) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _navigate(mod),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: mod.accent.withValues(alpha: 0.20), width: 1),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: mod.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
              border:
                  Border.all(color: mod.accent.withValues(alpha: 0.30)),
            ),
            child: Icon(mod.icon,
                size: 21, color: mod.accent.withValues(alpha: 0.90)),
          ),
          const Spacer(),
          Text(mod.title,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Text(mod.subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.40))),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOBILE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _mobile() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5),
                radius: 1.4,
                colors: [
                  Color(0xFF6A1B5D),
                  Color(0xFF3A0B32),
                  Color(0xFF1E0619)
                ],
                stops: [0.0, 0.50, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(children: [
              _mobileAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _mobileRoleBadge(),
                        const SizedBox(height: 20),
                        Text('Panel principal',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w200,
                                color: Colors.white,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 4),
                        Text('Seleccioná un módulo',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white
                                    .withValues(alpha: 0.40))),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount: _modules.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemBuilder: (_, i) =>
                              _moduleCard(_modules[i]),
                        ),
                        const SizedBox(height: 24),
                      ]),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _mobileRoleBadge() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.shield_outlined,
              size: 13, color: Colors.white.withValues(alpha: 0.50)),
          const SizedBox(width: 6),
          Text(_roleLabel,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.60),
                  letterSpacing: 0.4)),
        ]),
      );

  Widget _mobileAppBar() => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 1.5),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset('assets/images/LogoCarlota.png',
                fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hola, ${widget.userName}',
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w300)),
            Text('Residencia Carlota',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.45),
                    letterSpacing: 0.5)),
          ]),
          const Spacer(),
          PopupMenuButton<String>(
            color: const Color(0xFF3A0B32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10)),
            ),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Icon(Icons.person_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.75), size: 18),
            ),
            onSelected: (v) {
              if (v == 'logout') _logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(children: [
                  Icon(Icons.logout_rounded,
                      size: 16,
                      color: AppColors.error.withValues(alpha: 0.80)),
                  const SizedBox(width: 8),
                  Text('Cerrar sesión',
                      style: TextStyle(
                          color: AppColors.error.withValues(alpha: 0.80))),
                ]),
              ),
            ],
          ),
        ]),
      );
}
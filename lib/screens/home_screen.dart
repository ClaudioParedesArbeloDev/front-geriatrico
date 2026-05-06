import 'package:flutter/material.dart';
import 'package:app_geriatrico/services/auth_services.dart';
import 'package:app_geriatrico/core/app_colors.dart';

import 'package:app_geriatrico/screens/employees_screen.dart';
import 'package:app_geriatrico/screens/patients_screen.dart';
import 'package:app_geriatrico/screens/beds_screen.dart';


class HomeScreen extends StatefulWidget {
  final String userName;
  final String token;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.token,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int selectedIndex = 0;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    final success = await AuthService.logout(widget.token);
    if (!mounted) return;
    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al cerrar sesión'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _navigate(String title) {
    switch (title) {
      case 'Empleados':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => EmployeesScreen(token: widget.token)),
        );
        break;
      case 'Pacientes':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PatientsScreen(token: widget.token)),
        );
        break;
      case 'Camas':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BedsScreen(token: widget.token)),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Módulo "$title" próximamente'),
            backgroundColor: AppColors.primaryDark.withValues(alpha: 0.90),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth > 900 ? _desktop() : _mobile(),
      ),
    );
  }

  Widget _desktop() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E0619),
                  Color(0xFF2A0825),
                  Color(0xFF1A051A),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _sidebar(),
              Expanded(child: _mainContent()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebar() {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A1240),
            Color(0xFF3A0B32),
            Color(0xFF2A0825),
          ],
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.07), width: 1),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
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
                      ),
                    ],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                  ),
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/images/LogoCarlota.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Residencia',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.45),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Text(
                        'Carlota',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MENÚ',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.30),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _menuItem(Icons.dashboard_outlined, 'Dashboard', 0),
          _menuItem(Icons.elderly_outlined, 'Pacientes', 1),
          _menuItem(Icons.bed_outlined, 'Camas', 2),
          _menuItem(Icons.people_outline, 'Empleados', 3),
          _menuItem(Icons.event_outlined, 'Actividades', 4),
          const Spacer(),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 8),
          _menuItem(Icons.logout_rounded, 'Cerrar sesión', -1, onTap: logout),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _mainContent() {
    return Column(
      children: [
        _topBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _dashboard(),
          ),
        ),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07), width: 1),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido de vuelta',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                const SizedBox(width: 6),
                Text(
                  'En línea',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.white.withValues(alpha: 0.75),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

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
                  Color(0xFF1E0619),
                ],
                stops: [0.0, 0.50, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _mobileAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _dashboard(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white.withValues(alpha: 0.90), width: 1.5),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset('assets/images/LogoCarlota.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${widget.userName}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                'Residencia Carlota',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          PopupMenuButton<String>(
            color: const Color(0xFF3A0B32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                color: Colors.white.withValues(alpha: 0.75),
                size: 18,
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') logout();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 16, color: AppColors.error.withValues(alpha: 0.80)),
                    const SizedBox(width: 8),
                    Text('Cerrar sesión',
                        style: TextStyle(color: AppColors.error.withValues(alpha: 0.80))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final modules = [
      _ModuleItem('Pacientes', Icons.elderly_outlined, 'Gestión de residentes'),
      _ModuleItem('Camas', Icons.bed_outlined, 'Control de ocupación'),
      _ModuleItem('Empleados', Icons.people_outline, 'Personal activo'),
      _ModuleItem('Actividades', Icons.event_outlined, 'Agenda de actividades'),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel principal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seleccioná un módulo para continuar',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ),
            Container(
              width: 40,
              height: 1,
              color: Colors.white.withValues(alpha: 0.20),
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: modules.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) => _moduleCard(modules[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(_ModuleItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _navigate(item.title),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Icon(item.icon, size: 20, color: Colors.white.withValues(alpha: 0.80)),
            ),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    int index, {
    VoidCallback? onTap,
  }) {
    final isSelected = selectedIndex == index && index != -1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        border: isSelected
            ? Border.all(color: Colors.white.withValues(alpha: 0.16))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.50),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.50),
            letterSpacing: 0.2,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () {
          if (onTap != null) {
            onTap();
            return;
          }

          // Navigate to module
          final moduleTitles = ['', 'Pacientes', 'Camas', 'Empleados', 'Actividades'];
          if (index > 0 && index < moduleTitles.length) {
            _navigate(moduleTitles[index]);
            return;
          }

          if (index == -1) return;
          setState(() => selectedIndex = index);
        },
      ),
    );
  }
}

class _ModuleItem {
  final String title;
  final IconData icon;
  final String subtitle;
  const _ModuleItem(this.title, this.icon, this.subtitle);
}
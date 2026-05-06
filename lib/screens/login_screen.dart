import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/data/repositories/auth_repository.dart';
import 'package:app_geriatrico/screens/home_screen.dart';
import 'package:app_geriatrico/screens/forgot_password_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final authRepo           = AuthRepository();
  final formKey            = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool loading         = false;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryOpacity;
  late final Animation<Offset>   _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 750));
    _entryOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      final response = await authRepo.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;
      emailController.clear();
      passwordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bienvenido ${response.user['name']}')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName:  response.user['name'],
            token:     response.accessToken,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.6),
                radius: 1.6,
                colors: [
                  Color(0xFF7B2268),
                  Color(0xFF6A1B5D),
                  Color(0xFF3A0B32),
                  Color(0xFF1E0619),
                ],
                stops: [0.0, 0.30, 0.65, 1.0],
              ),
            ),
          ),

          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _LoginBgPainter(),
          ),

          LayoutBuilder(
            builder: (context, constraints) =>
                constraints.maxWidth > 900
                    ? _desktop(constraints)
                    : _mobile(),
          ),
        ],
      ),
    );
  }

  Widget _desktop(BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _LeftPanel(),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SlideTransition(
                position: _entrySlide,
                child: FadeTransition(
                  opacity: _entryOpacity,
                  child: _GlassCard(child: _formContent()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  
  Widget _mobile() {
    return SafeArea(
      child: Center(
        child: SlideTransition(
          position: _entrySlide,
          child: FadeTransition(
            opacity: _entryOpacity,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _GlassCard(child: _formContent()),
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _formContent() {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [


          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.20),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.90),
                  width: 2.5,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/LogoCarlota.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'RESIDENCIA CARLOTA',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 3.5,
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Center(
            child: Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w200,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              'Ingresá para continuar',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 0.3,
              ),
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Container(
              width: 40,
              height: 1,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),

          const SizedBox(height: 24),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: _inputDecoration(
              label: 'Usuario o Email',
              icon: Icons.person_outline_rounded,
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Ingresá tu usuario' : null,
          ),

          const SizedBox(height: 14),


          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: const TextStyle(fontSize: 14, color: Colors.white),
            decoration: _inputDecoration(
              label: 'Contraseña',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
              ),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Ingresá tu contraseña' : null,
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen()),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.70),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              ),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(fontSize: 12.5, letterSpacing: 0.2),
              ),
            ),
          ),

          const SizedBox(height: 6),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.25),
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Text(
                      'Ingresar',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
                Text(
                  'Code & Lens Solutions',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.8,
                    color: Colors.white.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13.5,
        color: Colors.white.withValues(alpha: 0.50),
        letterSpacing: 0.2,
      ),
      prefixIcon: Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.50)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.60),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [


          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
            ),
            padding: const EdgeInsets.all(12),
            child: Lottie.asset(
              'assets/animations/doctor.json',
              fit: BoxFit.contain,
            ),
          ),

          const Spacer(),

          Text(
            'Gestión\nIntegral',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              letterSpacing: 2,
              height: 1.12,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: 50,
            height: 1.5,
            color: Colors.white.withValues(alpha: 0.40),
          ),

          const SizedBox(height: 22),

          Text(
            'Residencia Carlota centraliza el cuidado,\nel bienestar y la gestión de la residencia\nen un solo lugar.',
            style: TextStyle(
              fontSize: 14,
              height: 1.75,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 0.2,
              fontWeight: FontWeight.w300,
            ),
          ),

          /* const SizedBox(height: 44), */

          /* 
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _ModuleChip(icon: Icons.elderly_outlined,   label: 'Pacientes'),
              _ModuleChip(icon: Icons.bed_outlined,        label: 'Camas'),
              _ModuleChip(icon: Icons.medication_outlined, label: 'Medicación'),
              _ModuleChip(icon: Icons.event_outlined,      label: 'Actividades'),
              _ModuleChip(icon: Icons.people_outline,      label: 'Empleados'),
              _ModuleChip(icon: Icons.history,             label: 'Historial'),
            ],
          ), */

          /* const SizedBox(height: 48), */
        ],
      ),
    );
  }
}

/* class _ModuleChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _ModuleChip({required this.icon, required this.label});
 */
/*   @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.09),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.70)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.70),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
 */

class _LoginBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width * 2; i += 70) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height * 0.55, size.height), p);
    }

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.75),
      size.width * 0.60,
      p..color = Colors.white.withValues(alpha: 0.025),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
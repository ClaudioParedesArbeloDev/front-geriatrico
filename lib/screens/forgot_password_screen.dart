import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:app_geriatrico/core/app_colors.dart';
import 'package:app_geriatrico/core/config.dart';

import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  bool loading = false;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _entryOpacity;
  late final Animation<Offset>   _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entrySlide = Tween<Offset>(
            begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> sendReset() async {
    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text.trim()}),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (response.statusCode == 200) {
        emailController.clear();
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.60),
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF3A0B32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            title: const Text(
              'Correo enviado',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, letterSpacing: 1),
            ),
            content: Text(
              'Revisá tu email para continuar con el restablecimiento.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.60), height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.80), letterSpacing: 1),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al enviar el correo'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error de conexión'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
                center: Alignment(0.3, -0.5),
                radius: 1.5,
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
            painter: _ForgotBgPainter(),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withValues(alpha: 0.75),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Recuperar Contraseña',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                if (!isDesktop) {
                  return _mobileLayout();
                }
                return _desktopLayout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/animations/Password.json',
                  height: 260,
                ),
                const SizedBox(height: 20),
                Text(
                  'Seguridad ante todo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w200,
                    color: Colors.white.withValues(alpha: 0.80),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Te enviaremos instrucciones por email',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),

        Container(
          width: 1,
          height: double.infinity,
          color: Colors.white.withValues(alpha: 0.08),
        ),


        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SlideTransition(
                position: _entrySlide,
                child: FadeTransition(
                  opacity: _entryOpacity,
                  child: _GlassCard(child: _buildForm()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileLayout() {
    return Center(
      child: SlideTransition(
        position: _entrySlide,
        child: FadeTransition(
          opacity: _entryOpacity,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _GlassCard(child: _buildForm()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.20),
                blurRadius: 25,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.90),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            'assets/images/LogoCarlota.png',
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w200,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 10),

        Text(
          'Ingresá tu email y te enviaremos\nlas instrucciones para restablecer',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.50),
            height: 1.6,
          ),
        ),

        const SizedBox(height: 28),

        Container(width: 36, height: 1, color: Colors.white.withValues(alpha: 0.20)),

        const SizedBox(height: 24),

        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
              fontSize: 13.5,
              color: Colors.white.withValues(alpha: 0.50),
            ),
            prefixIcon: Icon(Icons.email_outlined, size: 20, color: Colors.white.withValues(alpha: 0.50)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.60), width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 22),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: loading ? null : sendReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.20),
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
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
                    'Enviar instrucciones',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 4),
      ],
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

class _ForgotBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (double i = -size.height; i < size.width * 2; i += 70) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height * 0.55, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'admin_screens.dart';
import 'alumno_screens.dart';
import 'auth_screens.dart';
import 'docente_screens.dart';

/// Decide qué mostrar según la sesión: Login o la interfaz del rol.
class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().actual;
    if (u == null) return const LoginScreen();
    switch (u.rol) {
      case Rol.admin:
        return const AdminShell();
      case Rol.docente:
        return const DocenteShell();
      case Rol.alumno:
        return const AlumnoShell();
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const Root(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween(begin: .85, end: 1.0).animate(fade),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const RLLogo(size: 110),
                const SizedBox(height: 24),
                const Text('RappoLink',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: RL.text)),
                const SizedBox(height: 6),
                const Text('Conecta. Comunica. Respeta.',
                    style: TextStyle(color: RL.muted, fontSize: 14)),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

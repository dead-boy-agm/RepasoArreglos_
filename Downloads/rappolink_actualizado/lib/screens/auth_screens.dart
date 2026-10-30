import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';

final _emailRe = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');

String? validarCorreo(String? v) {
  final t = (v ?? '').trim();
  if (t.isEmpty) return 'Ingresa tu correo institucional';
  if (!_emailRe.hasMatch(t)) return 'Correo no válido (usuario@institucion.edu.mx)';
  return null;
}

String? validarPassword(String? v) {
  if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
  if (v.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

// ===================================================================== LOGIN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _pass = TextEditingController();
  bool _ver = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _entrar() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final err = context.read<AppState>().login(_correo.text, _pass.text);
    if (err != null) setState(() => _error = err);
    // Si es null, Root detecta la sesión y muestra la interfaz del rol.
  }

  void _demo(String correo, String pass) {
    _correo.text = correo;
    _pass.text = pass;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const Center(child: RLLogo(size: 78)),
                  const SizedBox(height: 18),
                  const Text('RappoLink',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: RL.text)),
                  const SizedBox(height: 4),
                  const Text('Bienvenido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: RL.primary)),
                  const SizedBox(height: 4),
                  const Text('Inicia sesión con tu cuenta institucional',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: RL.muted)),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    validator: validarCorreo,
                    decoration: const InputDecoration(
                      labelText: 'Correo institucional',
                      hintText: 'usuario@institucion.edu.mx',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass,
                    obscureText: !_ver,
                    validator: validarPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _ver ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _ver = !_ver),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: RL.redSoft,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.error_outline,
                            color: RL.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(color: RL.red))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                      onPressed: _entrar, child: const Text('INICIAR SESIÓN')),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RecuperarAccesoScreen())),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                  const Text(
                    'Las cuentas las crea la administración de tu institución.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: RL.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  const Text('Cuentas de prueba (toca para rellenar)',
                      style: TextStyle(color: RL.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    ActionChip(
                        label: const Text('Administrador'),
                        onPressed: () => _demo(
                            'admin@institucion.edu.mx', 'admin123')),
                    ActionChip(
                        label: const Text('Docente'),
                        onPressed: () => _demo(
                            'carlos@institucion.edu.mx', 'docente123')),
                    ActionChip(
                        label: const Text('Alumno'),
                        onPressed: () => _demo(
                            'angel@institucion.edu.mx', 'alumno123')),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}

// ====================================================== RECUPERAR ACCESO
class RecuperarAccesoScreen extends StatefulWidget {
  const RecuperarAccesoScreen({super.key});
  @override
  State<RecuperarAccesoScreen> createState() => _RecuperarAccesoScreenState();
}

class _RecuperarAccesoScreenState extends State<RecuperarAccesoScreen> {
  final _form = GlobalKey<FormState>();
  final _correo = TextEditingController();
  bool _enviado = false;

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_form.currentState!.validate()) return;
    context.read<AppState>().solicitarRecuperacion(_correo.text);
    // Mismo aviso exista o no el correo: no se revela si está registrado.
    setState(() => _enviado = true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Recuperar acceso')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _enviado ? _confirmacion(context) : _formulario(),
          ),
        ),
      );

  Widget _formulario() => Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Center(
                child: CircleAvatar(
                    radius: 40,
                    backgroundColor: RL.soft,
                    child: Icon(Icons.lock_reset, size: 40, color: RL.primary))),
            const SizedBox(height: 20),
            const Text('¿Olvidaste tu contraseña?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: RL.text)),
            const SizedBox(height: 8),
            const Text(
              'Escribe tu correo institucional y te enviaremos un enlace o '
              'código para restablecerla.',
              textAlign: TextAlign.center,
              style: TextStyle(color: RL.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _correo,
              keyboardType: TextInputType.emailAddress,
              validator: validarCorreo,
              decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                  prefixIcon: Icon(Icons.mail_outline)),
            ),
            const SizedBox(height: 22),
            FilledButton(
                onPressed: _enviar, child: const Text('ENVIAR ENLACE')),
          ],
        ),
      );

  Widget _confirmacion(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Center(
              child: CircleAvatar(
                  radius: 40,
                  backgroundColor: RL.greenSoft,
                  child: Icon(Icons.mark_email_read_outlined,
                      size: 40, color: RL.green))),
          const SizedBox(height: 20),
          const Text('Revisa tu correo',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: RL.text)),
          const SizedBox(height: 8),
          const Text(
            'Si el correo está registrado, recibirás un enlace o código para '
            'restablecer tu contraseña. Revisa también la carpeta de spam.\n\n'
            '¿No te llega nada? Pide a la administración que restablezca tu '
            'contraseña.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RL.muted, height: 1.4),
          ),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('VOLVER AL INICIO DE SESIÓN')),
        ],
      );
}

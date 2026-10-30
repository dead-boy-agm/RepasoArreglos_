import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.actual!;
    final grupo = u.rol == Rol.alumno ? s.grupoDe(u.id) : null;
    return Column(
      children: [
        const TabHeader(title: 'Perfil', subtitle: 'Cuenta institucional'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RLCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    UserAvatar(u, size: 72),
                    const SizedBox(height: 12),
                    Text(u.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: RL.text)),
                    const SizedBox(height: 2),
                    Text(u.correo, style: const TextStyle(color: RL.muted)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: [
                      Pill(s.nombreRol(u)),
                      if (grupo != null)
                        Pill(grupo, color: RL.violet, bg: RL.violetSoft),
                    ]),
                  ],
                ),
              ),
              const SectionLabel('Mi cuenta'),
              ActionTile(
                icon: Icons.edit_outlined,
                title: 'Editar datos',
                subtitle: 'Nombre, apellido y foto de perfil',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PerfilEditarScreen())),
              ),
              ActionTile(
                icon: Icons.lock_outline,
                title: 'Cambiar contraseña',
                subtitle: 'Se guarda cifrada y nunca se muestra',
                color: RL.violet,
                bg: RL.violetSoft,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CambiarPasswordScreen())),
              ),
              const SectionLabel('Preferencias · horario de atención'),
              RLCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modo de demostración: fuerza si los docentes están dentro o fuera de horario para probar los mensajes programados.',
                      style: TextStyle(color: RL.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ModoHorario>(
                        segments: const [
                          ButtonSegment(
                              value: ModoHorario.auto, label: Text('Real')),
                          ButtonSegment(
                              value: ModoHorario.dentro, label: Text('Dentro')),
                          ButtonSegment(
                              value: ModoHorario.fuera, label: Text('Fuera')),
                        ],
                        selected: {s.modoHorario},
                        onSelectionChanged: (v) => s.setModoHorario(v.first),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: RL.red,
                  side: const BorderSide(color: RL.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: () => s.logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================ EDITAR PERFIL
class PerfilEditarScreen extends StatefulWidget {
  const PerfilEditarScreen({super.key});
  @override
  State<PerfilEditarScreen> createState() => _PerfilEditarScreenState();
}

class _PerfilEditarScreenState extends State<PerfilEditarScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  Uint8List? _foto;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().actual!;
    _nombre = TextEditingController(text: u.nombrePila);
    _apellido = TextEditingController(text: u.apellido);
    _foto = u.foto;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final b = await elegirFoto(context);
    if (b != null && mounted) setState(() => _foto = b);
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final err = context.read<AppState>().actualizarPerfil(
        nombre: _nombre.text, apellido: _apellido.text, foto: _foto);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, 'Perfil actualizado');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final u = context.watch<AppState>().actual!;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar datos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Avatar(u.inicial, size: 88, foto: _foto)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                OutlinedButton.icon(
                    onPressed: _elegirFoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cambiar foto')),
                if (_foto != null)
                  TextButton(
                      onPressed: () => setState(() => _foto = null),
                      child: const Text('Quitar')),
              ]),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Ingresa tu nombre'
                    : null,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _apellido,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: u.correo,
                enabled: false,
                decoration: const InputDecoration(
                    labelText: 'Correo institucional',
                    helperText: 'Solo la administración puede cambiarlo.'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBox(_error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: _guardar, child: const Text('GUARDAR CAMBIOS')),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================== CAMBIAR CONTRASEÑA
class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});
  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirma = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirma.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final err =
        context.read<AppState>().cambiarPassword(_actual.text, _nueva.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, 'Contraseña actualizada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cambiar contraseña')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _actual,
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Ingresa tu contraseña actual' : null,
                  decoration:
                      const InputDecoration(labelText: 'Contraseña actual'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nueva,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                  decoration:
                      const InputDecoration(labelText: 'Nueva contraseña'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirma,
                  obscureText: true,
                  validator: (v) =>
                      v != _nueva.text ? 'Las contraseñas no coinciden' : null,
                  decoration: const InputDecoration(
                      labelText: 'Confirmar nueva contraseña'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  ErrorBox(_error!),
                ],
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: _guardar,
                    child: const Text('ACTUALIZAR CONTRASEÑA')),
              ],
            ),
          ),
        ),
      );
}

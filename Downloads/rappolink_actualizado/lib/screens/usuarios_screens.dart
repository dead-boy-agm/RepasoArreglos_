import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';
import 'auth_screens.dart';

// ============================================================ USUARIOS Y ROLES
class UsuariosRolesScreen extends StatelessWidget {
  const UsuariosRolesScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabHeader(
                title: 'Usuarios y roles',
                subtitle: 'Cuentas, accesos y permisos'),
            Container(
              color: Colors.white,
              child: const TabBar(
                tabs: [Tab(text: 'Usuarios'), Tab(text: 'Roles')],
              ),
            ),
            const Expanded(
              child: TabBarView(children: [UsuariosTab(), RolesTab()]),
            ),
          ],
        ),
      );
}

class _Dato extends StatelessWidget {
  final String label;
  final String valor;
  const _Dato(this.label, this.valor);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 130,
                child: Text(label,
                    style: const TextStyle(color: RL.muted, fontSize: 13))),
            Expanded(
                child: Text(valor,
                    style: const TextStyle(
                        color: RL.text, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

// ================================================================== USUARIOS
class UsuariosTab extends StatefulWidget {
  const UsuariosTab({super.key});
  @override
  State<UsuariosTab> createState() => _UsuariosTabState();
}

class _UsuariosTabState extends State<UsuariosTab> {
  String _q = '';
  String _rol = 'Todos';
  String _estado = 'Todos';

  void _consultar(Usuario u) {
    final s = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: UserAvatar(u, size: 72)),
              const SizedBox(height: 10),
              Center(
                child: Text(u.nombre,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: RL.text)),
              ),
              const SizedBox(height: 12),
              _Dato('Nombre', u.nombrePila),
              _Dato('Apellido', u.apellido.isEmpty ? '—' : u.apellido),
              _Dato('Correo', u.correo),
              _Dato('Rol', s.nombreRol(u)),
              _Dato('Estado', u.activo ? 'Activo' : 'Inactivo'),
              _Dato('Fecha de registro', fmtFecha(u.fechaRegistro)),
              if (u.rol == Rol.alumno)
                _Dato('Grupo', s.grupoDe(u.id) ?? 'Sin inscripción activa'),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => UsuarioFormScreen(usuario: u)));
                },
                child: const Text('EDITAR USUARIO'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lista = s.usuarios.where((u) {
      final txt = '${u.nombre} ${u.correo}'.toLowerCase();
      if (!txt.contains(_q.toLowerCase())) return false;
      if (_rol != 'Todos' && s.nombreRol(u) != _rol) return false;
      if (_estado == 'Activos' && !u.activo) return false;
      if (_estado == 'Inactivos' && u.activo) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: RL.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const UsuarioFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SearchField(
              hint: 'Buscar por nombre o correo...',
              onChanged: (v) => setState(() => _q = v)),
          ChipsFiltro(
            opciones: ['Todos', ...s.roles.map((r) => r.nombre)],
            valor: _rol,
            onChanged: (v) => setState(() => _rol = v),
          ),
          ChipsFiltro(
            opciones: const ['Todos', 'Activos', 'Inactivos'],
            valor: _estado,
            onChanged: (v) => setState(() => _estado = v),
          ),
          Expanded(
            child: lista.isEmpty
                ? const EmptyState(
                    icon: Icons.person_search,
                    title: 'No hay usuarios',
                    subtitle: 'Ningún usuario coincide con los filtros.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final u = lista[i];
                      return RLCard(
                        onTap: () => _consultar(u),
                        child: Row(
                          children: [
                            UserAvatar(u),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: RL.text)),
                                  Text(u.correo,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: RL.muted, fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 6, runSpacing: 4, children: [
                                    Pill(s.nombreRol(u),
                                        color: RL.violet, bg: RL.violetSoft),
                                    EstadoPill(u.activo),
                                    Pill('Registro ${fmtFecha(u.fechaRegistro)}',
                                        color: RL.muted, bg: RL.bg),
                                  ]),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'ver') _consultar(u);
                                if (v == 'editar') {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) =>
                                          UsuarioFormScreen(usuario: u)));
                                }
                                if (v == 'estado') {
                                  final err = s.toggleActivo(u);
                                  if (err != null) {
                                    snack(context, err, error: true);
                                  }
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'ver', child: Text('Consultar')),
                                const PopupMenuItem(
                                    value: 'editar', child: Text('Editar')),
                                PopupMenuItem(
                                    value: 'estado',
                                    child: Text(
                                        u.activo ? 'Desactivar' : 'Activar')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ======================================================== FORMULARIO: USUARIO
class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;
  const UsuarioFormScreen({super.key, this.usuario});
  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _apellido;
  late final TextEditingController _correo;
  final _pass = TextEditingController();
  String? _rolId;
  bool _activo = true;
  Uint8List? _foto;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombre = TextEditingController(text: u?.nombrePila ?? '');
    _apellido = TextEditingController(text: u?.apellido ?? '');
    _correo = TextEditingController(text: u?.correo ?? '');
    _rolId = u?.rolId;
    _activo = u?.activo ?? true;
    _foto = u?.foto;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _elegirFoto() async {
    final b = await elegirFoto(context);
    if (b != null && mounted) setState(() => _foto = b);
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final rol = s.rolInfo(_rolId!);
    final u = widget.usuario;
    final err = u == null
        ? s.crearUsuario(
            nombre: _nombre.text,
            apellido: _apellido.text,
            correo: _correo.text,
            password: _pass.text,
            rol: rol,
            activo: _activo,
            foto: _foto)
        : s.editarUsuario(u,
            nombre: _nombre.text,
            apellido: _apellido.text,
            correo: _correo.text,
            rol: rol,
            activo: _activo,
            foto: _foto,
            nuevaPassword: _pass.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, u == null ? 'Usuario creado correctamente' : 'Cambios guardados');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final nuevo = widget.usuario == null;
    final esYo = !nuevo && s.actual?.id == widget.usuario!.id;
    final roles = s.roles.where((r) => r.activo || r.id == _rolId).toList();

    return Scaffold(
      appBar: AppBar(title: Text(nuevo ? 'Nuevo usuario' : 'Editar usuario')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Avatar(
                    _nombre.text.isEmpty ? '?' : _nombre.text[0].toUpperCase(),
                    size: 72,
                    foto: _foto),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                        onPressed: _elegirFoto,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Foto')),
                    if (_foto != null)
                      TextButton(
                          onPressed: () => setState(() => _foto = null),
                          child: const Text('Quitar')),
                  ]),
                ),
              ]),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Ingresa el nombre'
                    : null,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _apellido,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Ingresa el apellido'
                    : null,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                validator: validarCorreo,
                decoration:
                    const InputDecoration(labelText: 'Correo institucional'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _rolId,
                hint: const Text('Selecciona un rol'),
                items: roles
                    .map((r) =>
                        DropdownMenuItem(value: r.id, child: Text(r.nombre)))
                    .toList(),
                onChanged: esYo ? null : (v) => setState(() => _rolId = v),
                validator: (v) => v == null ? 'Selecciona un rol' : null,
                decoration: const InputDecoration(labelText: 'Rol'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: true,
                validator: nuevo
                    ? validarPassword
                    : (v) => (v == null || v.isEmpty || v.length >= 6)
                        ? null
                        : 'Mínimo 6 caracteres',
                decoration: InputDecoration(
                  labelText:
                      nuevo ? 'Contraseña inicial' : 'Restablecer contraseña',
                  helperText: nuevo
                      ? 'Se guarda cifrada y no se vuelve a mostrar.'
                      : 'Déjala vacía para conservar la actual.',
                ),
              ),
              const SizedBox(height: 14),
              CampoEstado(
                  activo: _activo,
                  onChanged: esYo ? null : (v) => setState(() => _activo = v)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBox(_error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: _guardar,
                  child: Text(nuevo ? 'CREAR USUARIO' : 'GUARDAR CAMBIOS')),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================== ROLES
class RolesTab extends StatelessWidget {
  const RolesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: RL.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const RolFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          for (final r in s.roles)
            RLCard(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RolFormScreen(rol: r))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(r.nombre.isEmpty ? '?' : r.nombre[0].toUpperCase(),
                      bg: RL.violetSoft, fg: RL.violet),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: RL.text)),
                        const SizedBox(height: 2),
                        Text(r.descripcion,
                            style:
                                const TextStyle(color: RL.muted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 4, children: [
                          Pill(nivelAccesoTexto(r.nivel)),
                          EstadoPill(r.activo),
                          Pill('${s.usuariosConRol(r)} usuarios',
                              color: RL.muted, bg: RL.bg),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: RL.muted),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ========================================================== FORMULARIO: ROL
class RolFormScreen extends StatefulWidget {
  final RolInfo? rol;
  const RolFormScreen({super.key, this.rol});
  @override
  State<RolFormScreen> createState() => _RolFormScreenState();
}

class _RolFormScreenState extends State<RolFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _desc;
  int _nivel = 1;
  Rol _tipo = Rol.alumno;
  bool _activo = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.rol;
    _nombre = TextEditingController(text: r?.nombre ?? '');
    _desc = TextEditingController(text: r?.descripcion ?? '');
    _nivel = r?.nivel ?? 1;
    _tipo = r?.tipo ?? Rol.alumno;
    _activo = r?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final r = widget.rol;
    final err = r == null
        ? s.crearRol(
            nombre: _nombre.text,
            descripcion: _desc.text,
            nivel: _nivel,
            tipo: _tipo,
            activo: _activo)
        : s.editarRol(r,
            nombre: _nombre.text,
            descripcion: _desc.text,
            nivel: _nivel,
            activo: _activo);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, r == null ? 'Rol creado' : 'Rol actualizado');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nuevo = widget.rol == null;
    return Scaffold(
      appBar: AppBar(title: Text(nuevo ? 'Nuevo rol' : 'Editar rol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Ingresa el nombre del rol'
                    : null,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _desc,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Agrega una descripción'
                    : null,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Rol>(
                value: _tipo,
                items: Rol.values
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r.nombre)))
                    .toList(),
                onChanged: nuevo ? (v) => setState(() => _tipo = v ?? _tipo) : null,
                decoration: InputDecoration(
                  labelText: 'Tipo de interfaz',
                  helperText: nuevo
                      ? 'Define qué pantallas y permisos base usará este rol.'
                      : 'No se puede cambiar después de crear el rol.',
                ),
              ),
              const SizedBox(height: 18),
              const Text('Nivel de acceso',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: RL.text, fontSize: 14)),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                ],
                selected: {_nivel},
                onSelectionChanged: (v) => setState(() => _nivel = v.first),
              ),
              const SizedBox(height: 6),
              Text(nivelAccesoTexto(_nivel),
                  style: const TextStyle(color: RL.muted, fontSize: 13)),
              const SizedBox(height: 14),
              CampoEstado(
                  activo: _activo, onChanged: (v) => setState(() => _activo = v)),
              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorBox(_error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: _guardar,
                  child: Text(nuevo ? 'CREAR ROL' : 'GUARDAR CAMBIOS')),
            ],
          ),
        ),
      ),
    );
  }
}

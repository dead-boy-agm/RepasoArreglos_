import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';

Widget _fab(VoidCallback onTap) => FloatingActionButton(
      backgroundColor: RL.primary,
      foregroundColor: Colors.white,
      onPressed: onTap,
      child: const Icon(Icons.add),
    );

Widget _tabsHeader(String titulo, String subtitulo, List<String> tabs) =>
    Column(children: [
      TabHeader(title: titulo, subtitle: subtitulo),
      Container(
        color: Colors.white,
        child: TabBar(tabs: [for (final t in tabs) Tab(text: t)]),
      ),
    ]);

// =========================================================== GRUPOS E INSCRIP.
class GruposInscripcionesScreen extends StatelessWidget {
  const GruposInscripcionesScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(children: [
          _tabsHeader('Grupos e inscripciones', 'Periodos y alumnos inscritos',
              const ['Grupos', 'Inscripciones']),
          const Expanded(
              child: TabBarView(children: [GruposTab(), InscripcionesTab()])),
        ]),
      );
}

// ====================================================== MATERIAS Y ASIGNACION.
class MateriasAsignacionesScreen extends StatelessWidget {
  const MateriasAsignacionesScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Column(children: [
          _tabsHeader('Materias y asignaciones', 'Catálogo y docentes por grupo',
              const ['Materias', 'Asignaciones']),
          const Expanded(
              child:
                  TabBarView(children: [MateriasTab(), AsignacionesTab()])),
        ]),
      );
}

// ===================================================================== GRUPOS
class GruposTab extends StatefulWidget {
  const GruposTab({super.key});
  @override
  State<GruposTab> createState() => _GruposTabState();
}

class _GruposTabState extends State<GruposTab> {
  String _q = '';
  String _periodo = 'Todos';
  String _estado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lista = s.grupos.where((g) {
      if (!g.nombre.toLowerCase().contains(_q.toLowerCase())) return false;
      if (_periodo != 'Todos' && g.periodo != _periodo) return false;
      if (_estado == 'Activos' && !g.activo) return false;
      if (_estado == 'Inactivos' && g.activo) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: _fab(() => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const GrupoFormScreen()))),
      body: Column(children: [
        SearchField(
            hint: 'Buscar grupo...', onChanged: (v) => setState(() => _q = v)),
        ChipsFiltro(
          opciones: const ['Todos', ...periodosDisponibles],
          valor: _periodo,
          onChanged: (v) => setState(() => _periodo = v),
        ),
        ChipsFiltro(
          opciones: const ['Todos', 'Activos', 'Inactivos'],
          valor: _estado,
          onChanged: (v) => setState(() => _estado = v),
        ),
        Expanded(
          child: lista.isEmpty
              ? const EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'No hay grupos',
                  subtitle: 'Ningún grupo coincide con los filtros.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final g = lista[i];
                    return RLCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => GrupoFormScreen(grupo: g))),
                      child: Row(children: [
                        const Avatar('G', bg: RL.violetSoft, fg: RL.violet),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: RL.text)),
                              Text(g.periodo,
                                  style: const TextStyle(
                                      color: RL.muted, fontSize: 13)),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, children: [
                                EstadoPill(g.activo),
                                Pill('${s.inscritosEn(g.nombre)} alumnos inscritos',
                                    color: RL.primary, bg: RL.soft),
                              ]),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'editar') {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => GrupoFormScreen(grupo: g)));
                            } else {
                              final err = s.editarGrupo(g,
                                  nombre: g.nombre,
                                  periodo: g.periodo,
                                  activo: !g.activo);
                              if (err != null) snack(context, err, error: true);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'editar', child: Text('Editar')),
                            PopupMenuItem(
                                value: 'estado',
                                child:
                                    Text(g.activo ? 'Desactivar' : 'Activar')),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class GrupoFormScreen extends StatefulWidget {
  final Grupo? grupo;
  const GrupoFormScreen({super.key, this.grupo});
  @override
  State<GrupoFormScreen> createState() => _GrupoFormScreenState();
}

class _GrupoFormScreenState extends State<GrupoFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late String _periodo;
  bool _activo = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.grupo;
    _nombre = TextEditingController(text: g?.nombre ?? '');
    _periodo = g?.periodo ?? periodosDisponibles[1];
    _activo = g?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final g = widget.grupo;
    final err = g == null
        ? s.crearGrupo(nombre: _nombre.text, periodo: _periodo, activo: _activo)
        : s.editarGrupo(g,
            nombre: _nombre.text, periodo: _periodo, activo: _activo);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, g == null ? 'Grupo creado' : 'Grupo actualizado');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nuevo = widget.grupo == null;
    final periodos = {...periodosDisponibles, _periodo}.toList();
    return Scaffold(
      appBar: AppBar(title: Text(nuevo ? 'Nuevo grupo' : 'Editar grupo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Ingresa el nombre del grupo'
                    : null,
                decoration: const InputDecoration(
                    labelText: 'Nombre', hintText: 'Ej. GSI-61'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _periodo,
                items: periodos
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _periodo = v ?? _periodo),
                decoration: const InputDecoration(labelText: 'Periodo'),
              ),
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
                  child: Text(nuevo ? 'CREAR GRUPO' : 'GUARDAR CAMBIOS')),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================== INSCRIPCIONES
class InscripcionesTab extends StatefulWidget {
  const InscripcionesTab({super.key});
  @override
  State<InscripcionesTab> createState() => _InscripcionesTabState();
}

class _InscripcionesTabState extends State<InscripcionesTab> {
  String _grupo = 'Todos';
  String _estado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lista = s.inscripciones.where((i) {
      if (_grupo != 'Todos' && i.grupo != _grupo) return false;
      if (_estado != 'Todos' && i.estado.texto != _estado) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: _fab(() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const InscripcionFormScreen()))),
      body: Column(children: [
        FiltrosFila(children: [
          FiltroDrop(
              label: 'Grupo',
              valor: _grupo,
              opciones: ['Todos', ...s.grupos.map((g) => g.nombre)],
              onChanged: (v) => setState(() => _grupo = v)),
          FiltroDrop(
              label: 'Estado',
              valor: _estado,
              opciones: const ['Todos', 'Activa', 'Retirada'],
              onChanged: (v) => setState(() => _estado = v)),
        ]),
        Expanded(
          child: lista.isEmpty
              ? const EmptyState(
                  icon: Icons.how_to_reg_outlined,
                  title: 'No hay inscripciones',
                  subtitle: 'Inscribe alumnos en un grupo con el botón +.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final ins = lista[i];
                    final al = s.usuario(ins.alumnoId);
                    final activa = ins.estado == EstadoInscripcion.activa;
                    return RLCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              InscripcionFormScreen(inscripcion: ins))),
                      child: Row(children: [
                        UserAvatar(al),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(al.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: RL.text)),
                              Text('${ins.grupo} · ${fmtFecha(ins.fecha)}',
                                  style: const TextStyle(
                                      color: RL.muted, fontSize: 13)),
                              const SizedBox(height: 6),
                              Pill(ins.estado.texto,
                                  color: activa ? RL.green : RL.red,
                                  bg: activa ? RL.greenSoft : RL.redSoft),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'editar') {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) =>
                                      InscripcionFormScreen(inscripcion: ins)));
                            } else {
                              final ok = await confirmar(
                                  context,
                                  'Retirar alumno',
                                  '¿Retirar a ${al.nombre} del grupo ${ins.grupo}? '
                                      'Se conserva el historial y se detiene la comunicación con ese grupo.',
                                  ok: 'Retirar');
                              if (ok) s.retirarInscripcion(ins);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'editar', child: Text('Editar')),
                            if (activa)
                              const PopupMenuItem(
                                  value: 'retirar', child: Text('Retirar')),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class InscripcionFormScreen extends StatefulWidget {
  final Inscripcion? inscripcion;
  const InscripcionFormScreen({super.key, this.inscripcion});
  @override
  State<InscripcionFormScreen> createState() => _InscripcionFormScreenState();
}

class _InscripcionFormScreenState extends State<InscripcionFormScreen> {
  String? _alumnoId;
  String? _grupo;
  DateTime _fecha = DateTime.now();
  EstadoInscripcion _estado = EstadoInscripcion.activa;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.inscripcion;
    if (i != null) {
      _alumnoId = i.alumnoId;
      _grupo = i.grupo;
      _fecha = i.fecha;
      _estado = i.estado;
    }
  }

  Future<void> _elegirFecha() async {
    final f = await elegirFecha(context, _fecha);
    if (f != null) setState(() => _fecha = f);
  }

  void _guardar() {
    final s = context.read<AppState>();
    final i = widget.inscripcion;
    if (_alumnoId == null || _grupo == null) {
      setState(() => _error = 'Selecciona alumno y grupo.');
      return;
    }
    final err = i == null
        ? s.inscribir(
            alumnoId: _alumnoId!, grupo: _grupo!, fecha: _fecha, estado: _estado)
        : s.editarInscripcion(i, grupo: _grupo!, fecha: _fecha, estado: _estado);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, i == null ? 'Alumno inscrito' : 'Inscripción actualizada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final nueva = widget.inscripcion == null;
    final alumnos = s.alumnos.where((a) => a.activo || a.id == _alumnoId).toList();
    final grupos = s.grupos.where((g) => g.activo || g.nombre == _grupo).toList();

    return Scaffold(
      appBar: AppBar(title: Text(nueva ? 'Inscribir alumno' : 'Editar inscripción')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _alumnoId,
            hint: const Text('Selecciona un alumno'),
            items: alumnos
                .map((a) => DropdownMenuItem(value: a.id, child: Text(a.nombre)))
                .toList(),
            onChanged: nueva ? (v) => setState(() => _alumnoId = v) : null,
            decoration: const InputDecoration(labelText: 'Alumno'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _grupo,
            hint: const Text('Selecciona un grupo'),
            items: grupos
                .map((g) => DropdownMenuItem(
                    value: g.nombre, child: Text('${g.nombre} · ${g.periodo}')))
                .toList(),
            onChanged: (v) => setState(() => _grupo = v),
            decoration: const InputDecoration(labelText: 'Grupo'),
          ),
          const SizedBox(height: 14),
          SelectorCampo(
              label: 'Fecha de inscripción',
              valor: fmtFecha(_fecha),
              icon: Icons.event,
              onTap: _elegirFecha),
          const SizedBox(height: 14),
          DropdownButtonFormField<EstadoInscripcion>(
            value: _estado,
            items: EstadoInscripcion.values
                .map((e) => DropdownMenuItem(value: e, child: Text(e.texto)))
                .toList(),
            onChanged: (v) => setState(() => _estado = v ?? _estado),
            decoration: const InputDecoration(labelText: 'Estado'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(_error!),
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _guardar,
              child: Text(nueva ? 'INSCRIBIR' : 'GUARDAR CAMBIOS')),
        ],
      ),
    );
  }
}

// =================================================================== MATERIAS
class MateriasTab extends StatefulWidget {
  const MateriasTab({super.key});
  @override
  State<MateriasTab> createState() => _MateriasTabState();
}

class _MateriasTabState extends State<MateriasTab> {
  String _q = '';
  String _estado = 'Todos';

  void _asignaciones(Materia m) {
    final s = context.read<AppState>();
    final lista = s.asignacionesDeMateria(m.nombre);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Asignaciones de ${m.nombre}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: RL.text)),
              const SizedBox(height: 10),
              if (lista.isEmpty)
                const Text('Esta materia aún no tiene asignaciones.',
                    style: TextStyle(color: RL.muted))
              else
                for (final a in lista)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(s.usuario(a.docenteId), size: 38),
                    title: Text(s.usuario(a.docenteId).nombre),
                    subtitle: Text(
                        '${a.grupo} · ${a.activo ? 'Activa' : 'Inactiva'}'),
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
    final lista = s.materias.where((m) {
      final t = '${m.nombre} ${m.codigo}'.toLowerCase();
      if (!t.contains(_q.toLowerCase())) return false;
      if (_estado == 'Activas' && !m.activo) return false;
      if (_estado == 'Inactivas' && m.activo) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: _fab(() => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const MateriaFormScreen()))),
      body: Column(children: [
        SearchField(
            hint: 'Buscar por nombre o código...',
            onChanged: (v) => setState(() => _q = v)),
        ChipsFiltro(
          opciones: const ['Todos', 'Activas', 'Inactivas'],
          valor: _estado,
          onChanged: (v) => setState(() => _estado = v),
        ),
        Expanded(
          child: lista.isEmpty
              ? const EmptyState(
                  icon: Icons.menu_book_outlined, title: 'No hay materias')
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  children: [
                    for (final m in lista)
                      RLCard(
                        onTap: () => _asignaciones(m),
                        child: Row(children: [
                          const Avatar('M'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: RL.text)),
                                Text('Código ${m.codigo}',
                                    style: const TextStyle(
                                        color: RL.muted, fontSize: 13)),
                                const SizedBox(height: 6),
                                Wrap(spacing: 6, children: [
                                  EstadoPill(m.activo),
                                  Pill(
                                      '${s.asignacionesDeMateria(m.nombre).length} asignaciones',
                                      color: RL.muted,
                                      bg: RL.bg),
                                ]),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'ver') _asignaciones(m);
                              if (v == 'editar') {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) =>
                                        MateriaFormScreen(materia: m)));
                              }
                              if (v == 'estado') {
                                final err = s.editarMateria(m,
                                    nombre: m.nombre,
                                    codigo: m.codigo,
                                    activo: !m.activo);
                                if (err != null) {
                                  snack(context, err, error: true);
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'ver',
                                  child: Text('Ver asignaciones')),
                              const PopupMenuItem(
                                  value: 'editar', child: Text('Editar')),
                              PopupMenuItem(
                                  value: 'estado',
                                  child: Text(
                                      m.activo ? 'Desactivar' : 'Activar')),
                            ],
                          ),
                        ]),
                      ),
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Las materias no se eliminan: se desactivan para conservar el historial de asignaciones.',
                        style: TextStyle(color: RL.muted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
        ),
      ]),
    );
  }
}

class MateriaFormScreen extends StatefulWidget {
  final Materia? materia;
  const MateriaFormScreen({super.key, this.materia});
  @override
  State<MateriaFormScreen> createState() => _MateriaFormScreenState();
}

class _MateriaFormScreenState extends State<MateriaFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _codigo;
  bool _activo = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final m = widget.materia;
    _nombre = TextEditingController(text: m?.nombre ?? '');
    _codigo = TextEditingController(text: m?.codigo ?? '');
    _activo = m?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigo.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final s = context.read<AppState>();
    final m = widget.materia;
    final err = m == null
        ? s.crearMateria(
            nombre: _nombre.text, codigo: _codigo.text, activo: _activo)
        : s.editarMateria(m,
            nombre: _nombre.text, codigo: _codigo.text, activo: _activo);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, m == null ? 'Materia creada' : 'Materia actualizada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nueva = widget.materia == null;
    return Scaffold(
      appBar: AppBar(title: Text(nueva ? 'Nueva materia' : 'Editar materia')),
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
                    ? 'Ingresa el nombre de la materia'
                    : null,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _codigo,
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Ingresa el código'
                    : null,
                decoration: const InputDecoration(
                    labelText: 'Código', hintText: 'Ej. PRG-301'),
              ),
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
                  child: Text(nueva ? 'CREAR MATERIA' : 'GUARDAR CAMBIOS')),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ ASIGNACIONES
class AsignacionesTab extends StatefulWidget {
  const AsignacionesTab({super.key});
  @override
  State<AsignacionesTab> createState() => _AsignacionesTabState();
}

class _AsignacionesTabState extends State<AsignacionesTab> {
  String _periodo = 'Todos';
  String _grupo = 'Todos';
  String _materia = 'Todos';
  String _docente = 'Todos';
  String _estado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lista = s.asignaciones.where((a) {
      final per = s.grupoPorNombre(a.grupo)?.periodo ?? '';
      if (_periodo != 'Todos' && per != _periodo) return false;
      if (_grupo != 'Todos' && a.grupo != _grupo) return false;
      if (_materia != 'Todos' && a.materia != _materia) return false;
      if (_docente != 'Todos' && s.usuario(a.docenteId).nombre != _docente) {
        return false;
      }
      if (_estado == 'Activa' && !a.activo) return false;
      if (_estado == 'Inactiva' && a.activo) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: _fab(() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AsignacionFormScreen()))),
      body: Column(children: [
        FiltrosFila(children: [
          FiltroDrop(
              label: 'Periodo',
              valor: _periodo,
              opciones: const ['Todos', ...periodosDisponibles],
              onChanged: (v) => setState(() => _periodo = v)),
          FiltroDrop(
              label: 'Grupo',
              valor: _grupo,
              opciones: ['Todos', ...s.grupos.map((g) => g.nombre)],
              onChanged: (v) => setState(() => _grupo = v)),
          FiltroDrop(
              label: 'Materia',
              valor: _materia,
              opciones: ['Todos', ...s.materias.map((m) => m.nombre)],
              onChanged: (v) => setState(() => _materia = v)),
          FiltroDrop(
              label: 'Docente',
              valor: _docente,
              opciones: ['Todos', ...s.docentes.map((d) => d.nombre)],
              onChanged: (v) => setState(() => _docente = v)),
          FiltroDrop(
              label: 'Estado',
              valor: _estado,
              opciones: const ['Todos', 'Activa', 'Inactiva'],
              onChanged: (v) => setState(() => _estado = v)),
        ]),
        Expanded(
          child: lista.isEmpty
              ? const EmptyState(
                  icon: Icons.swap_horiz,
                  title: 'No hay asignaciones',
                  subtitle:
                      'Crea una para que los alumnos vean a sus docentes.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final a = lista[i];
                    final d = s.usuario(a.docenteId);
                    return RLCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AsignacionFormScreen(asignacion: a))),
                      child: Row(children: [
                        UserAvatar(d),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.nombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: RL.text)),
                              Text(a.materia,
                                  style: const TextStyle(
                                      color: RL.muted, fontSize: 13)),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, children: [
                                Pill(a.grupo),
                                Pill(s.grupoPorNombre(a.grupo)?.periodo ?? '—',
                                    color: RL.violet, bg: RL.violetSoft),
                                EstadoPill(a.activo),
                              ]),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'editar') {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) =>
                                      AsignacionFormScreen(asignacion: a)));
                            } else {
                              final err = s.alternarAsignacion(a);
                              if (err != null) snack(context, err, error: true);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'editar', child: Text('Editar')),
                            PopupMenuItem(
                                value: 'estado',
                                child:
                                    Text(a.activo ? 'Desactivar' : 'Activar')),
                          ],
                        ),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class AsignacionFormScreen extends StatefulWidget {
  final Asignacion? asignacion;
  const AsignacionFormScreen({super.key, this.asignacion});
  @override
  State<AsignacionFormScreen> createState() => _AsignacionFormScreenState();
}

class _AsignacionFormScreenState extends State<AsignacionFormScreen> {
  String? _docente;
  String? _materia;
  String? _grupo;
  bool _activo = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.asignacion;
    if (a != null) {
      _docente = a.docenteId;
      _materia = a.materia;
      _grupo = a.grupo;
      _activo = a.activo;
    }
  }

  void _guardar() {
    final s = context.read<AppState>();
    final a = widget.asignacion;
    final err = a == null
        ? s.crearAsignacion(_docente ?? '', _materia ?? '', _grupo ?? '',
            activo: _activo)
        : s.editarAsignacion(a,
            docenteId: _docente ?? '',
            materia: _materia ?? '',
            grupo: _grupo ?? '',
            activo: _activo);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, a == null ? 'Asignación creada' : 'Asignación actualizada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final nueva = widget.asignacion == null;
    final docentes =
        s.docentes.where((d) => d.activo || d.id == _docente).toList();
    final materias =
        s.materias.where((m) => m.activo || m.nombre == _materia).toList();
    final grupos =
        s.grupos.where((g) => g.activo || g.nombre == _grupo).toList();

    return Scaffold(
      appBar:
          AppBar(title: Text(nueva ? 'Nueva asignación' : 'Editar asignación')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _docente,
            hint: const Text('Selecciona un docente'),
            items: docentes
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.nombre)))
                .toList(),
            onChanged: (v) => setState(() => _docente = v),
            decoration: const InputDecoration(labelText: 'Docente'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _materia,
            hint: const Text('Selecciona una materia'),
            items: materias
                .map((m) => DropdownMenuItem(
                    value: m.nombre, child: Text('${m.nombre} (${m.codigo})')))
                .toList(),
            onChanged: (v) => setState(() => _materia = v),
            decoration: const InputDecoration(labelText: 'Materia'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _grupo,
            hint: const Text('Selecciona un grupo'),
            items: grupos
                .map((g) => DropdownMenuItem(
                    value: g.nombre, child: Text('${g.nombre} · ${g.periodo}')))
                .toList(),
            onChanged: (v) => setState(() => _grupo = v),
            decoration: const InputDecoration(labelText: 'Grupo'),
          ),
          const SizedBox(height: 14),
          CampoEstado(
              activo: _activo, onChanged: (v) => setState(() => _activo = v)),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Una asignación activa habilita la comunicación entre el docente y los alumnos inscritos en ese grupo.',
              style: TextStyle(color: RL.muted, fontSize: 12),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(_error!),
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _guardar,
              child: Text(nueva ? 'CREAR ASIGNACIÓN' : 'GUARDAR CAMBIOS')),
        ],
      ),
    );
  }
}

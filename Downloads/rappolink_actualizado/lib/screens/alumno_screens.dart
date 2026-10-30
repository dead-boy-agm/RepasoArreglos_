import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';
import 'chat_screens.dart';
import 'horarios_screens.dart';
import 'perfil_screen.dart';
import 'programados_screens.dart';

// ====================================================================== SHELL
class AlumnoShell extends StatefulWidget {
  const AlumnoShell({super.key});
  @override
  State<AlumnoShell> createState() => _AlumnoShellState();
}

class _AlumnoShellState extends State<AlumnoShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final nuevos = s.pendientes(s.actual!.id);
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        AlumnoHome(onGo: (n) => setState(() => _i = n)),
        const ChatsScreen(),
        const MisMateriasScreen(),
        const HorariosAlumnoScreen(),
        const ProgramadosScreen(),
        const PerfilScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        onDestinationSelected: (n) => setState(() => _i = n),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: nuevos > 0,
                  label: Text('$nuevos'),
                  child: const Icon(Icons.chat_bubble_outline)),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: 'Conversaciones'),
          const NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Materias'),
          const NavigationDestination(
              icon: Icon(Icons.schedule),
              selectedIcon: Icon(Icons.schedule),
              label: 'Horarios'),
          const NavigationDestination(
              icon: Icon(Icons.schedule_send_outlined),
              selectedIcon: Icon(Icons.schedule_send),
              label: 'Programados'),
          const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

/// Título de sección con acceso "Ver todo".
class SeccionConAccion extends StatelessWidget {
  final String titulo;
  final VoidCallback onTap;
  const SeccionConAccion(this.titulo, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: SectionLabel(titulo)),
        TextButton(onPressed: onTap, child: const Text('Ver todo')),
      ]);
}

// ================================================================= DASHBOARD
class AlumnoHome extends StatelessWidget {
  final ValueChanged<int> onGo;
  const AlumnoHome({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final grupo = s.grupoDe(me.id);
    final asigs = s.docentesDeAlumno(me);
    final docIds = asigs.map((a) => a.docenteId).toSet().toList();
    final disponibles = docIds.where((id) => s.dentroDeHorario(id)).length;
    final convs = s.conversacionesDe(me);
    final progs = s.programadosDe(me.id).reversed.take(3).toList();

    return Column(
      children: [
        TabHeader(
          title: 'Hola, ${me.primerNombre} 👋',
          subtitle: 'Alumno · ${grupo ?? 'Sin grupo'}',
          trailing: const Pill('Rol: Alumno'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  StatCard(
                      valor: '${s.pendientes(me.id)}',
                      label: 'Sin leer',
                      icon: Icons.mark_chat_unread_outlined),
                  StatCard(
                      valor: '${asigs.map((a) => a.materia).toSet().length}',
                      label: 'Materias',
                      icon: Icons.menu_book,
                      color: RL.green,
                      bg: RL.greenSoft),
                  StatCard(
                      valor: '$disponibles/${docIds.length}',
                      label: 'Docentes disponibles',
                      icon: Icons.groups,
                      color: RL.violet,
                      bg: RL.violetSoft),
                  StatCard(
                      valor: '${s.programadosPendientes(me.id)}',
                      label: 'Programados',
                      icon: Icons.schedule_send,
                      color: RL.amber,
                      bg: RL.amberSoft),
                ],
              ),
              const SizedBox(height: 8),
              SeccionConAccion('Conversaciones recientes', onTap: () => onGo(1)),
              if (convs.isEmpty)
                const RLCard(
                    child: Text('Aún no tienes conversaciones.',
                        style: TextStyle(color: RL.muted)))
              else
                for (final c in convs.take(3)) ConversacionCard(c),
              SeccionConAccion('Mis materias y docentes', onTap: () => onGo(2)),
              if (grupo == null)
                const RLCard(
                    child: Text('Aún no estás inscrito en un grupo.',
                        style: TextStyle(color: RL.muted)))
              else
                for (final a in asigs.take(4))
                  RLCard(
                    child: Row(children: [
                      const Avatar('M', bg: RL.greenSoft, fg: RL.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.materia,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: RL.text)),
                            Text(
                                '${a.grupo} · Prof. ${s.usuario(a.docenteId).nombre}',
                                style: const TextStyle(
                                    color: RL.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ]),
                  ),
              SeccionConAccion('Horarios de atención', onTap: () => onGo(3)),
              if (docIds.isEmpty)
                const RLCard(
                    child: Text('Sin docentes asignados.',
                        style: TextStyle(color: RL.muted)))
              else
                for (final id in docIds.take(3))
                  RLCard(
                    child: Row(children: [
                      UserAvatar(s.usuario(id), size: 38),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.usuario(id).nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: RL.text)),
                            Text(s.textoDisponibilidad(id),
                                style: const TextStyle(
                                    color: RL.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Pill(s.dentroDeHorario(id) ? 'Disponible' : 'Fuera',
                          color: s.dentroDeHorario(id) ? RL.green : RL.amber,
                          bg: s.dentroDeHorario(id)
                              ? RL.greenSoft
                              : RL.amberSoft),
                    ]),
                  ),
              SeccionConAccion('Mensajes programados', onTap: () => onGo(4)),
              if (progs.isEmpty)
                const RLCard(
                    child: Text('No tienes mensajes programados.',
                        style: TextStyle(color: RL.muted)))
              else
                for (final p in progs) ProgramadoCard(p, acciones: false),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================= MIS MATERIAS Y GRUPOS
class MisMateriasScreen extends StatefulWidget {
  const MisMateriasScreen({super.key});
  @override
  State<MisMateriasScreen> createState() => _MisMateriasScreenState();
}

class _MisMateriasScreenState extends State<MisMateriasScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final grupo = s.grupoDe(me.id);
    final todas = s.docentesDeAlumno(me);
    final lista = todas.where((a) {
      final d = s.usuario(a.docenteId);
      return '${d.nombre} ${a.materia}'.toLowerCase().contains(_q.toLowerCase());
    }).toList();
    final g = grupo == null ? null : s.grupoPorNombre(grupo);

    return Column(
      children: [
        TabHeader(
            title: 'Mis materias y grupos',
            subtitle: g == null ? 'Sin inscripción activa' : '${g.nombre} · ${g.periodo}',
            trailing: Pill('${todas.length} materias')),
        SearchField(
            hint: 'Buscar docente o materia...',
            onChanged: (v) => setState(() => _q = v)),
        Expanded(
          child: lista.isEmpty
              ? EmptyState(
                  icon: Icons.person_search,
                  title: grupo == null
                      ? 'Aún no estás inscrito'
                      : todas.isEmpty
                          ? 'No hay docentes asignados'
                          : 'Sin resultados',
                  subtitle: grupo == null
                      ? 'La administración debe inscribirte en un grupo.'
                      : todas.isEmpty
                          ? 'El administrador aún no asigna docentes a tu grupo.'
                          : 'Prueba con otro nombre o materia.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final a = lista[i];
                    final d = s.usuario(a.docenteId);
                    final dentro = s.dentroDeHorario(d.id);
                    final codigo = s.materiaPorNombre(a.materia)?.codigo ?? '';
                    return RLCard(
                      onTap: () {
                        final err = s.validarInicio(a, me.id);
                        if (err != null) {
                          snack(context, err, error: true);
                          return;
                        }
                        final c = s.abrirConversacion(a, me.id);
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatScreen(convId: c.id)));
                      },
                      child: Row(
                        children: [
                          UserAvatar(d),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.materia,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: RL.text)),
                                Text('Prof. ${d.nombre} · $codigo',
                                    style: const TextStyle(
                                        color: RL.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          Pill(dentro ? 'Disponible' : 'Fuera de horario',
                              color: dentro ? RL.green : RL.amber,
                              bg: dentro ? RL.greenSoft : RL.amberSoft),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

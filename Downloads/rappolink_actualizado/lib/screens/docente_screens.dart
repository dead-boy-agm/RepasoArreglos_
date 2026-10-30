import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';
import 'alumno_screens.dart' show SeccionConAccion;
import 'chat_screens.dart';
import 'horarios_screens.dart';
import 'perfil_screen.dart';
import 'programados_screens.dart';

// ====================================================================== SHELL
class DocenteShell extends StatefulWidget {
  const DocenteShell({super.key});
  @override
  State<DocenteShell> createState() => _DocenteShellState();
}

class _DocenteShellState extends State<DocenteShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pend = s.pendientes(s.actual!.id);
    return Scaffold(
      body: IndexedStack(index: _i, children: [
        DocenteHome(onGo: (n) => setState(() => _i = n)),
        const ChatsScreen(),
        const MisGruposScreen(),
        const HorariosDocenteScreen(),
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
                  isLabelVisible: pend > 0,
                  label: Text('$pend'),
                  child: const Icon(Icons.chat_bubble_outline)),
              selectedIcon: const Icon(Icons.chat_bubble),
              label: 'Conversaciones'),
          const NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: 'Grupos y materias'),
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

// ================================================================= DASHBOARD
class DocenteHome extends StatelessWidget {
  final ValueChanged<int> onGo;
  const DocenteHome({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final dentro = s.dentroDeHorario(me.id);
    final asigs = s.asignacionesDe(me.id);
    final grupos = asigs.map((a) => a.grupo).toSet();
    final alumnos = grupos.fold<int>(0, (t, g) => t + s.inscritosEn(g));
    final convs = s.conversacionesDe(me);
    final slots = s.horariosDe(me.id).where((h) => h.activo).toList();
    final progs = s
        .programadosDe(me.id)
        .where((p) => p.estado == EstadoProg.pendiente)
        .take(3)
        .toList();

    return Column(
      children: [
        TabHeader(
          title: 'Hola, ${me.primerNombre} 👋',
          subtitle: 'Docente · ${asigs.length} asignaciones',
          trailing: const Pill('Rol: Docente'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HorarioBanner(
                dentro: dentro,
                titulo: dentro ? 'Dentro de horario' : 'Fuera de horario',
                detalle: s.textoDisponibilidad(me.id),
              ),
              const SizedBox(height: 12),
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
                      label: 'Por responder',
                      icon: Icons.mark_chat_unread_outlined),
                  StatCard(
                      valor: '${asigs.length}',
                      label: 'Asignaciones',
                      icon: Icons.menu_book,
                      color: RL.green,
                      bg: RL.greenSoft),
                  StatCard(
                      valor: '$alumnos',
                      label: 'Alumnos',
                      icon: Icons.school,
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
              SeccionConAccion('Conversaciones', onTap: () => onGo(1)),
              if (convs.isEmpty)
                const RLCard(
                    child: Text('Cuando un alumno te escriba, aparecerá aquí.',
                        style: TextStyle(color: RL.muted)))
              else
                for (final c in convs.take(3)) ConversacionCard(c),
              SeccionConAccion('Grupos y materias asignados',
                  onTap: () => onGo(2)),
              if (asigs.isEmpty)
                const RLCard(
                    child: Text('Aún no tienes materias asignadas.',
                        style: TextStyle(color: RL.muted)))
              else
                for (final a in asigs.take(4))
                  RLCard(
                    child: Row(children: [
                      const Avatar('P'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a.materia,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, color: RL.text)),
                      ),
                      Pill(a.grupo),
                    ]),
                  ),
              SeccionConAccion('Mi horario de atención', onTap: () => onGo(3)),
              RLCard(
                child: slots.isEmpty
                    ? const Text('Aún no tienes horarios activos.',
                        style: TextStyle(color: RL.muted))
                    : Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final h in slots)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(
                                '${h.dia.substring(0, 3)} ${h.inicio}–${h.fin}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                      ]),
              ),
              SeccionConAccion('Mensajes programados pendientes',
                  onTap: () => onGo(4)),
              if (progs.isEmpty)
                const RLCard(
                    child: Text('No tienes mensajes pendientes de envío.',
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

// ================================================ MIS GRUPOS Y MATERIAS
class MisGruposScreen extends StatelessWidget {
  const MisGruposScreen({super.key});

  void _alumnos(BuildContext context, Asignacion a) {
    final s = context.read<AppState>();
    final alumnos = s.alumnosDeGrupo(a.grupo);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${a.materia} · ${a.grupo}',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: RL.text)),
              const Text('Toca un alumno para abrir la conversación.',
                  style: TextStyle(color: RL.muted, fontSize: 12)),
              const SizedBox(height: 8),
              if (alumnos.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No hay alumnos inscritos en este grupo.',
                      style: TextStyle(color: RL.muted)),
                )
              else
                for (final al in alumnos)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: UserAvatar(al, size: 38),
                    title: Text(al.nombre),
                    subtitle: Text(al.correo),
                    trailing: const Icon(Icons.chat_bubble_outline),
                    onTap: () {
                      Navigator.pop(sheet);
                      final err = s.validarInicio(a, al.id);
                      if (err != null) {
                        snack(context, err, error: true);
                        return;
                      }
                      final c = s.abrirConversacion(a, al.id);
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ChatScreen(convId: c.id)));
                    },
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
    final me = s.actual!;
    final asigs = s.asignacionesDe(me.id);
    return Column(
      children: [
        TabHeader(
            title: 'Mis grupos y materias',
            subtitle: 'Asignaciones activas',
            trailing: Pill('${asigs.length} asignaciones')),
        Expanded(
          child: asigs.isEmpty
              ? const EmptyState(
                  icon: Icons.groups_outlined,
                  title: 'Sin asignaciones',
                  subtitle:
                      'La administración aún no te asigna materias y grupos.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final a in asigs)
                      RLCard(
                        onTap: () => _alumnos(context, a),
                        child: Row(children: [
                          const Avatar('P'),
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
                                    '${a.grupo} · ${s.grupoPorNombre(a.grupo)?.periodo ?? ''}',
                                    style: const TextStyle(
                                        color: RL.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          Pill('${s.inscritosEn(a.grupo)} alumnos'),
                        ]),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

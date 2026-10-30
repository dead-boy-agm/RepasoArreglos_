import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'academico_screens.dart';
import 'perfil_screen.dart';
import 'usuarios_screens.dart';

// ====================================================================== SHELL
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: _i, children: [
          AdminHome(onGo: (n) => setState(() => _i = n)),
          const UsuariosRolesScreen(),
          const GruposInscripcionesScreen(),
          const MateriasAsignacionesScreen(),
          const PerfilScreen(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (n) => setState(() => _i = n),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Inicio'),
            NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Usuarios'),
            NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Grupos'),
            NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Materias'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil'),
          ],
        ),
      );
}

// ================================================================= DASHBOARD
class AdminHome extends StatelessWidget {
  final ValueChanged<int> onGo;
  const AdminHome({super.key, required this.onGo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final asigActivas = s.asignaciones.where((a) => a.activo).length;
    final inactivos = s.usuarios.where((u) => !u.activo).length;
    final inscActivas = s.inscripciones
        .where((i) => i.estado == EstadoInscripcion.activa)
        .length;
    final progPend =
        s.programados.where((p) => p.estado == EstadoProg.pendiente).length;

    return Column(
      children: [
        const TabHeader(
          title: 'Administrador',
          subtitle: 'Panel de control',
          trailing: Pill('Rol: Administrador'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionLabel('Resumen'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  StatCard(
                      valor: '${s.usuarios.length}',
                      label: 'Usuarios',
                      icon: Icons.people),
                  StatCard(
                      valor: '${s.grupos.length}',
                      label: 'Grupos',
                      icon: Icons.groups,
                      color: RL.amber,
                      bg: RL.amberSoft),
                  StatCard(
                      valor: '$asigActivas',
                      label: 'Asignaciones activas',
                      icon: Icons.swap_horiz,
                      color: RL.violet,
                      bg: RL.violetSoft),
                  StatCard(
                      valor: '${s.conversacionesActivas}',
                      label: 'Conversaciones activas',
                      icon: Icons.chat_bubble,
                      color: RL.green,
                      bg: RL.greenSoft),
                ],
              ),
              const SizedBox(height: 8),
              const SectionLabel('Indicadores operativos'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.9,
                children: [
                  StatCard(
                      valor: '$inscActivas',
                      label: 'Alumnos inscritos',
                      icon: Icons.how_to_reg,
                      color: RL.green,
                      bg: RL.greenSoft),
                  StatCard(
                      valor: '${s.contar(Rol.docente)}',
                      label: 'Docentes',
                      icon: Icons.badge,
                      color: RL.violet,
                      bg: RL.violetSoft),
                  StatCard(
                      valor: '$inactivos',
                      label: 'Cuentas inactivas',
                      icon: Icons.person_off_outlined,
                      color: RL.red,
                      bg: RL.redSoft),
                  StatCard(
                      valor: '$progPend',
                      label: 'Mensajes programados',
                      icon: Icons.schedule_send,
                      color: RL.amber,
                      bg: RL.amberSoft),
                ],
              ),
              const SizedBox(height: 8),
              const SectionLabel('Administración'),
              ActionTile(
                  icon: Icons.people,
                  title: 'Usuarios y roles',
                  subtitle: 'Cuentas, roles y estado',
                  onTap: () => onGo(1)),
              ActionTile(
                  icon: Icons.groups,
                  title: 'Grupos e inscripciones',
                  subtitle:
                      '${s.grupos.length} grupos · $inscActivas alumnos inscritos',
                  onTap: () => onGo(2)),
              ActionTile(
                  icon: Icons.menu_book,
                  title: 'Materias y asignaciones',
                  subtitle:
                      '${s.materias.length} materias · $asigActivas asignaciones activas',
                  onTap: () => onGo(3)),
              ActionTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Bitácora administrativa',
                  subtitle: '${s.bitacora.length} registros',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const BitacoraScreen()))),
              ActionTile(
                  icon: Icons.settings_outlined,
                  title: 'Sistema',
                  subtitle: 'RappoLink v1.0.0',
                  onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'RappoLink',
                        applicationVersion: '1.0.0',
                        children: const [
                          Text('Conecta. Comunica. Respeta.'),
                        ],
                      )),
            ],
          ),
        ),
      ],
    );
  }
}

// ================================================================== BITÁCORA
class BitacoraScreen extends StatelessWidget {
  const BitacoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Bitácora administrativa')),
      body: s.bitacora.isEmpty
          ? const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'Sin registros',
              subtitle: 'Aquí aparecerán las acciones administrativas.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: s.bitacora.length,
              itemBuilder: (_, i) {
                final r = s.bitacora[i];
                return RLCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.accion,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: RL.text)),
                      const SizedBox(height: 2),
                      Text('${r.actor} · ${fmtFechaHora(r.fecha)}',
                          style:
                              const TextStyle(color: RL.muted, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

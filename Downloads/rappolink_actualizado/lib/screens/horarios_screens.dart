import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';

// ============================================= LISTA DE HORARIOS (DOCENTE)
class HorariosDocenteScreen extends StatelessWidget {
  const HorariosDocenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final lista = s.horariosDe(me.id);
    final dentro = s.dentroDeHorario(me.id);

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RL.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const HorarioFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo horario'),
      ),
      body: Column(
        children: [
          const TabHeader(
              title: 'Horario de atención',
              subtitle: 'Cuándo pueden escribirte tus alumnos'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                HorarioBanner(
                  dentro: dentro,
                  titulo: dentro ? 'Dentro de horario' : 'Fuera de horario',
                  detalle: s.textoDisponibilidad(me.id),
                ),
                const SizedBox(height: 12),
                if (lista.isEmpty)
                  const RLCard(
                      child: Text(
                          'Aún no tienes horarios. Agrega uno con el botón "Nuevo horario".',
                          style: TextStyle(color: RL.muted)))
                else
                  for (final h in lista)
                    RLCard(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => HorarioFormScreen(horario: h))),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                color: h.activo ? RL.soft : RL.bg,
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.schedule,
                                color: h.activo ? RL.primary : RL.muted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.dia,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: RL.text)),
                                Text('${h.inicio} – ${h.fin}',
                                    style: const TextStyle(
                                        color: RL.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          EstadoPill(h.activo),
                          Switch(
                            value: h.activo,
                            onChanged: (_) {
                              final err = s.alternarHorario(me.id, h);
                              if (err != null) snack(context, err, error: true);
                            },
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================= FORMULARIO: HORARIO DE ATENCIÓN
class HorarioFormScreen extends StatefulWidget {
  final HorarioDia? horario;
  const HorarioFormScreen({super.key, this.horario});
  @override
  State<HorarioFormScreen> createState() => _HorarioFormScreenState();
}

class _HorarioFormScreenState extends State<HorarioFormScreen> {
  String _dia = diasSemana.first;
  String _inicio = '08:00';
  String _fin = '14:00';
  bool _activo = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final h = widget.horario;
    if (h != null) {
      _dia = h.dia;
      _inicio = h.inicio;
      _fin = h.fin;
      _activo = h.activo;
    }
  }

  Future<void> _hora(bool inicio) async {
    final v = await elegirHora(context, inicio ? _inicio : _fin);
    if (v == null) return;
    setState(() => inicio ? _inicio = v : _fin = v);
  }

  void _guardar() {
    final s = context.read<AppState>();
    final err = s.guardarHorario(s.actual!.id,
        editar: widget.horario,
        dia: _dia,
        inicio: _inicio,
        fin: _fin,
        activo: _activo);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, widget.horario == null ? 'Horario creado' : 'Horario actualizado');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final nuevo = widget.horario == null;
    return Scaffold(
      appBar: AppBar(title: Text(nuevo ? 'Nuevo horario' : 'Editar horario')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _dia,
            items: diasSemana
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
            onChanged: (v) => setState(() => _dia = v ?? _dia),
            decoration: const InputDecoration(labelText: 'Día de la semana'),
          ),
          const SizedBox(height: 14),
          SelectorCampo(
              label: 'Hora de inicio',
              valor: _inicio,
              icon: Icons.access_time,
              onTap: () => _hora(true)),
          const SizedBox(height: 14),
          SelectorCampo(
              label: 'Hora de fin',
              valor: _fin,
              icon: Icons.access_time,
              onTap: () => _hora(false)),
          const SizedBox(height: 14),
          CampoEstado(
              activo: _activo, onChanged: (v) => setState(() => _activo = v)),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Tus horarios activos del mismo día no pueden empalmarse. '
              'Para dejar de atender en un horario, desactívalo.',
              style: TextStyle(color: RL.muted, fontSize: 12, height: 1.4),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(_error!),
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _guardar,
              child: Text(nuevo ? 'CREAR HORARIO' : 'GUARDAR CAMBIOS')),
        ],
      ),
    );
  }
}

// ================================================= HORARIOS DE MIS DOCENTES
class HorariosAlumnoScreen extends StatelessWidget {
  const HorariosAlumnoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final asigs = s.docentesDeAlumno(me);
    final ids = <String>[];
    for (final a in asigs) {
      if (!ids.contains(a.docenteId)) ids.add(a.docenteId);
    }

    return Column(
      children: [
        TabHeader(
          title: 'Horarios de atención',
          subtitle: 'Disponibilidad de tus docentes',
          trailing: Pill('${ids.length} docentes'),
        ),
        Expanded(
          child: ids.isEmpty
              ? const EmptyState(
                  icon: Icons.schedule,
                  title: 'Sin docentes asignados',
                  subtitle:
                      'Cuando estés inscrito en un grupo verás aquí los horarios de tus docentes.')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final id in ids) _DocenteHorario(docenteId: id, asigs: asigs),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DocenteHorario extends StatelessWidget {
  final String docenteId;
  final List<Asignacion> asigs;
  const _DocenteHorario({required this.docenteId, required this.asigs});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final d = s.usuario(docenteId);
    final dentro = s.dentroDeHorario(docenteId);
    final materias = asigs
        .where((a) => a.docenteId == docenteId)
        .map((a) => a.materia)
        .join(', ');
    final slots = s.horariosDe(docenteId).where((h) => h.activo).toList();

    return RLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            UserAvatar(d),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: RL.text)),
                  Text(materias,
                      style: const TextStyle(color: RL.muted, fontSize: 13)),
                ],
              ),
            ),
            Pill(dentro ? 'Disponible ahora' : 'No disponible',
                color: dentro ? RL.green : RL.amber,
                bg: dentro ? RL.greenSoft : RL.amberSoft),
          ]),
          const SizedBox(height: 10),
          Text(s.textoDisponibilidad(docenteId),
              style: TextStyle(
                  color: dentro ? RL.green : RL.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            const Text('Sin horario de atención registrado.',
                style: TextStyle(color: RL.muted, fontSize: 13))
          else
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final h in slots)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${h.dia.substring(0, 3)} ${h.inicio}–${h.fin}',
                      style: const TextStyle(fontSize: 12)),
                ),
            ]),
        ],
      ),
    );
  }
}

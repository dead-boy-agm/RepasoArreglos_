import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';

// ================================================================== TARJETA
/// Mensaje programado con su estado. Con [acciones] permite editar y cancelar
/// mientras esté pendiente.
class ProgramadoCard extends StatelessWidget {
  final MensajeProgramado p;
  final bool acciones;
  const ProgramadoCard(this.p, {super.key, this.acciones = true});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final c = s.conversacion(p.conversacionId);
    final otro = s.usuario(me.id == c.docenteId ? c.alumnoId : c.docenteId);
    final Color color;
    final Color bg;
    switch (p.estado) {
      case EstadoProg.pendiente:
        color = RL.amber;
        bg = RL.amberSoft;
        break;
      case EstadoProg.enviado:
        color = RL.green;
        bg = RL.greenSoft;
        break;
      case EstadoProg.cancelado:
        color = RL.red;
        bg = RL.redSoft;
        break;
    }
    final fecha = p.estado == EstadoProg.enviado && p.enviadoEn != null
        ? 'Enviado ${fmtFechaHora(p.enviadoEn!)}'
        : 'Envío ${fmtFechaHora(p.entrega)}';

    return RLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.schedule_send, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.texto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: RL.text)),
                    const SizedBox(height: 2),
                    Text('Para ${otro.nombre} · ${c.materia}',
                        style: const TextStyle(color: RL.muted, fontSize: 12)),
                    Text(fecha,
                        style: const TextStyle(color: RL.muted, fontSize: 12)),
                    if (p.nota != null)
                      Text(p.nota!,
                          style: const TextStyle(color: RL.red, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Pill(p.estado.texto, color: color, bg: bg),
            ],
          ),
          if (acciones && p.estado == EstadoProg.pendiente)
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(spacing: 4, children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => ProgramadoFormScreen(programado: p))),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: RL.red),
                  onPressed: () async {
                    final ok = await confirmar(context, 'Cancelar mensaje',
                        'El mensaje no se enviará.',
                        ok: 'Cancelar mensaje');
                    if (ok) s.cancelarProgramado(p);
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Cancelar'),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}

// ================================================ LISTA DE MENSAJES PROGRAMADOS
class ProgramadosScreen extends StatefulWidget {
  const ProgramadosScreen({super.key});
  @override
  State<ProgramadosScreen> createState() => _ProgramadosScreenState();
}

class _ProgramadosScreenState extends State<ProgramadosScreen> {
  String _estado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final todos = s.programadosDe(me.id);
    final lista = todos.where((p) {
      if (_estado == 'Pendientes') return p.estado == EstadoProg.pendiente;
      if (_estado == 'Enviados') return p.estado == EstadoProg.enviado;
      if (_estado == 'Cancelados') return p.estado == EstadoProg.cancelado;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RL.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProgramadoFormScreen())),
        icon: const Icon(Icons.schedule_send),
        label: const Text('Programar'),
      ),
      body: Column(
        children: [
          TabHeader(
            title: 'Mensajes programados',
            subtitle: 'Se envían en la fecha y hora elegidas',
            trailing: Pill('${s.programadosPendientes(me.id)} pendientes'),
          ),
          ChipsFiltro(
            opciones: const ['Todos', 'Pendientes', 'Enviados', 'Cancelados'],
            valor: _estado,
            onChanged: (v) => setState(() => _estado = v),
          ),
          Expanded(
            child: lista.isEmpty
                ? EmptyState(
                    icon: Icons.schedule_send,
                    title: todos.isEmpty
                        ? 'No hay mensajes programados'
                        : 'Sin resultados',
                    subtitle: todos.isEmpty
                        ? 'Programa un mensaje con el botón "Programar".'
                        : 'No hay mensajes con ese estado.')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => ProgramadoCard(lista[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ====================================================== FORMULARIO: PROGRAMAR
class ProgramadoFormScreen extends StatefulWidget {
  final MensajeProgramado? programado;
  final String? convId;
  final String? textoInicial;
  const ProgramadoFormScreen(
      {super.key, this.programado, this.convId, this.textoInicial});
  @override
  State<ProgramadoFormScreen> createState() => _ProgramadoFormScreenState();
}

class _ProgramadoFormScreenState extends State<ProgramadoFormScreen> {
  late final TextEditingController _txt;
  String? _convId;
  late DateTime _fecha;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.programado;
    _txt = TextEditingController(text: p?.texto ?? widget.textoInicial ?? '');
    _convId = p?.conversacionId ?? widget.convId;
    final hoy = DateTime.now();
    _fecha = p?.entrega ??
        DateTime(hoy.year, hoy.month, hoy.day, 8).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _txt.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    final f = await elegirFechaHora(context, _fecha);
    if (f != null) setState(() => _fecha = f);
  }

  void _guardar() {
    final s = context.read<AppState>();
    final p = widget.programado;
    String? err;
    if (p != null) {
      err = s.editarProgramado(p, texto: _txt.text, entrega: _fecha);
    } else if (_convId == null) {
      err = 'Selecciona la conversación.';
    } else {
      err = s.programarMensaje(
          convId: _convId!, texto: _txt.text, entrega: _fecha);
    }
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    snack(context, p == null ? 'Mensaje programado' : 'Cambios guardados');
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final nuevo = widget.programado == null;
    final convs = s
        .conversacionesDe(me)
        .where((c) => s.motivoBloqueo(c) == null || c.id == _convId)
        .toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(nuevo ? 'Programar mensaje' : 'Editar mensaje programado')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _convId,
            isExpanded: true,
            hint: Text(convs.isEmpty
                ? 'No hay conversaciones activas'
                : 'Selecciona una conversación'),
            items: convs.map((c) {
              final otro =
                  s.usuario(me.id == c.docenteId ? c.alumnoId : c.docenteId);
              return DropdownMenuItem(
                  value: c.id,
                  child: Text('${otro.nombre} · ${c.materia}',
                      overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: nuevo ? (v) => setState(() => _convId = v) : null,
            decoration: const InputDecoration(labelText: 'Conversación'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _txt,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                labelText: 'Mensaje', alignLabelWithHint: true),
          ),
          const SizedBox(height: 14),
          SelectorCampo(
              label: 'Fecha y hora de envío',
              valor: fmtFechaHora(_fecha),
              icon: Icons.event,
              onTap: _elegirFecha),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'El mensaje se envía automáticamente en esa fecha y hora (mientras '
              'la app esté abierta). No se envía si la inscripción, la asignación '
              'o la conversación ya no están activas.',
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
              child: Text(nuevo ? 'PROGRAMAR' : 'GUARDAR CAMBIOS')),
        ],
      ),
    );
  }
}

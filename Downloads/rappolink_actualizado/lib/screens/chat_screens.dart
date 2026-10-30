import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../ui_extras.dart';
import '../widgets.dart';
import 'programados_screens.dart';

/// "14:05" si es de hoy; "27/10 14:05" si no.
String fmtChat(DateTime d) {
  final n = DateTime.now();
  if (d.year == n.year && d.month == n.month && d.day == n.day) {
    return fmtHora(d);
  }
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm ${fmtHora(d)}';
}

// ======================================================== TARJETA DE CHAT
/// Fila de conversación: participante, materia, grupo, último mensaje y no leídos.
class ConversacionCard extends StatelessWidget {
  final Conversacion c;
  const ConversacionCard(this.c, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final esDocente = me.id == c.docenteId;
    final otro = s.usuario(esDocente ? c.alumnoId : c.docenteId);
    final noLeidos = c.noLeidosPara(me.id);
    final u = c.ultimo;
    return RLCard(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ChatScreen(convId: c.id))),
      child: Row(
        children: [
          UserAvatar(otro),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(otro.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: RL.text)),
                Text(
                    '${esDocente ? 'Alumno' : 'Docente'} · ${c.materia} · ${c.grupo}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: RL.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(u?.texto ?? 'Sin mensajes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: RL.muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (u != null)
                Text(fmtChat(u.hora),
                    style: const TextStyle(color: RL.muted, fontSize: 11)),
              const SizedBox(height: 4),
              if (noLeidos > 0)
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: RL.primary, shape: BoxShape.circle),
                  child: Text('$noLeidos',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                )
              else if (c.estado != EstadoConv.activa)
                Pill(c.estado.texto, color: RL.muted, bg: RL.bg),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================ LISTA DE CHATS
/// Bandeja compartida: la misma lista cambia de perspectiva según el rol.
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});
  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  String _q = '';
  String _estado = 'Activas';
  String _asig = 'Todas';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final esDocente = me.rol == Rol.docente;
    final todas = s.conversacionesDe(me);
    final asignaciones = todas.map((c) => '${c.materia} · ${c.grupo}').toSet().toList()
      ..sort();
    final lista = todas.where((c) {
      final otro = s.usuario(esDocente ? c.alumnoId : c.docenteId);
      final t = '${otro.nombre} ${c.materia}'.toLowerCase();
      if (!t.contains(_q.toLowerCase())) return false;
      if (_estado == 'Activas' && c.estado != EstadoConv.activa) return false;
      if (_estado == 'Archivadas' && c.estado != EstadoConv.archivada) {
        return false;
      }
      if (_estado == 'Cerradas' && c.estado != EstadoConv.cerrada) return false;
      if (_asig != 'Todas' && '${c.materia} · ${c.grupo}' != _asig) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: RL.bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RL.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const IniciarConversacionScreen())),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Nueva'),
      ),
      body: Column(
        children: [
          TabHeader(
            title: esDocente ? 'Conversaciones' : 'Mis conversaciones',
            subtitle: esDocente
                ? 'Conversaciones con alumnos'
                : 'Conversaciones con docentes',
          ),
          SearchField(
              hint: 'Buscar conversación...',
              onChanged: (v) => setState(() => _q = v)),
          ChipsFiltro(
            opciones: const ['Activas', 'Archivadas', 'Cerradas', 'Todas'],
            valor: _estado,
            onChanged: (v) => setState(() => _estado = v),
          ),
          FiltrosFila(children: [
            FiltroDrop(
                label: 'Asignación',
                valor: _asig,
                opciones: ['Todas', ...asignaciones],
                onChanged: (v) => setState(() => _asig = v)),
          ]),
          Expanded(
            child: lista.isEmpty
                ? EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: todas.isEmpty
                        ? 'No hay conversaciones'
                        : 'Sin resultados',
                    subtitle: todas.isEmpty
                        ? 'Toca "Nueva" para iniciar una conversación.'
                        : 'Prueba con otros filtros.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: lista.length,
                    itemBuilder: (_, i) => ConversacionCard(lista[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// =================================================== INICIAR CONVERSACIÓN
class IniciarConversacionScreen extends StatefulWidget {
  const IniciarConversacionScreen({super.key});
  @override
  State<IniciarConversacionScreen> createState() =>
      _IniciarConversacionScreenState();
}

class _IniciarConversacionScreenState extends State<IniciarConversacionScreen> {
  String? _asigId;
  String? _alumnoId;
  String? _error;

  void _iniciar() {
    final s = context.read<AppState>();
    final me = s.actual!;
    final esDocente = me.rol == Rol.docente;
    final a = s.asignacionPorId(_asigId ?? '');
    if (a == null) {
      setState(() => _error = 'Selecciona una asignación.');
      return;
    }
    final alumnoId = esDocente ? _alumnoId : me.id;
    if (alumnoId == null) {
      setState(() => _error = 'Selecciona al alumno.');
      return;
    }
    final err = s.validarInicio(a, alumnoId);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    final c = s.abrirConversacion(a, alumnoId);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(convId: c.id)));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final esDocente = me.rol == Rol.docente;
    final asigs = esDocente ? s.asignacionesDe(me.id) : s.docentesDeAlumno(me);
    final sel = s.asignacionPorId(_asigId ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva conversación')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Elige la asignación y el participante. El sistema valida que el '
            'alumno esté inscrito en el grupo y que la asignación esté activa.',
            style: TextStyle(color: RL.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: _asigId,
            hint: Text(asigs.isEmpty
                ? 'No tienes asignaciones disponibles'
                : 'Selecciona una asignación'),
            items: asigs
                .map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(esDocente
                        ? '${a.materia} · ${a.grupo}'
                        : '${a.materia} · Prof. ${s.usuario(a.docenteId).nombre}')))
                .toList(),
            onChanged: (v) => setState(() {
              _asigId = v;
              _alumnoId = null;
              _error = null;
            }),
            decoration: const InputDecoration(labelText: 'Asignación'),
          ),
          const SizedBox(height: 14),
          if (esDocente)
            DropdownButtonFormField<String>(
              value: _alumnoId,
              hint: Text(sel == null
                  ? 'Primero elige una asignación'
                  : 'Selecciona un alumno'),
              items: sel == null
                  ? const []
                  : s
                      .alumnosDeGrupo(sel.grupo)
                      .map((al) =>
                          DropdownMenuItem(value: al.id, child: Text(al.nombre)))
                      .toList(),
              onChanged: sel == null ? null : (v) => setState(() => _alumnoId = v),
              decoration: const InputDecoration(labelText: 'Alumno'),
            )
          else if (sel != null)
            RLCard(
              child: Row(children: [
                UserAvatar(s.usuario(sel.docenteId), size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Docente',
                          style: TextStyle(color: RL.muted, fontSize: 12)),
                      Text(s.usuario(sel.docenteId).nombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: RL.text)),
                    ],
                  ),
                ),
              ]),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBox(_error!),
          ],
          const SizedBox(height: 24),
          FilledButton(
              onPressed: _iniciar, child: const Text('INICIAR CONVERSACIÓN')),
        ],
      ),
    );
  }
}

// ==================================================================== CHAT
class _Item {
  final DateTime hora;
  final Mensaje? m;
  final MensajeProgramado? p;
  _Item(this.hora, {this.m, this.p});
}

class ChatScreen extends StatefulWidget {
  final String convId;
  const ChatScreen({super.key, required this.convId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _txt = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().marcarLeida(widget.convId);
    });
  }

  @override
  void dispose() {
    _txt.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _enviar() async {
    final texto = _txt.text.trim();
    if (texto.isEmpty) return;
    final s = context.read<AppState>();
    final c = s.conversacion(widget.convId);
    final me = s.actual!;

    // Un alumno fuera del horario del docente → mensaje programado.
    if (me.rol == Rol.alumno &&
        s.motivoBloqueo(c) == null &&
        !s.dentroDeHorario(c.docenteId)) {
      final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
          builder: (_) =>
              ProgramarMensajeScreen(convId: c.id, texto: texto)));
      if (ok == true) {
        _txt.clear();
        _bajar();
      }
      return;
    }
    final err = s.enviarMensaje(c.id, texto);
    if (err != null) {
      snack(context, err, error: true);
      return;
    }
    _txt.clear();
    _bajar();
  }

  void _cambiarEstado(EstadoConv e) {
    final err = context
        .read<AppState>()
        .cambiarEstadoConversacion(widget.convId, e);
    if (err != null) {
      snack(context, err, error: true);
    } else {
      snack(context, 'Conversación: ${e.texto.toLowerCase()}');
    }
  }

  void _detalle() {
    final s = context.read<AppState>();
    final c = s.conversacion(widget.convId);
    final alumno = s.usuario(c.alumnoId);
    final docente = s.usuario(c.docenteId);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Detalle de la conversación',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: RL.text)),
              const SizedBox(height: 12),
              _fila('Materia', c.materia),
              _fila('Grupo', c.grupo),
              _fila('Docente', docente.nombre),
              _fila('Alumno', alumno.nombre),
              _fila('Estado', c.estado.texto),
              _fila('Mensajes', '${c.mensajes.length}'),
              _fila('Creada', fmtFechaHora(c.creada)),
              const SizedBox(height: 10),
              const Text(
                'Cualquier participante puede archivar la conversación. '
                'Solo el docente puede cerrarla o reabrirla. Los mensajes '
                'enviados no se editan ni se eliminan.',
                style: TextStyle(color: RL.muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fila(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          SizedBox(
              width: 90,
              child: Text(l,
                  style: const TextStyle(color: RL.muted, fontSize: 13))),
          Expanded(
              child: Text(v,
                  style: const TextStyle(
                      color: RL.text, fontWeight: FontWeight.w600))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final me = s.actual!;
    final c = s.conversacion(widget.convId);
    final esDocente = me.id == c.docenteId;
    final otro = s.usuario(esDocente ? c.alumnoId : c.docenteId);
    final bloqueo = s.motivoBloqueo(c);
    final sub = esDocente
        ? '${c.materia} · ${c.grupo}'
        : '${c.materia} · ${s.textoDisponibilidad(c.docenteId)}';

    final items = <_Item>[
      for (final m in c.mensajes) _Item(m.hora, m: m),
      for (final p in s.programados.where((p) =>
          p.conversacionId == c.id &&
          p.autorId == me.id &&
          p.estado == EstadoProg.pendiente))
        _Item(p.entrega, p: p),
    ]..sort((a, b) => a.hora.compareTo(b.hora));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          UserAvatar(otro, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(esDocente ? otro.nombre : 'Prof. ${otro.nombre}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                Text(sub,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11,
                        color: RL.muted,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
        actions: [
          IconButton(
            tooltip: 'Programar mensaje',
            icon: const Icon(Icons.schedule_send),
            onPressed: bloqueo != null
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProgramadoFormScreen(
                        convId: c.id, textoInicial: _txt.text))),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'info':
                  _detalle();
                  break;
                case 'archivar':
                  _cambiarEstado(EstadoConv.archivada);
                  break;
                case 'reactivar':
                  _cambiarEstado(EstadoConv.activa);
                  break;
                case 'cerrar':
                  _cambiarEstado(EstadoConv.cerrada);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'info', child: Text('Ver detalle')),
              if (c.estado == EstadoConv.activa)
                const PopupMenuItem(value: 'archivar', child: Text('Archivar')),
              if (c.estado == EstadoConv.activa && esDocente)
                const PopupMenuItem(value: 'cerrar', child: Text('Cerrar')),
              if (c.estado == EstadoConv.archivada)
                const PopupMenuItem(
                    value: 'reactivar', child: Text('Reactivar')),
              if (c.estado == EstadoConv.cerrada && esDocente)
                const PopupMenuItem(value: 'reactivar', child: Text('Reabrir')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Inicia la conversación',
                    subtitle: 'Escribe tu primer mensaje abajo.')
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i];
                      if (it.p != null) return _BurbujaProgramada(p: it.p!);
                      final m = it.m!;
                      return _Burbuja(
                        m: m,
                        mio: m.deId == me.id,
                        remitente: s.usuario(m.deId).primerNombre,
                      );
                    },
                  ),
          ),
          if (bloqueo != null)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: RL.amberSoft,
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Icon(Icons.lock_outline, color: RL.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(bloqueo,
                          style: const TextStyle(color: RL.text2))),
                ]),
              ),
            )
          else
            SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _txt,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _enviar(),
                        decoration: const InputDecoration(
                            hintText: 'Escribe un mensaje...', isDense: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: RL.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _enviar,
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final Mensaje m;
  final bool mio;
  final String remitente;
  const _Burbuja(
      {required this.m, required this.mio, required this.remitente});

  @override
  Widget build(BuildContext context) => Align(
        alignment: mio ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * .75),
          decoration: BoxDecoration(
            color: mio ? RL.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mio ? 16 : 4),
              bottomRight: Radius.circular(mio ? 4 : 16),
            ),
            border: mio ? null : Border.all(color: RL.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mio)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(remitente,
                      style: const TextStyle(
                          color: RL.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(m.texto,
                    style: TextStyle(
                        color: mio ? Colors.white : RL.text, height: 1.3)),
              ),
              const SizedBox(height: 4),
              Text(
                  '${fmtChat(m.hora)}${mio ? (m.leido ? '  ✓✓ Leído' : '  ✓ Enviado') : ''}',
                  style: TextStyle(
                      color: mio ? Colors.white70 : RL.muted, fontSize: 10)),
            ],
          ),
        ),
      );
}

class _BurbujaProgramada extends StatelessWidget {
  final MensajeProgramado p;
  const _BurbujaProgramada({required this.p});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * .75),
          decoration: BoxDecoration(
            color: RL.amber,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(p.texto,
                    style: const TextStyle(color: Colors.white, height: 1.3)),
              ),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.schedule, size: 12, color: Colors.white),
                const SizedBox(width: 3),
                Text('Programado · ${fmtFechaHora(p.entrega)}',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ]),
            ],
          ),
        ),
      );
}

// ======================================================= MENSAJE PROGRAMADO
/// Se muestra cuando un alumno escribe fuera del horario de atención.
class ProgramarMensajeScreen extends StatelessWidget {
  final String convId;
  final String texto;
  const ProgramarMensajeScreen(
      {super.key, required this.convId, required this.texto});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final c = s.conversacion(convId);
    final docente = s.usuario(c.docenteId);
    final disp = s.proximaDisponibilidad(c.docenteId);

    return Scaffold(
      appBar: AppBar(title: const Text('Mensaje programado')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                      color: RL.amberSoft, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.schedule, size: 48, color: RL.amber),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Fuera del horario\nde atención',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: RL.text)),
              const SizedBox(height: 8),
              Text(
                  'El profesor ${docente.nombre} no recibirá el mensaje en este momento.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: RL.muted, height: 1.4)),
              const SizedBox(height: 20),
              RLCard(
                color: RL.soft,
                child: Text('“$texto”',
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, color: RL.text2)),
              ),
              const SizedBox(height: 6),
              RLCard(
                color: RL.amberSoft,
                child: Row(
                  children: [
                    const Icon(Icons.event_available, color: RL.amber),
                    const SizedBox(width: 10),
                    const Expanded(
                        child: Text('Tu mensaje se entregará:',
                            style: TextStyle(color: RL.text2))),
                    Text(disp.etiqueta,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: RL.text)),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final err = s.programarMensaje(
                      convId: convId, texto: texto, entrega: disp.fecha);
                  if (err != null) {
                    snack(context, err, error: true);
                    return;
                  }
                  snack(context, 'Mensaje programado para ${disp.etiqueta}');
                  Navigator.of(context).pop(true);
                },
                child: const Text('PROGRAMAR MENSAJE'),
              ),
              const SizedBox(height: 4),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (_) => ProgramadoFormScreen(
                              convId: convId, textoInicial: texto)));
                  if (ok == true && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: const Text('Elegir otra fecha y hora'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

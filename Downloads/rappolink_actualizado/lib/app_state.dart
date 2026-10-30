import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'models.dart';

/// Modo de horario (solo para la demostración en vivo):
/// auto = usa la hora real; dentro/fuera = fuerza el resultado.
enum ModoHorario { auto, dentro, fuera }

const diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
const periodosDisponibles = ['Ene–Jun 2026', 'Ago–Dic 2026', 'Ene–Jun 2027'];

int minutos(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

String _dos(int n) => n.toString().padLeft(2, '0');
String fmtHora(DateTime d) => '${_dos(d.hour)}:${_dos(d.minute)}';
String fmtFecha(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}/${d.year}';
String fmtFechaHora(DateTime d) => '${fmtFecha(d)} ${fmtHora(d)}';

/// Estado global (Provider + ChangeNotifier).
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
    // Envía los mensajes programados cuando llega su fecha y hora.
    _timer =
        Timer.periodic(const Duration(seconds: 15), (_) => procesarProgramados());
  }

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  final List<RolInfo> roles = [];
  final List<Usuario> usuarios = [];
  final List<Materia> materias = [];
  final List<Grupo> grupos = [];
  final List<Inscripcion> inscripciones = [];
  final List<Asignacion> asignaciones = [];
  final Map<String, List<HorarioDia>> horarios = {};
  final List<Conversacion> conversaciones = [];
  final List<MensajeProgramado> programados = [];
  final List<RegistroBitacora> bitacora = [];

  Usuario? actual;
  ModoHorario modoHorario = ModoHorario.auto;
  int _seq = 100;
  String _id(String p) => '$p${_seq++}';

  void _log(String accion) {
    bitacora.insert(
        0, RegistroBitacora(DateTime.now(), actual?.nombre ?? 'Sistema', accion));
    if (bitacora.length > 200) bitacora.removeLast();
  }

  // ---------------------------------------------------------------- seed
  List<HorarioDia> _horarioBase() {
    HorarioDia h(String d, String i, String f, bool a) =>
        HorarioDia(id: _id('h'), dia: d, inicio: i, fin: f, activo: a);
    return [
      h('Lunes', '08:00', '16:00', true),
      h('Martes', '08:00', '16:00', true),
      h('Miércoles', '10:00', '15:00', true),
      h('Jueves', '08:00', '14:00', true),
      h('Viernes', '08:00', '14:00', false),
    ];
  }

  void _seed() {
    roles.addAll([
      RolInfo(
          id: 'r_admin',
          nombre: 'Administrador',
          descripcion: 'Gestiona cuentas, catálogos y asignaciones.',
          nivel: 3,
          tipo: Rol.admin),
      RolInfo(
          id: 'r_docente',
          nombre: 'Docente',
          descripcion: 'Atiende a los alumnos de sus grupos y define su horario.',
          nivel: 2,
          tipo: Rol.docente),
      RolInfo(
          id: 'r_alumno',
          nombre: 'Alumno',
          descripcion: 'Consulta a sus docentes y envía mensajes.',
          nivel: 1,
          tipo: Rol.alumno),
    ]);

    Usuario u(String id, String nombre, String apellido, String correo,
            String pass, String rolId, DateTime registro) =>
        Usuario(
          id: id,
          nombre: nombre,
          apellido: apellido,
          correo: correo,
          password: pass,
          rol: rolInfo(rolId).tipo,
          rolId: rolId,
          fechaRegistro: registro,
        );

    usuarios.addAll([
      u('u1', 'Administrador', 'RappoLink', 'admin@institucion.edu.mx',
          'admin123', 'r_admin', DateTime(2026, 8, 3)),
      u('u2', 'Carlos', 'Ramírez', 'carlos@institucion.edu.mx', 'docente123',
          'r_docente', DateTime(2026, 8, 5)),
      u('u3', 'Laura', 'Hernández', 'laura@institucion.edu.mx', 'docente123',
          'r_docente', DateTime(2026, 8, 5)),
      u('u4', 'Jorge', 'Pérez', 'jorge@institucion.edu.mx', 'docente123',
          'r_docente', DateTime(2026, 8, 6)),
      u('u5', 'Ana', 'Torres', 'ana@institucion.edu.mx', 'docente123',
          'r_docente', DateTime(2026, 8, 6)),
      u('u6', 'Ángel', 'Méndez', 'angel@institucion.edu.mx', 'alumno123',
          'r_alumno', DateTime(2026, 8, 17)),
      u('u7', 'Sofía', 'García', 'sofia@institucion.edu.mx', 'alumno123',
          'r_alumno', DateTime(2026, 8, 17)),
      u('u8', 'Luis', 'Torres', 'luis@institucion.edu.mx', 'alumno123',
          'r_alumno', DateTime(2026, 8, 18)),
      u('u9', 'Mariana', 'Ruiz', 'mariana@institucion.edu.mx', 'alumno123',
          'r_alumno', DateTime(2026, 8, 18)),
    ]);

    materias.addAll([
      Materia(id: 'm1', nombre: 'Programación III', codigo: 'PRG-301'),
      Materia(id: 'm2', nombre: 'Programación II', codigo: 'PRG-201'),
      Materia(id: 'm3', nombre: 'Bases de Datos', codigo: 'BDD-301'),
      Materia(id: 'm4', nombre: 'Matemáticas', codigo: 'MAT-101'),
      Materia(id: 'm5', nombre: 'Inglés', codigo: 'ING-101'),
    ]);

    grupos.addAll([
      Grupo(id: 'g1', nombre: 'GSI-41', periodo: 'Ago–Dic 2026'),
      Grupo(id: 'g2', nombre: 'GSI-51', periodo: 'Ago–Dic 2026'),
      Grupo(id: 'g3', nombre: 'GSI-52', periodo: 'Ago–Dic 2026'),
    ]);

    inscripciones.addAll([
      Inscripcion(
          id: 'i1', alumnoId: 'u6', grupo: 'GSI-51', fecha: DateTime(2026, 8, 24)),
      Inscripcion(
          id: 'i2', alumnoId: 'u7', grupo: 'GSI-51', fecha: DateTime(2026, 8, 24)),
      Inscripcion(
          id: 'i3', alumnoId: 'u8', grupo: 'GSI-41', fecha: DateTime(2026, 8, 24)),
      Inscripcion(
          id: 'i4', alumnoId: 'u9', grupo: 'GSI-51', fecha: DateTime(2026, 8, 25)),
    ]);

    asignaciones.addAll([
      Asignacion(
          id: 'a1', docenteId: 'u2', materia: 'Programación III', grupo: 'GSI-51'),
      Asignacion(
          id: 'a2', docenteId: 'u3', materia: 'Bases de Datos', grupo: 'GSI-51'),
      Asignacion(
          id: 'a3', docenteId: 'u4', materia: 'Matemáticas', grupo: 'GSI-51'),
      Asignacion(id: 'a4', docenteId: 'u5', materia: 'Inglés', grupo: 'GSI-51'),
      Asignacion(
          id: 'a5', docenteId: 'u2', materia: 'Programación II', grupo: 'GSI-41'),
    ]);

    for (final d in usuarios.where((x) => x.rol == Rol.docente)) {
      horarios[d.id] = _horarioBase();
    }

    final now = DateTime.now();
    DateTime h(int m) => now.subtract(Duration(minutes: m));
    conversaciones.addAll([
      Conversacion(
        id: 'c1',
        alumnoId: 'u6',
        docenteId: 'u2',
        asignacionId: 'a1',
        materia: 'Programación III',
        grupo: 'GSI-51',
        mensajes: [
          Mensaje(
              deId: 'u2',
              texto: 'Recuerda revisar la actividad 4.',
              hora: h(40)),
          Mensaje(
              deId: 'u6',
              texto: 'Profe, tengo una duda sobre el punto 3.',
              hora: h(20)),
          Mensaje(
              deId: 'u6', texto: 'Tengo una duda con la actividad', hora: h(18)),
        ],
      ),
      Conversacion(
        id: 'c2',
        alumnoId: 'u7',
        docenteId: 'u2',
        asignacionId: 'a1',
        materia: 'Programación III',
        grupo: 'GSI-51',
        mensajes: [
          Mensaje(
              deId: 'u7',
              texto: 'Gracias, profesor',
              hora: h(90),
              leidoEn: h(80)),
        ],
      ),
      Conversacion(
        id: 'c3',
        alumnoId: 'u8',
        docenteId: 'u2',
        asignacionId: 'a5',
        materia: 'Programación II',
        grupo: 'GSI-41',
        mensajes: [
          Mensaje(deId: 'u8', texto: '¿Se entrega hoy?', hora: h(130)),
        ],
      ),
    ]);

    final manana = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    programados.addAll([
      MensajeProgramado(
        id: 'p1',
        conversacionId: 'c1',
        autorId: 'u6',
        texto: 'Buenos días profesor, ¿me puede resolver la duda del punto 3?',
        entrega: manana.add(const Duration(hours: 8)),
      ),
      MensajeProgramado(
        id: 'p2',
        conversacionId: 'c2',
        autorId: 'u7',
        texto: 'Gracias por la retroalimentación.',
        entrega: h(300),
        estado: EstadoProg.cancelado,
        nota: 'Cancelado por el autor',
      ),
      MensajeProgramado(
        id: 'p3',
        conversacionId: 'c3',
        autorId: 'u2',
        texto: 'Recuerda entregar la práctica antes del viernes.',
        entrega: manana.add(const Duration(hours: 9)),
      ),
    ]);
  }

  // ------------------------------------------------------------- consultas
  Usuario usuario(String id) => usuarios.firstWhere((u) => u.id == id);

  RolInfo rolInfo(String id) => roles.firstWhere((r) => r.id == id);
  String nombreRol(Usuario u) => rolInfo(u.rolId).nombre;

  List<Usuario> get docentes =>
      usuarios.where((u) => u.rol == Rol.docente).toList();
  List<Usuario> get alumnos =>
      usuarios.where((u) => u.rol == Rol.alumno).toList();
  int contar(Rol r) => usuarios.where((u) => u.rol == r).length;

  Grupo? grupoPorNombre(String nombre) {
    for (final g in grupos) {
      if (g.nombre == nombre) return g;
    }
    return null;
  }

  Materia? materiaPorNombre(String nombre) {
    for (final m in materias) {
      if (m.nombre == nombre) return m;
    }
    return null;
  }

  Asignacion? asignacionPorId(String id) {
    for (final a in asignaciones) {
      if (a.id == id) return a;
    }
    return null;
  }

  Inscripcion? inscripcionActiva(String alumnoId) {
    for (final i in inscripciones) {
      if (i.alumnoId == alumnoId && i.estado == EstadoInscripcion.activa) {
        return i;
      }
    }
    return null;
  }

  String? grupoDe(String alumnoId) => inscripcionActiva(alumnoId)?.grupo;

  int inscritosEn(String grupo) => inscripciones
      .where((i) => i.grupo == grupo && i.estado == EstadoInscripcion.activa)
      .length;

  List<Usuario> alumnosDeGrupo(String grupo) {
    final ids = inscripciones
        .where((i) => i.grupo == grupo && i.estado == EstadoInscripcion.activa)
        .map((i) => i.alumnoId)
        .toSet();
    return usuarios.where((u) => ids.contains(u.id) && u.activo).toList();
  }

  /// Una asignación habilita la comunicación solo si ella, su materia, su
  /// grupo y su docente están activos.
  bool asignacionVigente(Asignacion a) {
    final m = materiaPorNombre(a.materia);
    final g = grupoPorNombre(a.grupo);
    return a.activo &&
        (m?.activo ?? false) &&
        (g?.activo ?? false) &&
        usuario(a.docenteId).activo;
  }

  List<Asignacion> asignacionesDe(String docenteId) => asignaciones
      .where((a) => a.docenteId == docenteId && asignacionVigente(a))
      .toList();

  /// Asignaciones que ve el alumno: las del grupo donde está inscrito.
  List<Asignacion> docentesDeAlumno(Usuario alumno) {
    final g = grupoDe(alumno.id);
    if (g == null) return [];
    return asignaciones
        .where((a) => a.grupo == g && asignacionVigente(a))
        .toList();
  }

  List<Conversacion> conversacionesDe(Usuario u) {
    final l = conversaciones
        .where((c) => c.alumnoId == u.id || c.docenteId == u.id)
        .toList();
    l.sort((a, b) {
      final ha = a.ultimo?.hora ?? a.creada;
      final hb = b.ultimo?.hora ?? b.creada;
      return hb.compareTo(ha);
    });
    return l;
  }

  Conversacion conversacion(String id) =>
      conversaciones.firstWhere((c) => c.id == id);

  int pendientes(String uid) => conversaciones
      .where((c) => c.alumnoId == uid || c.docenteId == uid)
      .fold(0, (total, c) => total + c.noLeidosPara(uid));
  int pendientesDocente(String docenteId) => pendientes(docenteId);
  int pendientesAlumno(String alumnoId) => pendientes(alumnoId);

  int get conversacionesActivas =>
      conversaciones.where((c) => c.estado == EstadoConv.activa).length;

  List<MensajeProgramado> programadosDe(String uid) {
    final l = programados.where((p) => p.autorId == uid).toList();
    l.sort((a, b) => a.entrega.compareTo(b.entrega));
    return l;
  }

  int programadosPendientes(String uid) => programados
      .where((p) => p.autorId == uid && p.estado == EstadoProg.pendiente)
      .length;

  // --------------------------------------------------------------- horario
  List<HorarioDia> horariosDe(String docenteId) => horarios[docenteId] ?? [];

  List<HorarioDia> _slotsDelDia(String docenteId, String dia) =>
      horariosDe(docenteId).where((h) => h.activo && h.dia == dia).toList();

  bool dentroDeHorario(String docenteId) {
    if (modoHorario == ModoHorario.dentro) return true;
    if (modoHorario == ModoHorario.fuera) return false;
    final now = DateTime.now();
    if (now.weekday > 5) return false;
    final m = now.hour * 60 + now.minute;
    return _slotsDelDia(docenteId, diasSemana[now.weekday - 1])
        .any((h) => m >= minutos(h.inicio) && m < minutos(h.fin));
  }

  /// Texto corto para mostrar disponibilidad del docente.
  String textoDisponibilidad(String docenteId) {
    if (dentroDeHorario(docenteId)) {
      final now = DateTime.now();
      if (modoHorario == ModoHorario.auto && now.weekday <= 5) {
        final m = now.hour * 60 + now.minute;
        for (final h in _slotsDelDia(docenteId, diasSemana[now.weekday - 1])) {
          if (m >= minutos(h.inicio) && m < minutos(h.fin)) {
            return 'Disponible hasta ${h.fin}';
          }
        }
      }
      return 'Disponible ahora';
    }
    return 'Fuera de horario · ${proximaDisponibilidad(docenteId).etiqueta}';
  }

  Disponibilidad proximaDisponibilidad(String docenteId) {
    final now = DateTime.now();
    for (var i = 0; i < 8; i++) {
      final day = now.add(Duration(days: i));
      if (day.weekday > 5) continue;
      final slots = _slotsDelDia(docenteId, diasSemana[day.weekday - 1]);
      slots.sort((a, b) => minutos(a.inicio).compareTo(minutos(b.inicio)));
      for (final s in slots) {
        final ini = minutos(s.inicio);
        final start =
            DateTime(day.year, day.month, day.day, ini ~/ 60, ini % 60);
        if (start.isAfter(now)) {
          final dia = i == 0
              ? 'Hoy'
              : i == 1
                  ? 'Mañana'
                  : diasSemana[day.weekday - 1];
          return Disponibilidad(start, '$dia · ${s.inicio}');
        }
      }
    }
    final t = now.add(const Duration(days: 1));
    return Disponibilidad(DateTime(t.year, t.month, t.day, 8), 'Mañana · 08:00');
  }

  /// Valida fin > inicio y que no se empalme con otro horario activo del
  /// mismo docente y día. Devuelve el error o null.
  String? validarHorario({
    required String docenteId,
    required String dia,
    required String inicio,
    required String fin,
    required bool activo,
    String? ignorarId,
  }) {
    if (minutos(fin) <= minutos(inicio)) {
      return 'La hora de fin debe ser mayor que la de inicio.';
    }
    if (!activo) return null;
    for (final h in horariosDe(docenteId)) {
      if (h.id == ignorarId || !h.activo || h.dia != dia) continue;
      if (minutos(inicio) < minutos(h.fin) && minutos(fin) > minutos(h.inicio)) {
        return 'Se empalma con tu horario del $dia de ${h.inicio} a ${h.fin}.';
      }
    }
    return null;
  }

  String? guardarHorario(
    String docenteId, {
    HorarioDia? editar,
    required String dia,
    required String inicio,
    required String fin,
    required bool activo,
  }) {
    final err = validarHorario(
        docenteId: docenteId,
        dia: dia,
        inicio: inicio,
        fin: fin,
        activo: activo,
        ignorarId: editar?.id);
    if (err != null) return err;
    final lista = horarios.putIfAbsent(docenteId, () => []);
    if (editar == null) {
      lista.add(HorarioDia(
          id: _id('h'), dia: dia, inicio: inicio, fin: fin, activo: activo));
    } else {
      editar
        ..dia = dia
        ..inicio = inicio
        ..fin = fin
        ..activo = activo;
    }
    lista.sort((a, b) {
      final c = diasSemana.indexOf(a.dia).compareTo(diasSemana.indexOf(b.dia));
      return c != 0 ? c : minutos(a.inicio).compareTo(minutos(b.inicio));
    });
    notifyListeners();
    return null;
  }

  /// Activa o desactiva (baja lógica). Al activar se revisa el empalme.
  String? alternarHorario(String docenteId, HorarioDia h) {
    if (!h.activo) {
      final err = validarHorario(
          docenteId: docenteId,
          dia: h.dia,
          inicio: h.inicio,
          fin: h.fin,
          activo: true,
          ignorarId: h.id);
      if (err != null) return err;
    }
    h.activo = !h.activo;
    notifyListeners();
    return null;
  }

  void setModoHorario(ModoHorario m) {
    modoHorario = m;
    notifyListeners();
  }

  // ----------------------------------------------------------------- auth
  /// Devuelve null si todo está bien, o el mensaje de error.
  String? login(String correo, String pass) {
    Usuario? u;
    for (final x in usuarios) {
      if (x.correo.toLowerCase() == correo.trim().toLowerCase()) u = x;
    }
    if (u == null || !u.verificarPassword(pass)) {
      return 'Correo o contraseña incorrectos.';
    }
    if (!u.activo) {
      return 'Tu cuenta está desactivada. Contacta al administrador.';
    }
    if (!rolInfo(u.rolId).activo) {
      return 'Tu rol está desactivado. Contacta al administrador.';
    }
    actual = u;
    notifyListeners();
    return null;
  }

  /// No revela si el correo existe: la pantalla muestra siempre el mismo aviso.
  void solicitarRecuperacion(String correo) {
    final c = correo.trim().toLowerCase();
    if (usuarios.any((u) => u.correo.toLowerCase() == c)) {
      bitacora.insert(
          0,
          RegistroBitacora(DateTime.now(), 'Sistema',
              'Solicitud de recuperación de acceso para $c'));
      notifyListeners();
    }
  }

  void logout() {
    actual = null;
    notifyListeners();
  }

  // -------------------------------------------------------------- perfil
  String? actualizarPerfil({
    required String nombre,
    required String apellido,
    Uint8List? foto,
  }) {
    final me = actual;
    if (me == null) return 'Sin sesión.';
    if (nombre.trim().length < 2) return 'Ingresa tu nombre.';
    me
      ..nombrePila = nombre.trim()
      ..apellido = apellido.trim()
      ..foto = foto;
    notifyListeners();
    return null;
  }

  String? cambiarPassword(String actualPass, String nueva) {
    final me = actual;
    if (me == null) return 'Sin sesión.';
    if (!me.verificarPassword(actualPass)) {
      return 'La contraseña actual no es correcta.';
    }
    if (nueva.length < 6) return 'La nueva contraseña debe tener 6 caracteres o más.';
    me.definirPassword(nueva);
    notifyListeners();
    return null;
  }

  // ------------------------------------------------ administración: usuarios
  String? crearUsuario({
    required String nombre,
    required String apellido,
    required String correo,
    required String password,
    required RolInfo rol,
    bool activo = true,
    Uint8List? foto,
  }) {
    final mail = correo.trim().toLowerCase();
    if (usuarios.any((u) => u.correo.toLowerCase() == mail)) {
      return 'Ese correo ya está registrado.';
    }
    if (!rol.activo) return 'El rol seleccionado está inactivo.';
    final u = Usuario(
      id: _id('u'),
      nombre: nombre.trim(),
      apellido: apellido.trim(),
      correo: mail,
      password: password,
      rol: rol.tipo,
      rolId: rol.id,
      activo: activo,
      foto: foto,
    );
    usuarios.add(u);
    if (rol.tipo == Rol.docente) horarios[u.id] = _horarioBase();
    _log('Creó la cuenta de ${u.nombre} (${rol.nombre})');
    notifyListeners();
    return null;
  }

  String? editarUsuario(
    Usuario u, {
    required String nombre,
    required String apellido,
    required String correo,
    required RolInfo rol,
    required bool activo,
    Uint8List? foto,
    String? nuevaPassword,
  }) {
    final mail = correo.trim().toLowerCase();
    if (usuarios.any((x) => x.id != u.id && x.correo.toLowerCase() == mail)) {
      return 'Ese correo ya está registrado.';
    }
    final esYo = actual?.id == u.id;
    if (esYo && !activo) return 'No puedes desactivar tu propia cuenta.';
    if (esYo && rol.id != u.rolId) return 'No puedes cambiar tu propio rol.';
    if (!rol.activo && rol.id != u.rolId) {
      return 'El rol seleccionado está inactivo.';
    }
    u
      ..nombrePila = nombre.trim()
      ..apellido = apellido.trim()
      ..correo = mail
      ..rolId = rol.id
      ..rol = rol.tipo
      ..activo = activo
      ..foto = foto;
    if (nuevaPassword != null && nuevaPassword.isNotEmpty) {
      u.definirPassword(nuevaPassword);
      _log('Restableció la contraseña de ${u.nombre}');
    }
    if (rol.tipo == Rol.docente) horarios.putIfAbsent(u.id, _horarioBase);
    _log('Editó la cuenta de ${u.nombre}');
    notifyListeners();
    return null;
  }

  String? toggleActivo(Usuario u) {
    if (actual?.id == u.id) return 'No puedes desactivar tu propia cuenta.';
    u.activo = !u.activo;
    _log('${u.activo ? 'Activó' : 'Desactivó'} la cuenta de ${u.nombre}');
    notifyListeners();
    return null;
  }

  // ---------------------------------------------------- administración: roles
  String? crearRol({
    required String nombre,
    required String descripcion,
    required int nivel,
    required Rol tipo,
    bool activo = true,
  }) {
    final n = nombre.trim();
    if (roles.any((r) => r.nombre.toLowerCase() == n.toLowerCase())) {
      return 'Ya existe un rol con ese nombre.';
    }
    roles.add(RolInfo(
        id: _id('r'),
        nombre: n,
        descripcion: descripcion.trim(),
        nivel: nivel,
        tipo: tipo,
        activo: activo));
    _log('Creó el rol $n');
    notifyListeners();
    return null;
  }

  int usuariosConRol(RolInfo r) => usuarios.where((u) => u.rolId == r.id).length;

  String? editarRol(
    RolInfo r, {
    required String nombre,
    required String descripcion,
    required int nivel,
    required bool activo,
  }) {
    final n = nombre.trim();
    if (roles.any((x) => x.id != r.id && x.nombre.toLowerCase() == n.toLowerCase())) {
      return 'Ya existe un rol con ese nombre.';
    }
    final enUso = usuariosConRol(r);
    if (!activo && r.activo && enUso > 0) {
      return 'No puedes desactivar este rol: $enUso usuario(s) lo tienen asignado. '
          'Reasígnalos primero.';
    }
    r
      ..nombre = n
      ..descripcion = descripcion.trim()
      ..nivel = nivel
      ..activo = activo;
    _log('Editó el rol $n');
    notifyListeners();
    return null;
  }

  // --------------------------------------------------- administración: grupos
  String? crearGrupo(
      {required String nombre, required String periodo, bool activo = true}) {
    final n = nombre.trim().toUpperCase();
    if (grupos.any((g) => g.nombre == n)) return 'Ya existe un grupo con ese nombre.';
    grupos.add(Grupo(id: _id('g'), nombre: n, periodo: periodo, activo: activo));
    _log('Creó el grupo $n');
    notifyListeners();
    return null;
  }

  String? editarGrupo(Grupo g,
      {required String nombre, required String periodo, required bool activo}) {
    final n = nombre.trim().toUpperCase();
    if (grupos.any((x) => x.id != g.id && x.nombre == n)) {
      return 'Ya existe un grupo con ese nombre.';
    }
    final viejo = g.nombre;
    if (viejo != n) {
      for (final a in asignaciones) {
        if (a.grupo == viejo) a.grupo = n;
      }
      for (final i in inscripciones) {
        if (i.grupo == viejo) i.grupo = n;
      }
      for (final c in conversaciones) {
        if (c.grupo == viejo) c.grupo = n;
      }
    }
    g
      ..nombre = n
      ..periodo = periodo
      ..activo = activo;
    _log('Editó el grupo $n');
    notifyListeners();
    return null;
  }

  // ------------------------------------------------- administración: materias
  String? crearMateria(
      {required String nombre, required String codigo, bool activo = true}) {
    final n = nombre.trim();
    final c = codigo.trim().toUpperCase();
    if (materias.any((m) => m.nombre.toLowerCase() == n.toLowerCase())) {
      return 'Ya existe una materia con ese nombre.';
    }
    if (materias.any((m) => m.codigo == c)) return 'Ese código ya está en uso.';
    materias.add(Materia(id: _id('m'), nombre: n, codigo: c, activo: activo));
    _log('Creó la materia $n');
    notifyListeners();
    return null;
  }

  String? editarMateria(Materia m,
      {required String nombre, required String codigo, required bool activo}) {
    final n = nombre.trim();
    final c = codigo.trim().toUpperCase();
    if (materias.any((x) => x.id != m.id && x.nombre.toLowerCase() == n.toLowerCase())) {
      return 'Ya existe una materia con ese nombre.';
    }
    if (materias.any((x) => x.id != m.id && x.codigo == c)) {
      return 'Ese código ya está en uso.';
    }
    final viejo = m.nombre;
    if (viejo != n) {
      for (final a in asignaciones) {
        if (a.materia == viejo) a.materia = n;
      }
      for (final cv in conversaciones) {
        if (cv.materia == viejo) cv.materia = n;
      }
    }
    m
      ..nombre = n
      ..codigo = c
      ..activo = activo;
    _log('Editó la materia $n');
    notifyListeners();
    return null;
  }

  List<Asignacion> asignacionesDeMateria(String materia) =>
      asignaciones.where((a) => a.materia == materia).toList();

  // --------------------------------------------- administración: inscripciones
  String? _validarInscripcion({
    required String alumnoId,
    required String grupo,
    required EstadoInscripcion estado,
    String? ignorarId,
  }) {
    final g = grupoPorNombre(grupo);
    if (g == null) return 'Selecciona un grupo.';
    if (estado == EstadoInscripcion.activa) {
      if (!g.activo) return 'El grupo $grupo está inactivo.';
      for (final i in inscripciones) {
        if (i.id != ignorarId &&
            i.alumnoId == alumnoId &&
            i.estado == EstadoInscripcion.activa) {
          return 'El alumno ya tiene una inscripción activa en ${i.grupo}. '
              'Retírala o edítala primero.';
        }
      }
    }
    return null;
  }

  String? inscribir({
    required String alumnoId,
    required String grupo,
    required DateTime fecha,
    EstadoInscripcion estado = EstadoInscripcion.activa,
  }) {
    if (alumnoId.isEmpty) return 'Selecciona un alumno.';
    final al = usuario(alumnoId);
    if (al.rol != Rol.alumno || !al.activo) return 'Selecciona un alumno activo.';
    final err =
        _validarInscripcion(alumnoId: alumnoId, grupo: grupo, estado: estado);
    if (err != null) return err;
    inscripciones.add(Inscripcion(
        id: _id('i'),
        alumnoId: alumnoId,
        grupo: grupo,
        fecha: fecha,
        estado: estado));
    _log('Inscribió a ${al.nombre} en $grupo');
    notifyListeners();
    return null;
  }

  String? editarInscripcion(Inscripcion i,
      {required String grupo,
      required DateTime fecha,
      required EstadoInscripcion estado}) {
    final err = _validarInscripcion(
        alumnoId: i.alumnoId, grupo: grupo, estado: estado, ignorarId: i.id);
    if (err != null) return err;
    i
      ..grupo = grupo
      ..fecha = fecha
      ..estado = estado;
    _log('Editó la inscripción de ${usuario(i.alumnoId).nombre} ($grupo)');
    notifyListeners();
    return null;
  }

  void retirarInscripcion(Inscripcion i) {
    i.estado = EstadoInscripcion.retirada;
    _log('Retiró a ${usuario(i.alumnoId).nombre} de ${i.grupo}');
    notifyListeners();
  }

  // ------------------------------------------------ administración: asignación
  String? _validarAsignacion({
    required String docenteId,
    required String materia,
    required String grupo,
    required bool activo,
    String? ignorarId,
  }) {
    if (docenteId.isEmpty || materia.isEmpty || grupo.isEmpty) {
      return 'Selecciona docente, materia y grupo.';
    }
    if (asignaciones.any((a) =>
        a.id != ignorarId &&
        a.docenteId == docenteId &&
        a.materia == materia &&
        a.grupo == grupo)) {
      return 'Esa asignación ya existe.';
    }
    if (activo) {
      if (!(materiaPorNombre(materia)?.activo ?? false)) {
        return 'La materia $materia está inactiva.';
      }
      if (!(grupoPorNombre(grupo)?.activo ?? false)) {
        return 'El grupo $grupo está inactivo.';
      }
      if (!usuario(docenteId).activo) return 'El docente está inactivo.';
    }
    return null;
  }

  String? crearAsignacion(String docenteId, String materia, String grupo,
      {bool activo = true}) {
    final err = _validarAsignacion(
        docenteId: docenteId, materia: materia, grupo: grupo, activo: activo);
    if (err != null) return err;
    asignaciones.add(Asignacion(
        id: _id('a'),
        docenteId: docenteId,
        materia: materia,
        grupo: grupo,
        activo: activo));
    _log('Creó la asignación $materia · $grupo para ${usuario(docenteId).nombre}');
    notifyListeners();
    return null;
  }

  String? editarAsignacion(Asignacion a,
      {required String docenteId,
      required String materia,
      required String grupo,
      required bool activo}) {
    final err = _validarAsignacion(
        docenteId: docenteId,
        materia: materia,
        grupo: grupo,
        activo: activo,
        ignorarId: a.id);
    if (err != null) return err;
    a
      ..docenteId = docenteId
      ..materia = materia
      ..grupo = grupo
      ..activo = activo;
    for (final c in conversaciones.where((c) => c.asignacionId == a.id)) {
      c
        ..docenteId = docenteId
        ..materia = materia
        ..grupo = grupo;
    }
    _log('Editó la asignación $materia · $grupo');
    notifyListeners();
    return null;
  }

  String? alternarAsignacion(Asignacion a) {
    if (!a.activo) {
      final err = _validarAsignacion(
          docenteId: a.docenteId,
          materia: a.materia,
          grupo: a.grupo,
          activo: true,
          ignorarId: a.id);
      if (err != null) return err;
    }
    a.activo = !a.activo;
    _log('${a.activo ? 'Activó' : 'Desactivó'} la asignación ${a.materia} · ${a.grupo}');
    notifyListeners();
    return null;
  }

  // ------------------------------------------------------------ mensajería
  /// null = se puede conversar; si no, el motivo.
  String? motivoBloqueo(Conversacion c) {
    if (c.estado == EstadoConv.cerrada) return 'Esta conversación está cerrada.';
    if (c.estado == EstadoConv.archivada) {
      return 'Esta conversación está archivada.';
    }
    final a = asignacionPorId(c.asignacionId);
    if (a == null || !asignacionVigente(a)) {
      return 'La asignación de esta conversación está inactiva.';
    }
    if (grupoDe(c.alumnoId) != a.grupo) {
      return 'El alumno ya no está inscrito en el grupo ${a.grupo}.';
    }
    if (!usuario(c.alumnoId).activo) return 'La cuenta del alumno está inactiva.';
    return null;
  }

  /// Valida inscripción del alumno, estado de la asignación y autorización.
  String? validarInicio(Asignacion a, String alumnoId) {
    final me = actual;
    if (me == null) return 'Sin sesión.';
    if (me.rol == Rol.alumno && me.id != alumnoId) return 'No autorizado.';
    if (me.rol == Rol.docente && me.id != a.docenteId) return 'No autorizado.';
    if (me.rol == Rol.admin) return 'El administrador no inicia conversaciones.';
    if (!asignacionVigente(a)) return 'La asignación no está activa.';
    if (grupoDe(alumnoId) != a.grupo) {
      return 'El alumno no está inscrito en el grupo ${a.grupo}.';
    }
    if (!usuario(alumnoId).activo) return 'La cuenta del alumno está inactiva.';
    return null;
  }

  /// Devuelve la conversación existente o crea una nueva (ya validada).
  Conversacion abrirConversacion(Asignacion a, String alumnoId) {
    for (final c in conversaciones) {
      if (c.alumnoId == alumnoId && c.asignacionId == a.id) return c;
    }
    final c = Conversacion(
      id: _id('c'),
      alumnoId: alumnoId,
      docenteId: a.docenteId,
      asignacionId: a.id,
      materia: a.materia,
      grupo: a.grupo,
    );
    conversaciones.add(c);
    notifyListeners();
    return c;
  }

  bool _participa(Conversacion c, Usuario? u) =>
      u != null && (u.id == c.alumnoId || u.id == c.docenteId);

  void marcarLeida(String convId) {
    final c = conversacion(convId);
    final me = actual;
    if (!_participa(c, me)) return;
    var cambio = false;
    final ahora = DateTime.now();
    for (final m in c.mensajes) {
      if (m.deId != me!.id && !m.leido) {
        m.leidoEn = ahora;
        cambio = true;
      }
    }
    if (cambio) notifyListeners();
  }

  String? enviarMensaje(String convId, String texto) {
    final c = conversacion(convId);
    final me = actual;
    if (!_participa(c, me)) return 'No autorizado.';
    if (texto.trim().isEmpty) return 'Escribe un mensaje.';
    final bloqueo = motivoBloqueo(c);
    if (bloqueo != null) return bloqueo;
    c.mensajes
        .add(Mensaje(deId: me!.id, texto: texto.trim(), hora: DateTime.now()));
    notifyListeners();
    return null;
  }

  /// Archivar/reactivar: cualquier participante. Cerrar/reabrir: solo el docente.
  String? cambiarEstadoConversacion(String convId, EstadoConv nuevo) {
    final c = conversacion(convId);
    final me = actual;
    if (!_participa(c, me)) return 'No autorizado.';
    if ((nuevo == EstadoConv.cerrada || c.estado == EstadoConv.cerrada) &&
        me!.id != c.docenteId) {
      return 'Solo el docente puede cerrar o reabrir la conversación.';
    }
    c.estado = nuevo;
    notifyListeners();
    return null;
  }

  // ------------------------------------------------- mensajes programados
  String? programarMensaje({
    required String convId,
    required String texto,
    required DateTime entrega,
  }) {
    final c = conversacion(convId);
    final me = actual;
    if (!_participa(c, me)) return 'No autorizado.';
    if (texto.trim().isEmpty) return 'Escribe el mensaje.';
    if (!entrega.isAfter(DateTime.now())) {
      return 'La fecha y hora de envío deben ser futuras.';
    }
    final bloqueo = motivoBloqueo(c);
    if (bloqueo != null) return bloqueo;
    programados.add(MensajeProgramado(
      id: _id('p'),
      conversacionId: convId,
      autorId: me!.id,
      texto: texto.trim(),
      entrega: entrega,
    ));
    notifyListeners();
    return null;
  }

  String? editarProgramado(MensajeProgramado p,
      {required String texto, required DateTime entrega}) {
    if (p.estado != EstadoProg.pendiente) {
      return 'Solo se pueden editar los mensajes pendientes.';
    }
    if (texto.trim().isEmpty) return 'Escribe el mensaje.';
    if (!entrega.isAfter(DateTime.now())) {
      return 'La fecha y hora de envío deben ser futuras.';
    }
    p
      ..texto = texto.trim()
      ..entrega = entrega;
    notifyListeners();
    return null;
  }

  void cancelarProgramado(MensajeProgramado p) {
    if (p.estado != EstadoProg.pendiente) return;
    p.estado = EstadoProg.cancelado;
    p.nota = 'Cancelado por el autor';
    notifyListeners();
  }

  /// Envía los mensajes cuya fecha llegó. No envía si la inscripción o la
  /// asignación (o la conversación) ya no están activas.
  void procesarProgramados() {
    final ahora = DateTime.now();
    var cambio = false;
    for (final p in programados) {
      if (p.estado != EstadoProg.pendiente || p.entrega.isAfter(ahora)) continue;
      final c = conversacion(p.conversacionId);
      final bloqueo = motivoBloqueo(c);
      if (bloqueo != null) {
        p.estado = EstadoProg.cancelado;
        p.nota = 'No enviado: $bloqueo';
      } else {
        c.mensajes.add(Mensaje(deId: p.autorId, texto: p.texto, hora: ahora));
        p.estado = EstadoProg.enviado;
        p.enviadoEn = ahora;
      }
      cambio = true;
    }
    if (cambio) notifyListeners();
  }
}

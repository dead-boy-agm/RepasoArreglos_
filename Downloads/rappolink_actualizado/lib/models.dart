import 'dart:typed_data';

import 'security.dart';

/// Entidades del modelo ER de RappoLink:
/// ROLES, USUARIOS, MATERIAS, GRUPOS, INSCRIPCIONES, ASIGNACIONES,
/// HORARIOS_ATENCION, CONVERSACIONES, MENSAJES, MENSAJES_PROGRAMADOS.

/// Tipo base de interfaz. Cada rol del catálogo se apoya en uno de estos tres.
enum Rol { admin, docente, alumno }

extension RolX on Rol {
  String get nombre {
    switch (this) {
      case Rol.admin:
        return 'Administrador';
      case Rol.docente:
        return 'Docente';
      case Rol.alumno:
        return 'Alumno';
    }
  }
}

/// Valores controlados de nivel_acceso.
String nivelAccesoTexto(int n) {
  switch (n) {
    case 1:
      return 'Nivel 1 · Consulta y mensajería';
    case 2:
      return 'Nivel 2 · Gestión de su docencia';
    default:
      return 'Nivel 3 · Administración total';
  }
}

// ===================================================================== ROLES
class RolInfo {
  final String id;
  String nombre;
  String descripcion;
  int nivel; // 1..3
  bool activo;
  final Rol tipo;
  RolInfo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.nivel,
    required this.tipo,
    this.activo = true,
  });
}

// ================================================================== USUARIOS
class Usuario {
  final String id;
  String nombrePila;
  String apellido;
  String correo;
  String rolId;
  Rol rol;
  bool activo;
  final DateTime fechaRegistro;
  Uint8List? foto;

  /// Solo se guarda el hash con sal; nunca la contraseña.
  late String salt;
  late String passwordHash;

  Usuario({
    required this.id,
    required String nombre,
    this.apellido = '',
    required this.correo,
    required String password,
    required this.rol,
    required this.rolId,
    this.activo = true,
    DateTime? fechaRegistro,
    this.foto,
  })  : nombrePila = nombre,
        fechaRegistro = fechaRegistro ?? DateTime.now() {
    definirPassword(password);
  }

  /// Nombre completo (nombre + apellido).
  String get nombre => '$nombrePila $apellido'.trim();
  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
  String get primerNombre => nombrePila.split(' ').first;

  void definirPassword(String password) {
    salt = generarSal();
    passwordHash = hashPassword(password, salt);
  }

  bool verificarPassword(String password) =>
      hashPassword(password, salt) == passwordHash;
}

// ================================================= MATERIAS, GRUPOS, INSCRIP.
class Materia {
  final String id;
  String nombre;
  String codigo;
  bool activo;
  Materia(
      {required this.id,
      required this.nombre,
      required this.codigo,
      this.activo = true});
}

class Grupo {
  final String id;
  String nombre;
  String periodo;
  bool activo;
  Grupo(
      {required this.id,
      required this.nombre,
      required this.periodo,
      this.activo = true});
}

enum EstadoInscripcion { activa, retirada }

extension EstadoInscripcionX on EstadoInscripcion {
  String get texto =>
      this == EstadoInscripcion.activa ? 'Activa' : 'Retirada';
}

class Inscripcion {
  final String id;
  final String alumnoId;
  String grupo; // nombre del grupo
  DateTime fecha;
  EstadoInscripcion estado;
  Inscripcion({
    required this.id,
    required this.alumnoId,
    required this.grupo,
    required this.fecha,
    this.estado = EstadoInscripcion.activa,
  });
}

// ============================================================== ASIGNACIONES
class Asignacion {
  final String id;
  String docenteId;
  String materia; // nombre de la materia
  String grupo; // nombre del grupo
  bool activo;
  Asignacion({
    required this.id,
    required this.docenteId,
    required this.materia,
    required this.grupo,
    this.activo = true,
  });
}

// ====================================================== HORARIOS DE ATENCIÓN
class HorarioDia {
  final String id;
  String dia;
  String inicio; // "08:00"
  String fin; // "16:00"
  bool activo;
  HorarioDia({
    required this.id,
    required this.dia,
    required this.inicio,
    required this.fin,
    this.activo = true,
  });
}

// ====================================================== CONVERSACIONES Y MSG
class Mensaje {
  final String deId;
  final String texto;
  final DateTime hora;
  DateTime? leidoEn;
  Mensaje({
    required this.deId,
    required this.texto,
    required this.hora,
    this.leidoEn,
  });
  bool get leido => leidoEn != null;
}

enum EstadoConv { activa, archivada, cerrada }

extension EstadoConvX on EstadoConv {
  String get texto {
    switch (this) {
      case EstadoConv.activa:
        return 'Activa';
      case EstadoConv.archivada:
        return 'Archivada';
      case EstadoConv.cerrada:
        return 'Cerrada';
    }
  }
}

class Conversacion {
  final String id;
  final String alumnoId;
  String docenteId;
  final String asignacionId;
  String materia;
  String grupo;
  EstadoConv estado;
  final DateTime creada;
  final List<Mensaje> mensajes;
  Conversacion({
    required this.id,
    required this.alumnoId,
    required this.docenteId,
    required this.asignacionId,
    required this.materia,
    required this.grupo,
    this.estado = EstadoConv.activa,
    DateTime? creada,
    List<Mensaje>? mensajes,
  })  : creada = creada ?? DateTime.now(),
        mensajes = mensajes ?? [];

  Mensaje? get ultimo => mensajes.isEmpty ? null : mensajes.last;

  /// Mensajes del otro participante que [uid] aún no ha leído.
  int noLeidosPara(String uid) =>
      mensajes.where((m) => m.deId != uid && !m.leido).length;
}

enum EstadoProg { pendiente, enviado, cancelado }

extension EstadoProgX on EstadoProg {
  String get texto {
    switch (this) {
      case EstadoProg.pendiente:
        return 'Pendiente';
      case EstadoProg.enviado:
        return 'Enviado';
      case EstadoProg.cancelado:
        return 'Cancelado';
    }
  }
}

/// Borrador programado: guarda su propio contenido y estado; el mensaje real
/// se crea en la conversación solo cuando llega la fecha de envío.
class MensajeProgramado {
  final String id;
  final String conversacionId;
  final String autorId;
  String texto;
  DateTime entrega;
  EstadoProg estado;
  final DateTime creado;
  DateTime? enviadoEn;
  String? nota;
  MensajeProgramado({
    required this.id,
    required this.conversacionId,
    required this.autorId,
    required this.texto,
    required this.entrega,
    this.estado = EstadoProg.pendiente,
    DateTime? creado,
    this.enviadoEn,
    this.nota,
  }) : creado = creado ?? DateTime.now();
}

class Disponibilidad {
  final DateTime fecha;
  final String etiqueta;
  Disponibilidad(this.fecha, this.etiqueta);
}

/// Acciones administrativas relevantes.
class RegistroBitacora {
  final DateTime fecha;
  final String actor;
  final String accion;
  RegistroBitacora(this.fecha, this.actor, this.accion);
}

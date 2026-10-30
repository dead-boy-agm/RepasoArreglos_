import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rappolinkaplicacion/app_state.dart';
import 'package:rappolinkaplicacion/main.dart';
import 'package:rappolinkaplicacion/models.dart';

void main() {
  testWidgets('Splash muestra RappoLink y luego el login', (tester) async {
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const RappoLinkApp(),
    ));
    expect(find.text('RappoLink'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  group('Reglas de negocio', () {
    late AppState s;
    setUp(() => s = AppState());
    tearDown(() => s.dispose());

    test('las contraseñas se guardan como hash, no en texto legible', () {
      for (final u in s.usuarios) {
        expect(u.passwordHash.length, 64);
        expect(u.passwordHash, isNot('admin123'));
        expect(u.passwordHash, isNot('docente123'));
        expect(u.passwordHash, isNot('alumno123'));
      }
    });

    test('login válido, inválido y cuenta inactiva', () {
      expect(s.login('admin@institucion.edu.mx', 'admin123'), isNull);
      s.logout();
      expect(s.login('admin@institucion.edu.mx', 'mala'), isNotNull);
      s.usuario('u6').activo = false;
      expect(s.login('angel@institucion.edu.mx', 'alumno123'), isNotNull);
    });

    test('no se puede inscribir dos veces activo al mismo alumno', () {
      final err = s.inscribir(
          alumnoId: 'u6', grupo: 'GSI-41', fecha: DateTime(2026, 9, 1));
      expect(err, isNotNull);
    });

    test('los horarios del docente no se empalman', () {
      final err = s.guardarHorario('u2',
          dia: 'Lunes', inicio: '10:00', fin: '12:00', activo: true);
      expect(err, isNotNull);
      final ok = s.guardarHorario('u2',
          dia: 'Viernes', inicio: '15:00', fin: '17:00', activo: true);
      expect(ok, isNull);
    });

    test('no se desactiva un rol con usuarios asignados', () {
      final r = s.rolInfo('r_alumno');
      final err = s.editarRol(r,
          nombre: r.nombre,
          descripcion: r.descripcion,
          nivel: r.nivel,
          activo: false);
      expect(err, isNotNull);
    });

    test('un alumno no puede iniciar conversación fuera de su grupo', () {
      s.login('luis@institucion.edu.mx', 'alumno123'); // GSI-41
      final a = s.asignacionPorId('a2')!; // GSI-51
      expect(s.validarInicio(a, 'u8'), isNotNull);
    });

    test('el mensaje programado se envía al llegar su hora', () {
      s.login('angel@institucion.edu.mx', 'alumno123');
      final p = s.programados.firstWhere((x) => x.id == 'p1');
      final antes = s.conversacion('c1').mensajes.length;
      p.entrega = DateTime.now().subtract(const Duration(minutes: 1));
      s.procesarProgramados();
      expect(p.estado, EstadoProg.enviado);
      expect(s.conversacion('c1').mensajes.length, antes + 1);
    });
  });
}

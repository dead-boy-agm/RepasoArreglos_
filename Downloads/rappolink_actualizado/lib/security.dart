import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Sal aleatoria por usuario (16 bytes en base64url).
String generarSal() {
  final r = Random.secure();
  return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
}

/// Hash SHA-256 con sal. Las contraseñas nunca se guardan en texto legible.
///
/// Nota: en un backend real se recomienda un algoritmo lento y pensado para
/// contraseñas (bcrypt, scrypt o Argon2) en lugar de SHA-256 simple.
String hashPassword(String password, String sal) =>
    sha256.convert(utf8.encode('$sal:$password')).toString();

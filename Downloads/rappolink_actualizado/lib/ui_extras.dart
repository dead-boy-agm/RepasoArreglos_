import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Avatar de un usuario (foto de perfil si existe, inicial si no).
class UserAvatar extends StatelessWidget {
  final Usuario usuario;
  final double size;
  const UserAvatar(this.usuario, {super.key, this.size = 44});
  @override
  Widget build(BuildContext context) =>
      Avatar(usuario.inicial, size: size, foto: usuario.foto);
}

/// Pill de estado activo/inactivo.
class EstadoPill extends StatelessWidget {
  final bool activo;
  const EstadoPill(this.activo, {super.key});
  @override
  Widget build(BuildContext context) => Pill(activo ? 'Activo' : 'Inactivo',
      color: activo ? RL.green : RL.red,
      bg: activo ? RL.greenSoft : RL.redSoft);
}

/// Fila horizontal de chips para filtrar por una opción.
class ChipsFiltro extends StatelessWidget {
  final List<String> opciones;
  final String valor;
  final ValueChanged<String> onChanged;
  const ChipsFiltro(
      {super.key,
      required this.opciones,
      required this.valor,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            for (final o in opciones)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(o),
                  selected: o == valor,
                  onSelected: (_) => onChanged(o),
                ),
              ),
          ],
        ),
      );
}

/// Desplegable compacto para filtros ("Periodo: Todos").
class FiltroDrop extends StatelessWidget {
  final String label;
  final String valor;
  final List<String> opciones;
  final ValueChanged<String> onChanged;
  const FiltroDrop(
      {super.key,
      required this.label,
      required this.valor,
      required this.opciones,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RL.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: opciones.contains(valor) ? valor : opciones.first,
            isDense: true,
            style: const TextStyle(color: RL.text, fontSize: 13),
            items: [
              for (final o in opciones)
                DropdownMenuItem(value: o, child: Text('$label: $o')),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      );
}

/// Fila desplazable de [FiltroDrop].
class FiltrosFila extends StatelessWidget {
  final List<Widget> children;
  const FiltrosFila({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          children: children,
        ),
      );
}

/// Campo de solo lectura que abre un selector (fecha, hora...).
class SelectorCampo extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final VoidCallback onTap;
  const SelectorCampo(
      {super.key,
      required this.label,
      required this.valor,
      required this.icon,
      required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label, suffixIcon: Icon(icon, color: RL.muted)),
          child: Text(valor),
        ),
      );
}

/// Interruptor de estado activo/inactivo para formularios.
class CampoEstado extends StatelessWidget {
  final bool activo;
  final ValueChanged<bool>? onChanged;
  const CampoEstado({super.key, required this.activo, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: RL.border),
        ),
        child: SwitchListTile(
          value: activo,
          onChanged: onChanged,
          title: const Text('Estado'),
          subtitle: Text(activo ? 'Activo' : 'Inactivo'),
        ),
      );
}

class ErrorBox extends StatelessWidget {
  final String texto;
  const ErrorBox(this.texto, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: RL.redSoft, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.error_outline, color: RL.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: const TextStyle(color: RL.red))),
        ]),
      );
}

Future<bool> confirmar(BuildContext context, String titulo, String texto,
    {String ok = 'Confirmar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

/// Abre la galería y devuelve los bytes de la foto elegida (o null).
Future<Uint8List?> elegirFoto(BuildContext context) async {
  try {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80);
    if (x == null) return null;
    return await x.readAsBytes();
  } catch (_) {
    if (context.mounted) {
      snack(context, 'No se pudo abrir la galería.', error: true);
    }
    return null;
  }
}

Future<DateTime?> elegirFecha(BuildContext context, DateTime inicial,
    {bool permitirPasado = true}) {
  final hoy = DateTime.now();
  final primera = permitirPasado
      ? DateTime(2020)
      : DateTime(hoy.year, hoy.month, hoy.day);
  final inicio = inicial.isBefore(primera) ? primera : inicial;
  return showDatePicker(
    context: context,
    initialDate: inicio,
    firstDate: primera,
    lastDate: DateTime(hoy.year + 2, 12, 31),
  );
}

Future<DateTime?> elegirFechaHora(BuildContext context, DateTime inicial) async {
  final f = await elegirFecha(context, inicial, permitirPasado: false);
  if (f == null || !context.mounted) return null;
  final t = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(inicial));
  if (t == null) return null;
  return DateTime(f.year, f.month, f.day, t.hour, t.minute);
}

/// Devuelve la hora elegida como "HH:mm" (o null si se cancela).
Future<String?> elegirHora(BuildContext context, String actual) async {
  final p = actual.split(':');
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
  );
  if (t == null) return null;
  return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

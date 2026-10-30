import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'theme.dart';

class RLLogo extends StatelessWidget {
  final double size;
  const RLLogo({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: RL.primary,
          borderRadius: BorderRadius.circular(size * .28),
          boxShadow: [
            BoxShadow(
                color: RL.primary.withOpacity(.30),
                blurRadius: 24,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Icon(Icons.link_rounded, color: Colors.white, size: size * .55),
      );
}

class RLCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  const RLCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.color = Colors.white,
  });
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RL.border),
              ),
              child: child,
            ),
          ),
        ),
      );
}

class Avatar extends StatelessWidget {
  final String letra;
  final double size;
  final Color bg;
  final Color fg;
  final Uint8List? foto;
  const Avatar(this.letra,
      {super.key,
      this.size = 44,
      this.bg = RL.soft,
      this.fg = RL.primary,
      this.foto});
  @override
  Widget build(BuildContext context) {
    if (foto != null) {
      return ClipOval(
        child: Image.memory(foto!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(letra,
          style: TextStyle(
              color: fg, fontWeight: FontWeight.w800, fontSize: size * .4)),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color bg;
  const Pill(this.text,
      {super.key, this.color = RL.primary, this.bg = RL.soft});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.subtitle = ''});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration:
                    const BoxDecoration(color: RL.soft, shape: BoxShape.circle),
                child: Icon(icon, size: 38, color: RL.primary),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: RL.text)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: RL.muted, height: 1.4)),
              ],
            ],
          ),
        ),
      );
}

/// Encabezado para pantallas que viven dentro de una pestaña (sin AppBar).
class TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  const TabHeader(
      {super.key, required this.title, this.subtitle = '', this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: RL.text)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: const TextStyle(color: RL.muted, fontSize: 13)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search, color: RL.muted),
            isDense: true,
          ),
        ),
      );
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: RL.text)),
      );
}

class StatCard extends StatelessWidget {
  final String valor;
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const StatCard(
      {super.key,
      required this.valor,
      required this.label,
      required this.icon,
      this.color = RL.primary,
      this.bg = RL.soft});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RL.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(valor,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: RL.text)),
                  Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: RL.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

class ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;
  final Color bg;
  const ActionTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.onTap,
      this.subtitle = '',
      this.color = RL.primary,
      this.bg = RL.soft});
  @override
  Widget build(BuildContext context) => RLCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: RL.text)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style:
                            const TextStyle(color: RL.muted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: RL.muted),
          ],
        ),
      );
}

/// Banner verde/ámbar de estado de horario (docente y alumno).
class HorarioBanner extends StatelessWidget {
  final bool dentro;
  final String titulo;
  final String detalle;
  const HorarioBanner(
      {super.key,
      required this.dentro,
      required this.titulo,
      required this.detalle});
  @override
  Widget build(BuildContext context) {
    final c = dentro ? RL.green : RL.amber;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dentro ? RL.greenSoft : RL.amberSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(color: c, fontWeight: FontWeight.w800)),
                Text(detalle,
                    style: const TextStyle(color: RL.text2, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? RL.red : RL.text,
      behavior: SnackBarBehavior.floating,
    ));
}

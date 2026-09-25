import 'package:flutter/material.dart';

/// A sleek round icon button used in top bars and overlays.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final double size;
  final EdgeInsetsGeometry padding;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconColor,
  }) : padding = const EdgeInsets.all(6),
       size = 19;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: padding,
          child: Icon(icon, color: iconColor ?? Colors.white, size: size),
        ),
      ),
    );
  }
}

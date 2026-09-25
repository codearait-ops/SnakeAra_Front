import 'package:flutter/material.dart';

class TrendIndicator extends StatelessWidget {
  final String trend; // 'up' | 'down' | 'same' | 'new'

  const TrendIndicator({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    switch (trend.toLowerCase()) {
      case 'up':
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_drop_up_rounded, color: Colors.greenAccent, size: 22),
            Text(
              '▲',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case 'down':
        return const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_drop_down_rounded, color: Colors.redAccent, size: 22),
            Text(
              '▼',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case 'same':
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.remove_rounded, color: Colors.grey, size: 16),
        );
      case 'new':
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: const Text(
            'NEW',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        );
    }
  }
}

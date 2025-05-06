import 'package:flutter/material.dart';
import 'package:campus_connect/config/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final bool animate;

  const StatusBadge({
    Key? key,
    required this.status,
    this.fontSize = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.animate = false,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'accepted':
        return AppTheme.successColor;
      case 'rejected':
      case 'cancelled':
        return AppTheme.errorColor;
      case 'completed':
        return AppTheme.accentColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final Widget badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.capitalize(),
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    if (animate) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: badge,
      );
    }

    return badge;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

import 'package:flutter/material.dart';
import 'package:campus_connect/config/theme.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final double elevation;
  final bool fullWidth;

  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.borderRadius = 8,
    this.padding,
    this.icon,
    this.elevation = 2,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveWidth = fullWidth ? double.infinity : width;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: effectiveWidth,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isOutlined
                  ? Colors.transparent
                  : (backgroundColor ?? theme.primaryColor),
          foregroundColor:
              isOutlined
                  ? (textColor ?? theme.primaryColor)
                  : (textColor ?? Colors.white),
          elevation: isOutlined ? 0 : elevation,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side:
                isOutlined
                    ? BorderSide(
                      color: backgroundColor ?? theme.primaryColor,
                      width: 1.5,
                    )
                    : BorderSide.none,
          ),
          disabledBackgroundColor:
              isOutlined ? Colors.transparent : Colors.grey.shade300,
          disabledForegroundColor:
              isOutlined ? Colors.grey.shade400 : Colors.white70,
          shadowColor: Colors.black.withOpacity(0.2),
        ),
        child:
            isLoading
                ? SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOutlined
                          ? (textColor ?? theme.primaryColor)
                          : Colors.white,
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

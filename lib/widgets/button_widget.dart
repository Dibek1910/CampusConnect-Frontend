import 'package:flutter/material.dart';
import 'package:campus_connect/config/theme.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final BorderRadius? borderRadius;

  const ButtonWidget({
    Key? key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.icon,
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? AppTheme.primaryColor;
    final effectiveTextColor =
        textColor ?? (isOutlined ? effectiveBackgroundColor : Colors.white);

    return SizedBox(
      width: width,
      height: height ?? 48,
      child:
          isOutlined
              ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: effectiveBackgroundColor, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                  ),
                  padding:
                      padding ??
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: _buildButtonContent(effectiveTextColor),
              )
              : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveBackgroundColor,
                  foregroundColor: effectiveTextColor,
                  elevation: 2,
                  shadowColor: effectiveBackgroundColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                  ),
                  padding:
                      padding ??
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: _buildButtonContent(effectiveTextColor),
              ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize ?? 16,
                fontWeight: fontWeight ?? FontWeight.w600,
                letterSpacing: 0.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize ?? 16,
        fontWeight: fontWeight ?? FontWeight.w600,
        letterSpacing: 0.1,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}

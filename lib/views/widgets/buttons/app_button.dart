import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;
  final TextStyle? textStyle;

  const AppButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.icon,
      this.isLoading = false,
      this.variant = AppButtonVariant.primary,
      this.size = AppButtonSize.medium,
      this.fullWidth = true,
      this.textStyle});

  double get _height => switch (size) {
        AppButtonSize.small => 40.0,
        AppButtonSize.medium => 52.0,
        AppButtonSize.large => 60.0,
      };

  double get _fontSize => size == AppButtonSize.small ? 14.0 : 16.0;

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.primary || variant == AppButtonVariant.danger
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    final effectiveStyle = TextStyle(
      fontSize: _fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ).merge(textStyle);

    return Text(label, style: effectiveStyle);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = _buildChild(context);

    Widget button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.danger => ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
          ),
          onPressed: effectiveOnPressed,
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
    };

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: button,
    );
  }
}

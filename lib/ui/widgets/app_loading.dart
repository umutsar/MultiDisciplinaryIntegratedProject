import 'package:flutter/material.dart';

/// AppLoading: tutarlı bir yükleme göstergesi.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.size = 40, this.strokeWidth = 3});

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: theme.colorScheme.primary,
      ),
    );
  }
}



import 'package:flutter/material.dart';

/// Simple layout wrapper used across screens.
/// Provides consistent horizontal padding and optional vertical padding.
class AppLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppLayout({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

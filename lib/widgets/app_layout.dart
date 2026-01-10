import 'package:flutter/material.dart';

/// AppLayout keeps page content centered with a consistent max width and padding.
/// Use inside a Scaffold's body to constrain content on wide screens.
class AppLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  const AppLayout({super.key, required this.child, this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12), this.maxWidth = 520});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

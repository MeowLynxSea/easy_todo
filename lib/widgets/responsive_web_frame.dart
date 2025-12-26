import 'package:flutter/material.dart';

import 'package:easy_todo/utils/responsive.dart';

class ResponsiveWebFrame extends StatelessWidget {
  final Widget child;

  const ResponsiveWebFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isWebDesktop(context)) return child;

    const maxWidth = 1440.0;

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final framedChild = screenWidth > maxWidth
        ? Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          )
        : child;

    return ColoredBox(color: theme.scaffoldBackgroundColor, child: framedChild);
  }
}

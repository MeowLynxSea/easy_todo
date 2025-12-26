import 'package:flutter/material.dart';

import 'package:easy_todo/utils/responsive.dart';

class ResponsiveWebFrame extends StatelessWidget {
  final Widget child;

  const ResponsiveWebFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!isWebDesktop(context)) return child;

    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 1440 ? 32.0 : 20.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surfaceContainerLowest,
            colorScheme.surfaceContainer,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: child,
          ),
        ),
      ),
    );
  }
}

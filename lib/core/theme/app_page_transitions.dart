import 'package:flutter/material.dart';

class AppPageTransitions {
  static const Duration duration = Duration(milliseconds: 320);
  static const Duration reverseDuration = Duration(milliseconds: 260);

  static Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final zoomIn = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    final fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
    final zoomOut = Tween<double>(begin: 1, end: 1.04).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    return FadeTransition(
      opacity: fadeOut,
      child: ScaleTransition(
        scale: zoomOut,
        child: FadeTransition(
          opacity: fadeIn,
          child: ScaleTransition(scale: zoomIn, child: child),
        ),
      ),
    );
  }

  static Route<T> route<T>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name ?? page.runtimeType.toString()),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      transitionsBuilder: buildTransition,
    );
  }

  static PageTransitionsTheme theme = PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: const _AppPageTransitionsBuilder(),
    },
  );
}

class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransitions.buildTransition(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

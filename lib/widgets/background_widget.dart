import 'package:flutter/material.dart';

/// Wraps a screen with the subtle coffee-shop background image.
class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final double opacity;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.opacity = 0.06,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3F0),
        image: DecorationImage(
          image: const AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
          opacity: opacity,
        ),
      ),
      child: child,
    );
  }
}
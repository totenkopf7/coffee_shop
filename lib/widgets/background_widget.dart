// widgets/background_widget.dart
import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;
  final double opacity;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
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

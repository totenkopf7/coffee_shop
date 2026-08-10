import 'package:flutter/material.dart';

class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: const [
            Color(0xFFE0E0E0),
            Color(0xFFF5F5F5),
            Color(0xFFE0E0E0),
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: const SlidingGradientTransform(),
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }
}

class SlidingGradientTransform extends GradientTransform {
  const SlidingGradientTransform();

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * 0.5,
      0.0,
      0.0,
    );
  }
}

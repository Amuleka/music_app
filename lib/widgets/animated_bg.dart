import 'package:flutter/material.dart';

class AnimatedBg extends StatefulWidget {
  final Widget child;
  const AnimatedBg({super.key, required this.child});

  @override
  State<AnimatedBg> createState() => _AnimatedBgState();
}

class _AnimatedBgState extends State<AnimatedBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(seconds: 8))
    ..repeat(reverse: true);
  late final Animation<double> _a =
  CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) {
        final shift = _a.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1 + shift, -1),
              end: Alignment(1 - shift, 1),
              colors: const [
                Color(0xFF0E1B4B),
                Color(0xFF2A6AF0),
                Color(0xFF6AE3FF),
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

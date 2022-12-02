import 'dart:math';

import 'package:flutter/material.dart';
import 'package:social_news_app/model/theme.dart';

class ParticleWidget extends StatefulWidget {
  final Widget child;
  final int animated;

  ParticleWidget({
    super.key,
    required this.child,
    required this.animated,
  });

  @override
  State<ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<ParticleWidget>
    with TickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  late List<Particle> particles;
  late int animated;

  @override
  void initState() {
    animated = widget.animated;
    controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    animation = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener(() => setState(() {}));

    updateParticles();

    if (animated != 0) {
      controller.forward();
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ParticleWidget oldWidget) {
    animated = widget.animated;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateParticles() {
    particles = <Particle>[];
    final rand = Random();
    final intensity = animated;
    final abs = intensity < 0 ? -intensity : intensity;
    for (int i = 0; i < min(abs * 2 + 3, 50); i += 1) {
      final startPos = Offset(rand.nextDouble(), rand.nextDouble());
      final endPos = Offset(
        startPos.dx,
        startPos.dy + (0.2 + rand.nextDouble()) * (intensity < 0 ? 1 : -1),
      );
      final startSize = 64 + rand.nextDouble() * 28;
      final endSize = startSize + rand.nextDouble() * 12;
      final startColor = MyTheme.primary;
      final endColor = startColor.withAlpha(0);
      final startTime = rand.nextDouble() * 0.2;
      final endTime = 0.8 + rand.nextDouble() * 0.2;
      final x = Particle(
        startPos: startPos,
        endPos: endPos,
        startSize: startSize,
        endSize: endSize,
        startColor: startColor,
        endColor: endColor,
        startTime: startTime,
        endTime: endTime,
        icon: animated > 0
            ? Icons.arrow_drop_up_rounded
            : Icons.arrow_drop_down_rounded,
      );
      particles.add(x);
    }
    animated = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (animated != 0 && !controller.isAnimating) {
      if (controller.isCompleted || controller.isDismissed) {
        final intensity = animated.toDouble();
        print("$intensity");
        final d =
            (min(pow(intensity < 0 ? -intensity : intensity, 0.25), 4.0) * 1000)
                .toInt();
        controller = AnimationController(
            vsync: this, duration: Duration(milliseconds: d));
        animation = Tween(begin: 0.0, end: 1.0).animate(controller)
          ..addListener(() => setState(() {}));
        updateParticles();
        controller.reset();
      }
      controller.forward();
    }
    return CustomPaint(
      foregroundPainter: ParticlePainter(animation.value, particles),
      child: widget.child,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double alpha;
  final List<Particle> particles;

  ParticlePainter(this.alpha, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    if (alpha == 0.0 || alpha == 1.0) {
      return;
    }
    for (final p in particles) {
      p.draw(canvas, size, alpha);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Particle {
  final Offset startPos;
  final Offset endPos;
  final double startSize;
  final double endSize;
  final Color startColor;
  final Color endColor;
  final double startTime;
  final double endTime;
  final IconData icon;

  const Particle({
    required this.startPos,
    required this.endPos,
    required this.startSize,
    required this.endSize,
    required this.startColor,
    required this.endColor,
    required this.startTime,
    required this.endTime,
    required this.icon,
  });

  double lerpD(double x, double y, double a) {
    return x + (y - x) * a;
  }

  Offset lerpO(Offset x, Offset y, double a) {
    return Offset(lerpD(x.dx, y.dx, a), lerpD(x.dy, y.dy, a));
  }

  Offset scaleO(Offset x, Size s, double itemSize) {
    return Offset(x.dx * s.width - itemSize, x.dy * s.height);
  }

  Color lerpC(Color x, Color y, double a) {
    final r = lerpD(x.red.toDouble(), y.red.toDouble(), a).toInt();
    final g = lerpD(x.green.toDouble(), y.green.toDouble(), a).toInt();
    final b = lerpD(x.blue.toDouble(), y.blue.toDouble(), a).toInt();
    final t = lerpD(x.alpha.toDouble(), y.alpha.toDouble(), a).toInt();
    return Color.fromARGB(t, r, g, b);
  }

  void draw(Canvas canvas, Size size, double alpha) {
    late double a;
    if (alpha < startTime) {
      return;
    } else if (alpha > endTime) {
      return;
    } else if (endTime != startTime) {
      a = (alpha - startTime) * 1 / (endTime - startTime);
    } else {
      return;
    }
    if (a == 0 || a == 1) {
      return;
    }

    final s = lerpD(startSize, endSize, a);
    final c = lerpC(startColor, endColor, a);
    final o =
        lerpO(scaleO(startPos, size, s / 2), scaleO(endPos, size, s / 2), a);

    final textPainter = TextPainter(textDirection: TextDirection.rtl);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: s,
        fontFamily: icon.fontFamily,
        color: c,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, o);
  }
}

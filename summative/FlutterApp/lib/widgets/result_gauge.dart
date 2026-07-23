import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class _GaugePainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final track = Paint()
      ..color = AppColors.glassFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.35, 4.72,
        false, track);

    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: 2.35,
        endAngle: 2.35 + 4.72,
        colors: [color.withOpacity(0.5), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 2.35,
        4.72 * progress, false, arc);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Animated 0-100 score gauge, colour-coded by performance flag.
class ResultGauge extends StatefulWidget {
  final double predictedAverageScore;
  final Color color;

  const ResultGauge({super.key, required this.predictedAverageScore, required this.color});

  @override
  State<ResultGauge> createState() => _ResultGaugeState();
}

class _ResultGaugeState extends State<ResultGauge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  late final Animation<double> _anim =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = (widget.predictedAverageScore.clamp(0, 100)) / 100.0;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final progress = target * _anim.value;
        return SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _GaugePainter(progress: progress, color: widget.color),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (widget.predictedAverageScore * _anim.value).toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: widget.color,
                    ),
                  ),
                  const Text('/ 100', style: TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

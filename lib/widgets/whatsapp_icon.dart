import 'package:flutter/material.dart';

class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color? backgroundColor;

  const WhatsAppIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFFc9a063),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(color: color, backgroundColor: backgroundColor),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  final Color color;
  final Color? backgroundColor;

  _WhatsAppPainter({required this.color, this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    double scaleX = size.width / 24.0;
    double scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    if (backgroundColor != null) {
      // Draw solid bubble in backgroundColor, and phone receiver in color
      final Paint bgPaint = Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;

      Path bubblePath = Path();
      bubblePath.moveTo(12.011, 1.985);
      bubblePath.cubicTo(6.489, 1.985, 2.011, 6.462, 2.011, 11.985);
      bubblePath.cubicTo(2.011, 13.745, 2.468, 15.399, 3.269, 16.843);
      bubblePath.lineTo(1.933, 21.72);
      bubblePath.lineTo(6.924, 20.41);
      bubblePath.cubicTo(8.314, 21.163, 9.897, 21.595, 11.578, 21.595);
      bubblePath.cubicTo(17.101, 21.595, 21.578, 17.118, 21.578, 11.595);
      bubblePath.cubicTo(21.578, 6.072, 17.101, 1.985, 12.011, 1.985);
      bubblePath.close();
      canvas.drawPath(bubblePath, bgPaint);

      final Paint phonePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      Path phonePath = _getPhonePath();
      canvas.drawPath(phonePath, phonePaint);
    } else {
      // Single color cut-out using PathFillType.evenOdd so the phone is hollow
      final Paint paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      Path path = Path();
      path.fillType = PathFillType.evenOdd;

      // Outer speech bubble
      path.moveTo(12.011, 1.985);
      path.cubicTo(6.489, 1.985, 2.011, 6.462, 2.011, 11.985);
      path.cubicTo(2.011, 13.745, 2.468, 15.399, 3.269, 16.843);
      path.lineTo(1.933, 21.72);
      path.lineTo(6.924, 20.41);
      path.cubicTo(8.314, 21.163, 9.897, 21.595, 11.578, 21.595);
      path.cubicTo(17.101, 21.595, 21.578, 17.118, 21.578, 11.595);
      path.cubicTo(21.578, 6.072, 17.101, 1.985, 12.011, 1.985);
      path.close();

      // Inner phone handset cut-out
      Path phonePath = _getPhonePath();
      path.addPath(phonePath, Offset.zero);

      canvas.drawPath(path, paint);
    }
  }

  Path _getPhonePath() {
    Path phonePath = Path();
    phonePath.moveTo(17.847, 16.175);
    phonePath.cubicTo(17.603, 16.861, 16.427, 17.484, 15.893, 17.56);
    phonePath.cubicTo(15.387, 17.631, 14.732, 17.664, 14.022, 17.438);
    phonePath.cubicTo(12.878, 17.073, 11.404, 16.291, 10.231, 15.258);
    phonePath.cubicTo(8.703, 13.914, 7.496, 12.18, 6.813, 10.594);
    phonePath.cubicTo(6.386, 9.603, 6.736, 8.756, 7.065, 8.371);
    phonePath.cubicTo(7.3, 8.095, 7.606, 7.963, 7.856, 7.963);
    phonePath.cubicTo(7.974, 7.963, 8.08, 7.969, 8.174, 7.974);
    phonePath.cubicTo(8.444, 7.988, 8.58, 8.007, 8.761, 8.44);
    phonePath.cubicTo(8.984, 8.975, 9.527, 10.309, 9.594, 10.446);
    phonePath.cubicTo(9.662, 10.584, 9.707, 10.745, 9.616, 10.928);
    phonePath.cubicTo(9.525, 11.111, 9.479, 11.225, 9.344, 11.385);
    phonePath.cubicTo(9.209, 11.545, 9.06, 11.743, 8.938, 11.866);
    phonePath.cubicTo(8.801, 12.004, 8.658, 12.155, 8.818, 12.43);
    phonePath.cubicTo(8.978, 12.705, 9.529, 13.6, 10.345, 14.328);
    phonePath.cubicTo(11.394, 15.262, 12.279, 15.552, 12.554, 15.69);
    phonePath.cubicTo(12.829, 15.828, 12.989, 15.805, 13.15, 15.622);
    phonePath.cubicTo(13.31, 15.439, 13.837, 14.82, 14.021, 14.545);
    phonePath.cubicTo(14.204, 14.27, 14.387, 14.316, 14.638, 14.407);
    phonePath.cubicTo(14.89, 14.499, 16.235, 15.159, 16.51, 15.296);
    phonePath.cubicTo(16.785, 15.434, 16.968, 15.503, 17.037, 15.617);
    phonePath.cubicTo(17.106, 15.731, 17.106, 16.28, 16.862, 16.966);
    phonePath.close();
    return phonePath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

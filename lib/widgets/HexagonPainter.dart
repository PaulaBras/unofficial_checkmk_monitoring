import 'package:flutter/material.dart';

class HexagonPainter extends CustomPainter {
  final Color color;

  HexagonPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 4)
      ..lineTo(size.width, 3 * size.height / 4)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, 3 * size.height / 4)
      ..lineTo(0, size.height / 4)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Hexagon extends StatelessWidget {
  final Color color;
  final double size;

  Hexagon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HexagonPainter(color),
      size: Size(size, size),
    );
  }
}

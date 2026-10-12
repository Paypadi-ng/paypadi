import 'package:flutter/material.dart';
import 'package:paypadi/app/theme.dart';
import 'package:paypadi/core/utils/constants.dart' show Values;

class DottedDivider extends StatelessWidget {
  const DottedDivider({super.key, this.topPadding});

  final double? topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: topPadding ?? Values.v16,
        bottom: Values.v16,
      ),
      child: SizedBox(
        width: double.infinity,
        child: CustomPaint(
          painter: _DottedLinePainter(color: context.palette.dividerColor),
          size: const Size(double.infinity, 1),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  _DottedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const double dashWidth = 6;
    const double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

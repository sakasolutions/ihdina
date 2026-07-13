import 'package:flutter/material.dart';

import '../purification_live_presentation.dart';

const Color _accentGold = Color(0xFFE5C07B);
const Color _lineColor = Color(0x4DE5C07B);
const Color _fillColor = Color(0x0F1E6B52);

/// Abstrakte geometrische Konturen — bewusstes Designelement, kein Foto-Platzhalter.
class PurificationLiveVisualPainter extends CustomPainter {
  PurificationLiveVisualPainter({
    required this.category,
  });

  final PurificationLiveVisualCategory category;

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF0C1F1A),
          const Color(0xFF060E0C),
        ],
      ).createShader(Offset.zero & size);

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, bgPaint);

    final stroke = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = _fillColor
      ..style = PaintingStyle.fill;

    final accent = Paint()
      ..color = _accentGold.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = size.width * 0.62;
    final h = size.height * 0.52;

    switch (category) {
      case PurificationLiveVisualCategory.preparation:
        _drawRipple(canvas, cx, cy, w * 0.45, stroke, fill);
      case PurificationLiveVisualCategory.intention:
        canvas.drawCircle(Offset(cx, cy), w * 0.18, fill);
        canvas.drawCircle(Offset(cx, cy), w * 0.18, stroke);
        canvas.drawCircle(Offset(cx, cy), w * 0.05, accent);
      case PurificationLiveVisualCategory.basmala:
        _drawArc(canvas, cx, cy, w * 0.5, stroke);
      case PurificationLiveVisualCategory.hands:
        _drawPair(
          canvas,
          cx,
          cy,
          w * 0.22,
          h * 0.55,
          stroke,
          fill,
          vertical: true,
        );
      case PurificationLiveVisualCategory.mouth:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: w * 0.7,
              height: h * 0.22,
            ),
            const Radius.circular(20),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: w * 0.7,
              height: h * 0.22,
            ),
            const Radius.circular(20),
          ),
          stroke,
        );
      case PurificationLiveVisualCategory.nose:
        final path = Path()
          ..moveTo(cx, cy - h * 0.2)
          ..lineTo(cx + w * 0.12, cy + h * 0.15)
          ..lineTo(cx - w * 0.12, cy + h * 0.15)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
      case PurificationLiveVisualCategory.face:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: w * 0.55,
              height: h * 0.72,
            ),
            const Radius.circular(18),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(cx, cy),
              width: w * 0.55,
              height: h * 0.72,
            ),
            const Radius.circular(18),
          ),
          stroke,
        );
      case PurificationLiveVisualCategory.arms:
        _drawArm(canvas, cx - w * 0.18, cy, w * 0.35, h * 0.12, stroke, fill);
        _drawArm(canvas, cx + w * 0.18, cy, w * 0.35, h * 0.12, stroke, fill);
      case PurificationLiveVisualCategory.head:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(cx, cy + h * 0.05),
            width: w * 0.55,
            height: h * 0.5,
          ),
          3.14,
          3.14,
          false,
          stroke,
        );
        canvas.drawLine(
          Offset(cx - w * 0.28, cy + h * 0.3),
          Offset(cx + w * 0.28, cy + h * 0.3),
          stroke,
        );
      case PurificationLiveVisualCategory.ears:
        _drawEar(canvas, cx - w * 0.22, cy, h * 0.28, stroke);
        _drawEar(canvas, cx + w * 0.22, cy, h * 0.28, stroke);
      case PurificationLiveVisualCategory.feet:
        _drawPair(
          canvas,
          cx,
          cy + h * 0.08,
          w * 0.28,
          h * 0.16,
          stroke,
          fill,
          vertical: false,
        );
      case PurificationLiveVisualCategory.completion:
        canvas.drawCircle(Offset(cx, cy), w * 0.22, stroke);
        canvas.drawLine(
          Offset(cx - w * 0.08, cy),
          Offset(cx - w * 0.01, cy + h * 0.1),
          stroke,
        );
        canvas.drawLine(
          Offset(cx - w * 0.01, cy + h * 0.1),
          Offset(cx + w * 0.12, cy - h * 0.08),
          stroke,
        );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
        const Radius.circular(12),
      ),
      accent,
    );
  }

  void _drawRipple(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Paint stroke,
    Paint fill,
  ) {
    for (var i = 0; i < 3; i++) {
      final r = radius * (0.55 + i * 0.22);
      canvas.drawCircle(Offset(cx, cy), r, i == 0 ? fill : stroke);
    }
  }

  void _drawArc(
      Canvas canvas, double cx, double cy, double width, Paint stroke) {
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, cy), width: width, height: width * 0.45),
      3.4,
      2.2,
      false,
      stroke,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy + 8),
        width: width * 0.55,
        height: width * 0.2,
      ),
      0.2,
      2.6,
      false,
      stroke,
    );
  }

  void _drawPair(
    Canvas canvas,
    double cx,
    double cy,
    double itemW,
    double itemH,
    Paint stroke,
    Paint fill, {
    required bool vertical,
  }) {
    final gap = itemW * 0.35;
    for (final side in [-1.0, 1.0]) {
      final rect = vertical
          ? Rect.fromCenter(
              center: Offset(cx + side * gap, cy),
              width: itemW,
              height: itemH,
            )
          : Rect.fromCenter(
              center: Offset(cx + side * gap, cy),
              width: itemH,
              height: itemW * 0.55,
            );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        stroke,
      );
    }
  }

  void _drawArm(
    Canvas canvas,
    double cx,
    double cy,
    double length,
    double thickness,
    Paint stroke,
    Paint fill,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: length,
        height: thickness,
      ),
      Radius.circular(thickness / 2),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, stroke);
  }

  void _drawEar(
    Canvas canvas,
    double cx,
    double cy,
    double height,
    Paint stroke,
  ) {
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: height * 0.45,
        height: height,
      ),
      1.6,
      2.0,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant PurificationLiveVisualPainter oldDelegate) {
    return oldDelegate.category != category;
  }
}

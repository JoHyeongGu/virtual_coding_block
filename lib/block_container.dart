import 'package:flutter/material.dart';

enum BlockShapePos { none, topLeft, topRight, bottomLeft, bottomRight }

class BlockContainer extends StatelessWidget {
  final Widget child;
  final double height;
  final double shapeWidth;
  final double shapeHeight;
  final double borderRadius;
  final BlockShapePos blockShapePos;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry margin;

  const BlockContainer({
    super.key,
    required this.child,
    this.height = 90,
    this.shapeWidth = 45.0,
    this.shapeHeight = 20.0,
    this.borderRadius = 5.0,
    this.blockShapePos = BlockShapePos.topLeft,
    this.backgroundColor = const Color.fromARGB(255, 169, 161, 158),
    this.borderColor = Colors.white,
    this.margin = const EdgeInsets.only(top: 8),
  });

  EdgeInsetsGeometry get _effectivePadding {
    switch (blockShapePos) {
      case BlockShapePos.topLeft:
      case BlockShapePos.topRight:
        return EdgeInsets.only(top: shapeHeight);
      case BlockShapePos.bottomLeft:
      case BlockShapePos.bottomRight:
        return EdgeInsets.only(bottom: shapeHeight);
      case BlockShapePos.none:
        return EdgeInsets.zero; // 꼬다리가 없으므로 추가 여백 없음
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      padding: _effectivePadding,
      decoration: ShapeDecoration(
        color: backgroundColor,
        shadows: const [
          BoxShadow(
            color: Color.fromARGB(100, 0, 0, 0),
            blurRadius: 2,
            offset: Offset(2, 2),
          ),
        ],
        shape: _ProtrudingBorder(
          shapeWidth: shapeWidth,
          shapeHeight: shapeHeight,
          borderRadius: borderRadius,
          position: blockShapePos,
          side: BorderSide(color: borderColor, width: 4),
        ),
      ),
      child: child,
    );
  }
}

class _ProtrudingBorder extends ShapeBorder {
  final double shapeWidth;
  final double shapeHeight;
  final double borderRadius;
  final BlockShapePos position;
  final BorderSide side;

  const _ProtrudingBorder({
    required this.shapeWidth,
    required this.shapeHeight,
    required this.position,
    this.borderRadius = 0.0,
    this.side = BorderSide.none,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.width), textDirection: textDirection);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final double r = borderRadius;
    final Path path = Path();

    switch (position) {
      case BlockShapePos.none:
        // 일반 컨테이너(꼬다리 없음): 둥근 사각형 경로를 한 번에 추가
        path.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
        break;

      case BlockShapePos.topLeft:
        final innerX = rect.left + shapeWidth;
        final innerY = rect.top + shapeHeight;
        path
          ..moveTo(rect.left, rect.top + r)
          ..quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top)
          ..lineTo(innerX - r, rect.top)
          ..quadraticBezierTo(innerX, rect.top, innerX, rect.top + r)
          ..lineTo(innerX, innerY - r)
          ..quadraticBezierTo(innerX, innerY, innerX + r, innerY)
          ..lineTo(rect.right - r, innerY)
          ..quadraticBezierTo(rect.right, innerY, rect.right, innerY + r)
          ..lineTo(rect.right, rect.bottom - r)
          ..quadraticBezierTo(
            rect.right,
            rect.bottom,
            rect.right - r,
            rect.bottom,
          )
          ..lineTo(rect.left + r, rect.bottom)
          ..quadraticBezierTo(
            rect.left,
            rect.bottom,
            rect.left,
            rect.bottom - r,
          )
          ..close();
        break;

      case BlockShapePos.topRight:
        final innerX = rect.right - shapeWidth;
        final innerY = rect.top + shapeHeight;
        path
          ..moveTo(rect.left, innerY + r)
          ..quadraticBezierTo(rect.left, innerY, rect.left + r, innerY)
          ..lineTo(innerX - r, innerY)
          ..quadraticBezierTo(innerX, innerY, innerX, innerY - r)
          ..lineTo(innerX, rect.top + r)
          ..quadraticBezierTo(innerX, rect.top, innerX + r, rect.top)
          ..lineTo(rect.right - r, rect.top)
          ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r)
          ..lineTo(rect.right, rect.bottom - r)
          ..quadraticBezierTo(
            rect.right,
            rect.bottom,
            rect.right - r,
            rect.bottom,
          )
          ..lineTo(rect.left + r, rect.bottom)
          ..quadraticBezierTo(
            rect.left,
            rect.bottom,
            rect.left,
            rect.bottom - r,
          )
          ..close();
        break;

      case BlockShapePos.bottomLeft:
        final innerX = rect.left + shapeWidth;
        final innerY = rect.bottom - shapeHeight;
        path
          ..moveTo(rect.left, rect.top + r)
          ..quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top)
          ..lineTo(rect.right - r, rect.top)
          ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r)
          ..lineTo(rect.right, innerY - r)
          ..quadraticBezierTo(rect.right, innerY, rect.right - r, innerY)
          ..lineTo(innerX + r, innerY)
          ..quadraticBezierTo(innerX, innerY, innerX, innerY + r)
          ..lineTo(innerX, rect.bottom - r)
          ..quadraticBezierTo(innerX, rect.bottom, innerX - r, rect.bottom)
          ..lineTo(rect.left + r, rect.bottom)
          ..quadraticBezierTo(
            rect.left,
            rect.bottom,
            rect.left,
            rect.bottom - r,
          )
          ..close();
        break;

      case BlockShapePos.bottomRight:
        final innerX = rect.right - shapeWidth;
        final innerY = rect.bottom - shapeHeight;
        path
          ..moveTo(rect.left, rect.top + r)
          ..quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top)
          ..lineTo(rect.right - r, rect.top)
          ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r)
          ..lineTo(rect.right, rect.bottom - r)
          ..quadraticBezierTo(
            rect.right,
            rect.bottom,
            rect.right - r,
            rect.bottom,
          )
          ..lineTo(innerX + r, rect.bottom)
          ..quadraticBezierTo(innerX, rect.bottom, innerX, rect.bottom - r)
          ..lineTo(innerX, innerY + r)
          ..quadraticBezierTo(innerX, innerY, innerX - r, innerY)
          ..lineTo(rect.left + r, innerY)
          ..quadraticBezierTo(rect.left, innerY, rect.left, innerY - r)
          ..close();
        break;
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none) {
      final paint = side.toPaint();
      final path = getOuterPath(rect, textDirection: textDirection);
      canvas.drawPath(path, paint);
    }
  }

  @override
  ShapeBorder scale(double t) {
    return _ProtrudingBorder(
      shapeWidth: shapeWidth * t,
      shapeHeight: shapeHeight * t,
      borderRadius: borderRadius * t,
      position: position,
      side: side.scale(t),
    );
  }
}

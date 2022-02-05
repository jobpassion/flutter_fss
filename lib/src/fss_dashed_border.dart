//Copyright (c) 2018 Dan Field

//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:

//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.

//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

import 'dart:ui';

import 'package:flutter/widgets.dart';

/// This is a simple implementation of a border that allows to specify a dash pattern.
/// Unfortunately the standard borders of Flutter only allow solid lines.
class DashPathBorder extends Border {
  final CircularIntervalList<double>? dashTopArray;
  final CircularIntervalList<double>? dashRightArray;
  final CircularIntervalList<double>? dashBottomArray;
  final CircularIntervalList<double>? dashLeftArray;

  /// Constructor
  const DashPathBorder({
    BorderSide top = BorderSide.none,
    this.dashTopArray,
    BorderSide left = BorderSide.none,
    this.dashLeftArray,
    BorderSide right = BorderSide.none,
    this.dashRightArray,
    BorderSide bottom = BorderSide.none,
    this.dashBottomArray,
  }) : super(
          top: top,
          left: left,
          right: right,
          bottom: bottom,
        );

  factory DashPathBorder.all({
    BorderSide borderSide = const BorderSide(),
    required CircularIntervalList<double> dashArray,
  }) {
    return DashPathBorder(
      dashTopArray: dashArray,
      top: borderSide,
      right: borderSide,
      dashRightArray: dashArray,
      left: borderSide,
      dashLeftArray: dashArray,
      bottom: borderSide,
      dashBottomArray: dashArray,
    );
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (isUniform) {
      final paintRect = rect.deflate(top.width / 2.0);
      switch (top.style) {
        case BorderStyle.none:
          return;
        case BorderStyle.solid:
          if (borderRadius != null) {
            final RRect roundRect =
                RRect.fromRectAndRadius(paintRect, borderRadius.topLeft);
            canvas.drawPath(
              dashPath(Path()..addRRect(roundRect), dashArray: dashTopArray!),
              top.toPaint(),
            );
            return;
          }
          canvas.drawPath(
            dashPath(Path()..addRect(paintRect), dashArray: dashTopArray!),
            top.toPaint(),
          );
          return;
      }
    }

    assert(
      borderRadius == null,
      'A borderRadius can only be given for uniform borders.',
    );

    // Draw top line
    if (dashTopArray != null && top.style == BorderStyle.solid) {
      final paint = top.toPaint();
      final d = top.width / 2.0;
      canvas.drawPath(
        dashPath(
          Path()
            ..moveTo(rect.left, rect.top + d)
            ..lineTo(rect.right, rect.top + d),
          dashArray: dashTopArray!,
        ),
        paint,
      );
    }

    // Draw right line
    if (dashRightArray != null && right.style == BorderStyle.solid) {
      final paint = right.toPaint();
      final d = right.width / 2.0;
      canvas.drawPath(
        dashPath(
          Path()
            ..moveTo(rect.right - d, rect.top)
            ..lineTo(rect.right - d, rect.bottom),
          dashArray: dashRightArray!,
        ),
        paint,
      );
    }
    // Draw bottom line
    if (dashBottomArray != null && bottom.style == BorderStyle.solid) {
      final paint = bottom.toPaint();
      final d = bottom.width / 2.0;
      canvas.drawPath(
        dashPath(
          Path()
            ..moveTo(rect.right, rect.bottom - d)
            ..lineTo(rect.left, rect.bottom - d),
          dashArray: dashBottomArray!,
        ),
        paint,
      );
    }
    // Draw left line
    if (dashLeftArray != null && left.style == BorderStyle.solid) {
      final paint = left.toPaint();
      final d = right.width / 2.0;
      canvas.drawPath(
        dashPath(
          Path()
            ..moveTo(rect.left + d, rect.bottom)
            ..lineTo(rect.left + d, rect.top),
          dashArray: dashLeftArray!,
        ),
        paint,
      );
    }
  }

  @override
  bool get isUniform => super.isUniform && _isDashUniform;

  bool get _isDashUniform {
    return dashTopArray == dashBottomArray &&
        dashBottomArray == dashLeftArray &&
        dashLeftArray == dashRightArray;
  }
}

/// Creates a new path that is drawn from the segments of `source`.
///
/// Dash intervals are controlled by the `dashArray` - see [CircularIntervalList]
/// for examples.
///
/// `dashOffset` specifies an initial starting point for the dashing.
///
/// Passing a `source` that is an empty path will return an empty path.
Path dashPath(
  Path source, {
  required CircularIntervalList<double> dashArray,
  DashOffset? offset,
}) {
  final dashOffset = offset ?? const DashOffset.absolute(0.0);

  final Path dest = Path();
  for (final PathMetric metric in source.computeMetrics()) {
    double distance = dashOffset._calculate(metric.length);
    bool draw = true;
    while (distance < metric.length) {
      final double len = dashArray.next;
      if (draw) {
        dest.addPath(metric.extractPath(distance, distance + len), Offset.zero);
      }
      distance += len;
      draw = !draw;
    }
  }

  return dest;
}

enum _DashOffsetType { Absolute, Percentage }

/// Specifies the starting position of a dash array on a path, either as a
/// percentage or absolute value.
///
/// The internal value will be guaranteed to not be null.
class DashOffset {
  /// Create a DashOffset that will be measured as a percentage of the length
  /// of the segment being dashed.
  ///
  /// `percentage` will be clamped between 0.0 and 1.0.
  DashOffset.percentage(double percentage)
      : _rawVal = percentage.clamp(0.0, 1.0),
        _dashOffsetType = _DashOffsetType.Percentage;

  /// Create a DashOffset that will be measured in terms of absolute pixels
  /// along the length of a [Path] segment.
  const DashOffset.absolute(double start)
      : _rawVal = start,
        _dashOffsetType = _DashOffsetType.Absolute;

  final double _rawVal;
  final _DashOffsetType _dashOffsetType;

  double _calculate(double length) {
    return _dashOffsetType == _DashOffsetType.Absolute
        ? _rawVal
        : length * _rawVal;
  }
}

/// A circular array of dash offsets and lengths.
///
/// For example, the array `[5, 10]` would result in dashes 5 pixels long
/// followed by blank spaces 10 pixels long.  The array `[5, 10, 5]` would
/// result in a 5 pixel dash, a 10 pixel gap, a 5 pixel dash, a 5 pixel gap,
/// a 10 pixel dash, etc.
///
/// Note that this does not quite conform to an [Iterable<T>], because it does
/// not have a moveNext.
class CircularIntervalList<T> {
  CircularIntervalList(this._values);

  final List<T> _values;
  int _idx = 0;

  T get next {
    if (_idx >= _values.length) {
      _idx = 0;
    }
    return _values[_idx++];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CircularIntervalList &&
          runtimeType == other.runtimeType &&
          _equalsList(_values, other._values);

  @override
  int get hashCode => _hashList(_values);
}

bool _equalsList(List? list1, List? list2) {
  if (identical(list1, list2)) return true;
  if (list1 == null || list2 == null) return false;
  final length = list1.length;
  if (length != list2.length) return false;
  for (var i = 0; i < length; i++) {
    if (list1[i] != list2[i]) return false;
  }
  return true;
}

const int _hashMask = 0x7fffffff;

int _hashList(List? list) {
  if (list == null) return null.hashCode;
  var hash = 0;
  for (var i = 0; i < list.length; i++) {
    final c = list[i].hashCode;
    hash = (hash + c) & _hashMask;
    hash = (hash + (hash << 10)) & _hashMask;
    hash ^= hash >> 6;
  }
  hash = (hash + (hash << 3)) & _hashMask;
  hash ^= hash >> 11;
  hash = (hash + (hash << 15)) & _hashMask;
  return hash;
}

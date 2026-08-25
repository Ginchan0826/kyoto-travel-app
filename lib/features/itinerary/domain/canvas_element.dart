import 'dart:ui';

/// デザインキャンバス上の1要素（画像・テキスト・手書き線）。
/// 座標・サイズは論理キャンバス座標系（[CanvasElement.canvasWidth] x
/// [CanvasElement.canvasHeight]）で保存し、表示時に画面サイズへスケールする。
class CanvasElement {
  const CanvasElement({
    required this.id,
    required this.type,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.rotation = 0,
    this.imageUrl,
    this.text,
    this.points,
    this.colorValue,
    this.strokeWidth,
  });

  static const double canvasWidth = 1000;
  static const double canvasHeight = 1400;

  final String id;
  final String type; // 'image' | 'text' | 'stroke'

  // 画像・テキスト要素用
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final String? imageUrl;
  final String? text;

  // 手書き線要素用
  final List<Offset>? points;
  final int? colorValue;
  final double? strokeWidth;

  CanvasElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  }) {
    return CanvasElement(
      id: id,
      type: type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      imageUrl: imageUrl,
      text: text,
      points: points,
      colorValue: colorValue,
      strokeWidth: strokeWidth,
    );
  }

  factory CanvasElement.fromMap(Map<String, dynamic> map) {
    final rawPoints = map['points'] as List?;
    return CanvasElement(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? 'image',
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      width: (map['width'] as num?)?.toDouble() ?? 200,
      height: (map['height'] as num?)?.toDouble() ?? 200,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0,
      imageUrl: map['imageUrl'] as String?,
      text: map['text'] as String?,
      points: rawPoints?.map((p) => Offset(
            ((p as Map)['x'] as num).toDouble(),
            (p['y'] as num).toDouble(),
          )).toList(),
      colorValue: map['color'] as int?,
      strokeWidth: (map['strokeWidth'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'imageUrl': imageUrl,
      'text': text,
      if (points != null)
        'points': points!.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      if (colorValue != null) 'color': colorValue,
      if (strokeWidth != null) 'strokeWidth': strokeWidth,
    };
  }
}

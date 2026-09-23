/// Window geometry persisted between runs (physical pixels).
library;

/// Saved top-level window position and size.
class WindowBounds {
  const WindowBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Smallest geometry worth restoring; smaller values are treated as corrupt
  /// (e.g. a window saved while minimised) and ignored.
  static const int minWidth = 320;
  static const int minHeight = 240;

  final int x;
  final int y;
  final int width;
  final int height;

  /// Rebuilds bounds from a decoded JSON object, or `null` when any field is
  /// missing or not an integer.
  static WindowBounds? fromJson(Object? json) {
    if (json is! Map) return null;
    final x = json['x'];
    final y = json['y'];
    final width = json['width'];
    final height = json['height'];
    if (x is! int || y is! int || width is! int || height is! int) return null;
    return WindowBounds(x: x, y: y, width: width, height: height);
  }

  /// Whether the size is plausible enough to restore.
  bool get isUsable => width >= minWidth && height >= minHeight;

  Map<String, Object?> toJson() => <String, Object?>{
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  @override
  bool operator ==(Object other) =>
      other is WindowBounds &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() => 'WindowBounds($x, $y, ${width}x$height)';
}

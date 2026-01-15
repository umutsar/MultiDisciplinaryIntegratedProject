import 'dart:io';
import 'package:image/image.dart' as img;

/// Generates a 1024x1024 PNG icon source from the current app icon.
///
/// This helps keep icon generation consistent even if the source file isn't 1024x1024.
/// Output: assets/icon/app_icon_1024.png
Future<void> main() async {
  const inputPath = 'assets/icon/app_icon.png';
  const outputPath = 'assets/icon/app_icon_1024.png';

  final bytes = File(inputPath).readAsBytesSync();
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    stderr.writeln('Failed to decode PNG: $inputPath');
    exitCode = 2;
    return;
  }

  // Ensure square canvas (pad to square if needed).
  final int size = decoded.width > decoded.height ? decoded.width : decoded.height;
  img.Image square = decoded;
  if (decoded.width != decoded.height) {
    square = img.Image(width: size, height: size, numChannels: 4);
    img.fill(square, color: img.ColorRgba8(0, 0, 0, 0));
    final dx = (size - decoded.width) ~/ 2;
    final dy = (size - decoded.height) ~/ 2;
    img.compositeImage(square, decoded, dstX: dx, dstY: dy);
  }

  // Resize to 1024x1024 with good interpolation.
  final out = img.copyResize(
    square,
    width: 1024,
    height: 1024,
    interpolation: img.Interpolation.cubic,
  );

  File(outputPath).writeAsBytesSync(img.encodePng(out, level: 6));
  stdout.writeln('Wrote $outputPath');
}


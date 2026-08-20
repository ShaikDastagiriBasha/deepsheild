import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final source = img.decodeImage(
    File('assets/images/deepshield_icon.png').readAsBytesSync(),
  );
  if (source == null) {
    throw StateError('Unable to decode DeepShield launcher master.');
  }

  var minX = source.width;
  var minY = source.height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final luminance =
          pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114;
      final isNavyBackground = luminance < 25 && pixel.b >= pixel.r;
      if (isNavyBackground) {
        pixel.a = 0;
      } else {
        minX = x < minX ? x : minX;
        minY = y < minY ? y : minY;
        maxX = x > maxX ? x : maxX;
        maxY = y > maxY ? y : maxY;
      }
    }
  }

  if (maxX < minX || maxY < minY) {
    throw StateError('No launcher foreground was detected.');
  }

  final cropped = img.copyCrop(
    source,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
  final targetSide = 860;
  final scale = targetSide / (cropped.width > cropped.height
      ? cropped.width
      : cropped.height);
  final resized = img.copyResize(
    cropped,
    width: (cropped.width * scale).round(),
    height: (cropped.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );
  final output = img.Image(width: 1024, height: 1024, numChannels: 4);
  img.compositeImage(
    output,
    resized,
    dstX: (output.width - resized.width) ~/ 2,
    dstY: (output.height - resized.height) ~/ 2,
  );
  File('assets/images/deepshield_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(output));
}

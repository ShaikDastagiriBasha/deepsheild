import 'dart:math';
import 'package:image/image.dart' as img;

class FaceTransform {
  final double a;
  final double b;
  final double tx;
  final double ty;

  FaceTransform(this.a, this.b, this.tx, this.ty);

  // Maps destination (u,v) back to source (x,y)
  Point<double> inverse(double u, double v) {
    final dx = u - tx;
    final dy = v - ty;
    final det = a * a + b * b;
    if (det == 0) return Point(u, v);
    final x = (a * dx + b * dy) / det;
    final y = (a * dy - b * dx) / det;
    return Point(x, y);
  }
}

FaceTransform computeSimilarityTransform(List<Point<double>> src, List<Point<double>> dst) {
  if (src.length != dst.length || src.isEmpty) return FaceTransform(1, 0, 0, 0);

  double srcCx = 0, srcCy = 0;
  double dstCx = 0, dstCy = 0;

  for (int i = 0; i < src.length; i++) {
    srcCx += src[i].x;
    srcCy += src[i].y;
    dstCx += dst[i].x;
    dstCy += dst[i].y;
  }

  srcCx /= src.length;
  srcCy /= src.length;
  dstCx /= dst.length;
  dstCy /= dst.length;

  double sum1 = 0;
  double sum2 = 0;
  double sumSq = 0;

  for (int i = 0; i < src.length; i++) {
    final sx = src[i].x - srcCx;
    final sy = src[i].y - srcCy;
    final dx = dst[i].x - dstCx;
    final dy = dst[i].y - dstCy;

    sum1 += sx * dx + sy * dy;
    sum2 += sx * dy - sy * dx;
    sumSq += sx * sx + sy * sy;
  }

  if (sumSq < 1e-6) return FaceTransform(1, 0, 0, 0);

  final a = sum1 / sumSq;
  final b = sum2 / sumSq;
  final tx = dstCx - (a * srcCx - b * srcCy);
  final ty = dstCy - (b * srcCx + a * srcCy);

  return FaceTransform(a, b, tx, ty);
}

img.Image transformImage(img.Image srcImage, FaceTransform transform, int dstWidth, int dstHeight) {
  final dstImage = img.Image(width: dstWidth, height: dstHeight, numChannels: srcImage.numChannels);

  for (int v = 0; v < dstHeight; v++) {
    for (int u = 0; u < dstWidth; u++) {
      final srcP = transform.inverse(u.toDouble(), v.toDouble());
      
      // Bilinear interpolation
      final x = srcP.x;
      final y = srcP.y;

      if (x < 0 || x >= srcImage.width - 1 || y < 0 || y >= srcImage.height - 1) {
        // Out of bounds, leave pixel as 0 (black)
        continue;
      }

      final x0 = x.floor();
      final y0 = y.floor();
      final x1 = x0 + 1;
      final y1 = y0 + 1;

      final dx = x - x0;
      final dy = y - y0;

      final p00 = srcImage.getPixel(x0, y0);
      final p10 = srcImage.getPixel(x1, y0);
      final p01 = srcImage.getPixel(x0, y1);
      final p11 = srcImage.getPixel(x1, y1);

      num interp(num c00, num c10, num c01, num c11) {
        final c0 = c00 * (1 - dx) + c10 * dx;
        final c1 = c01 * (1 - dx) + c11 * dx;
        return c0 * (1 - dy) + c1 * dy;
      }

      dstImage.setPixelRgba(
        u, 
        v, 
        interp(p00.r, p10.r, p01.r, p11.r).round(),
        interp(p00.g, p10.g, p01.g, p11.g).round(),
        interp(p00.b, p10.b, p01.b, p11.b).round(),
        255
      );
    }
  }

  return dstImage;
}

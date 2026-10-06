import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

/// Display sizes for pictogram images; each maps to a maximum pixel width
/// requested from Cloudinary.
enum PictogramImageSize {
  /// Grids, thumbnails and previews (up to ~120 logical pixels).
  small(360),

  /// Full-screen pictogram in a session or preview.
  large(1000);

  const PictogramImageSize(this.maxWidth);

  final int maxWidth;
}

/// Image provider for a pictogram that keeps data usage low:
/// - asks Cloudinary for a resized, compressed WebP instead of the original
///   upload, and
/// - caches the image on disk, so it is downloaded only once instead of on
///   every app start.
ImageProvider pictogramImage(String imageUrl, PictogramImageSize size) {
  return CachedNetworkImageProvider(optimizedPictogramUrl(imageUrl, size));
}

/// Adds a Cloudinary transformation (resize + WebP + automatic quality) to
/// [imageUrl]. Non-Cloudinary URLs are returned unchanged.
String optimizedPictogramUrl(String imageUrl, PictogramImageSize size) {
  const uploadSegment = '/image/upload/';
  if (!imageUrl.contains('res.cloudinary.com') ||
      !imageUrl.contains(uploadSegment)) {
    return imageUrl;
  }
  return imageUrl.replaceFirst(
    uploadSegment,
    '${uploadSegment}w_${size.maxWidth},c_limit,f_webp,q_auto/',
  );
}

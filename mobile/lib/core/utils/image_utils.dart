import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Appends a Cloudinary resize transformation to a URL so small widgets
/// (avatars, thumbnails) don't download the full-resolution image.
///
/// e.g. cloudinaryThumb('https://res.cloudinary.com/…/upload/image.jpg', w: 200)
/// →    'https://res.cloudinary.com/…/upload/w_200,h_200,c_fill,f_auto,q_auto/image.jpg'
String cloudinaryThumb(String? url, {int w = 400}) {
  if (url == null || url.isEmpty) return '';
  // Only transform Cloudinary URLs
  if (!url.contains('res.cloudinary.com')) return url;
  return url.replaceFirst(
    '/upload/',
    '/upload/w_$w,h_$w,c_fill,f_auto,q_auto/',
  );
}

/// Drop-in replacement for Image.network that adds disk + memory caching.
/// Use [thumbWidth] for small widgets (avatars, list tiles) to request a
/// smaller image from Cloudinary rather than downloading full resolution.
Widget cachedImage(
  String? url, {
  BoxFit fit = BoxFit.cover,
  int? thumbWidth,
  double? width,
  double? height,
  Widget? placeholder,
  Widget? errorWidget,
}) {
  final resolvedUrl =
      thumbWidth != null ? cloudinaryThumb(url, w: thumbWidth) : (url ?? '');

  if (resolvedUrl.isEmpty) {
    return errorWidget ?? _defaultError();
  }

  return CachedNetworkImage(
    imageUrl: resolvedUrl,
    fit: fit,
    width: width,
    height: height,
    placeholder: (_, __) =>
        placeholder ??
        Container(
          color: const Color(0xFF191A20),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0x44FFFFFF),
              ),
            ),
          ),
        ),
    errorWidget: (_, __, ___) => errorWidget ?? _defaultError(),
    memCacheWidth: thumbWidth,
    memCacheHeight: thumbWidth,
  );
}

Widget _defaultError() => Container(
      color: const Color(0xFF191A20),
      child: const Icon(Icons.person, color: Color(0x33FFFFFF), size: 32),
    );

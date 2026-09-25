import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_constants.dart';

/// A high-performance, memory-optimized, lazy-loaded avatar widget.
///
/// Features:
/// 1. Memory caching with [memCacheWidth] and [memCacheHeight] to avoid high RAM usage
///    when rendering large server images in lists.
/// 2. Automatic disk caching using standard CachedNetworkImage engine.
/// 3. Normalizes relative URLs (e.g. `/storage/avatar/...`) to absolute backend URLs.
/// 4. Graceful fallback to [PresetAvatar] with vibrant gradients and icons.
/// 5. Shimmer placeholder to prevent layout shifts.
class AppCachedAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? avatarId;
  final double size;
  final double? iconSize;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final BoxFit fit;

  const AppCachedAvatar({
    super.key,
    required this.avatarUrl,
    this.avatarId,
    this.size = 34.0,
    this.iconSize,
    this.border,
    this.boxShadow,
    this.fit = BoxFit.cover,
  });

  /// Normalize and resolve avatar URL
  static String? resolveAvatarUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    final trimmed = rawUrl.trim().replaceAll(r'\/', '/');
    if (trimmed.isEmpty) return null;

    // Already a full absolute URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // If it is an avatar identifier rather than a path or filename
    if (trimmed.startsWith('avatar_') || (!trimmed.contains('/') && !trimmed.contains('.'))) {
      return null;
    }

    // Relative path from backend
    final host = kBaseUrl.replaceAll(RegExp(r'/api/?$'), '');
    if (trimmed.startsWith('/')) {
      return '$host$trimmed';
    }
    return '$host/$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveAvatarUrl(avatarUrl);
    final preset = getAvatarById(avatarId ?? 'avatar_1');
    final effectiveIconSize = iconSize ?? (size * 0.52);

    // Calculate memory cache dimensions based on size (scaled for high DPI, clamped)
    final cacheDim = (size * 2.5).round().clamp(60, 240);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [preset.primaryColor, preset.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
        boxShadow: boxShadow,
      ),
      child: ClipOval(
        child: (resolvedUrl != null && resolvedUrl.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: resolvedUrl,
                fit: fit,
                memCacheWidth: cacheDim,
                memCacheHeight: cacheDim,
                maxWidthDiskCache: 300,
                maxHeightDiskCache: 300,
                fadeInDuration: const Duration(milliseconds: 180),
                fadeOutDuration: const Duration(milliseconds: 150),
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: preset.primaryColor.withValues(alpha: 0.5),
                  highlightColor: preset.secondaryColor.withValues(alpha: 0.8),
                  child: Container(
                    color: Colors.white24,
                    child: Center(
                      child: Icon(
                        preset.icon,
                        color: Colors.white38,
                        size: effectiveIconSize,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
                  debugPrint('🚨 [AppCachedAvatar Error] CachedNetworkImage failed for "$url": $error. Trying Image.network fallback...');
                  return Image.network(
                    url,
                    fit: fit,
                    errorBuilder: (ctx, err, stack) {
                      debugPrint('🚨 [AppCachedAvatar Error] Image.network also failed: $err');
                      return _buildFallback(preset, effectiveIconSize);
                    },
                  );
                },
              )
            : (preset.imageUrl != null && preset.imageUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: preset.imageUrl!,
                    fit: fit,
                    memCacheWidth: cacheDim,
                    memCacheHeight: cacheDim,
                    maxWidthDiskCache: 300,
                    maxHeightDiskCache: 300,
                    placeholder: (context, url) => _buildFallback(preset, effectiveIconSize),
                    errorWidget: (context, url, error) {
                      debugPrint('🚨 [AppCachedAvatar Error] Failed to load preset "${preset.imageUrl}": $error');
                      return _buildFallback(preset, effectiveIconSize);
                    },
                  )
                : _buildFallback(preset, effectiveIconSize),
      ),
    );
  }

  Widget _buildFallback(PresetAvatar preset, double effectiveIconSize) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Icon(
          preset.icon,
          color: Colors.black87,
          size: effectiveIconSize,
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import '../../domain/media.dart';

class PhotoGridItem extends StatelessWidget {
  final Media media;
  final VoidCallback? onTap;
  final VoidCallback? onForceUpload;

  const PhotoGridItem({
    super.key,
    required this.media,
    this.onTap,
    this.onForceUpload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.localFile != null)
              Image.file(media.localFile!, fit: BoxFit.cover)
            else ...[
              if (media.blurHash.isNotEmpty) BlurHash(hash: media.blurHash),
              if (media.url.startsWith('http'))
                CachedNetworkImage(
                  imageUrl: media.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => media.blurHash.isNotEmpty
                      ? const SizedBox.shrink() // BlurHash is already showing
                      : Container(color: colorScheme.surfaceContainerHighest),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  fadeInDuration: const Duration(milliseconds: 300),
                ),
            ],
            // Optional: Add a subtle gradient or overlay if needed for selection state later
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: Colors.black.withOpacity(0.1),
                highlightColor: Colors.black.withOpacity(0.05),
              ),
            ),
            if (media.isHighlighted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1), // 邊框顏色
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Icon(
                          Icons.copy_all_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (media.isUploading)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: media.uploadProgress,
                      strokeWidth: 2,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

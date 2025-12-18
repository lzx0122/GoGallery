import 'package:flutter/material.dart';
import '../../domain/media.dart';
import 'media_thumbnail.dart';
import 'media_context_menu.dart';

class PhotoGridItem extends StatelessWidget {
  final Media media;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onForceUpload;

  const PhotoGridItem({
    super.key,
    required this.media,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.onForceUpload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaThumbnail(media: media),

          // Touch Ripple & Interaction
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: () {
                if (onDelete != null || onEdit != null) {
                  MediaContextMenu.show(
                    context,
                    media: media,
                    onDelete: onDelete ?? () {},
                    onEdit: onEdit ?? () {},
                  );
                }
              },
              splashColor: Colors.black.withOpacity(0.1),
              highlightColor: Colors.black.withOpacity(0.05),
            ),
          ),

          // Highlight Overlay (Duplicate)
          if (media.isHighlighted)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
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

          // Uploading Indicator
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
    );
  }
}

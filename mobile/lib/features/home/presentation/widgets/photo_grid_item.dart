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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transform: media.isHighlighted
          ? (Matrix4.identity()
              ..scale(1.05)
              ..translate(0.0, -2.0))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(media.isHighlighted ? 12 : 0),
        boxShadow: media.isHighlighted
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
      ),
      clipBehavior: Clip.none,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(media.isHighlighted ? 12 : 0),
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
                    color: Colors.black.withOpacity(0.1), // Lighter overlay
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.copy_all_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 14,
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
      ),
    );
  }
}

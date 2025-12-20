import 'package:flutter/material.dart';
import '../../domain/media.dart';
import 'media_thumbnail.dart';
import 'media_context_menu.dart';

class PhotoGridItem extends StatelessWidget {
  final Media media;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onSelect;
  final VoidCallback? onMap;
  final VoidCallback? onForceUpload;
  final bool isSelected;

  const PhotoGridItem({
    super.key,
    required this.media,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onEdit,
    this.onSelect,
    this.onMap,
    this.onForceUpload,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transformAlignment: Alignment.center,
      transform: media.isHighlighted || isSelected
          ? (Matrix4.identity()..scale(0.85))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          media.isHighlighted || isSelected ? 12 : 0,
        ),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 3)
            : null,
        boxShadow: media.isHighlighted
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.3),
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
                const BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                const BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
      ),
      clipBehavior: Clip.none,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          media.isHighlighted || isSelected ? 9 : 0,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaThumbnail(media: media),

            // Touch Ripple & Interaction
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress:
                    onLongPress ??
                    () {
                      if (onDelete != null || onEdit != null) {
                        MediaContextMenu.show(
                          context,
                          media: media,
                          onDelete: onDelete ?? () {},
                          onEdit: onEdit ?? () {},
                          onSelect: onSelect ?? () {},
                          onMap: onMap ?? () {},
                        );
                      }
                    },
                splashColor: colorScheme.onSurface.withOpacity(0.1),
                highlightColor: colorScheme.onSurface.withOpacity(0.05),
              ),
            ),

            // Selection Indicator
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
              ),

            // Highlight Overlay (Duplicate)
            if (media.isHighlighted)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.scrim.withOpacity(
                      0.1,
                    ), // Lighter overlay
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
                              color: colorScheme.shadow.withOpacity(0.2),
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
                  decoration: BoxDecoration(
                    color: colorScheme.scrim.withOpacity(0.54),
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

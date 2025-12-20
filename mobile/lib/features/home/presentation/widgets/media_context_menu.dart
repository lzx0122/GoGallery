import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/media.dart';
import 'media_thumbnail.dart';

class MediaContextMenu extends StatefulWidget {
  final Media media;
  final Rect originalRect;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onSelect;
  final VoidCallback onMap;

  const MediaContextMenu({
    super.key,
    required this.media,
    required this.originalRect,
    required this.onDelete,
    required this.onEdit,
    required this.onSelect,
    required this.onMap,
  });

  static Future<void> show(
    BuildContext context, {
    required Media media,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
    required VoidCallback onSelect,
    required VoidCallback onMap,
  }) async {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final rect = position & size;

    HapticFeedback.mediumImpact();

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return MediaContextMenu(
            media: media,
            originalRect: rect,
            onDelete: onDelete,
            onEdit: onEdit,
            onSelect: onSelect,
            onMap: onMap,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<MediaContextMenu> createState() => _MediaContextMenuState();
}

class _MediaContextMenuState extends State<MediaContextMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenSize = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    final rect = widget.originalRect;
    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    // Determine menu position (above or below)
    final bool showBelow = centerY < screenSize.height / 2;

    const double menuWidth = 200.0;
    final double menuLeft = (centerX - menuWidth / 2).clamp(
      16.0,
      screenSize.width - menuWidth - 16.0,
    );

    return Stack(
      children: [
        // Backdrop tap to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
        ),
        // Image
        Positioned(
          top: rect.top,
          left: rect.left,
          width: rect.width,
          height: rect.height,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaThumbnail(media: widget.media),
                ),
              );
            },
          ),
        ),
        // Menu
        Positioned(
          top: showBelow ? rect.bottom + 16 : null,
          bottom: showBelow ? null : (screenSize.height - rect.top) + 16,
          left: menuLeft,
          width: menuWidth,
          child: FadeTransition(
            opacity: _controller,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.check_circle_outline,
                    label: l10n.actionSelect,
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelect();
                    },
                  ),
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  _buildMenuItem(
                    context,
                    icon: Icons.edit_outlined,
                    label: l10n.actionEdit,
                    onTap: widget.onEdit,
                  ),
                  if (widget.media.latitude != null &&
                      widget.media.longitude != null) ...[
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    _buildMenuItem(
                      context,
                      icon: Icons.map_outlined,
                      label: l10n.actionShowOnMap,
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onMap();
                      },
                    ),
                  ],
                  Divider(height: 1, color: colorScheme.outlineVariant),
                  _buildMenuItem(
                    context,
                    icon: Icons.delete_outline,
                    label: l10n.actionDelete,
                    color: colorScheme.error,
                    onTap: () {
                      Navigator.of(context).pop(); // Close menu first
                      widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color ?? theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

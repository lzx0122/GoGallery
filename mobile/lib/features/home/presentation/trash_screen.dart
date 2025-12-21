import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/media.dart';
import 'providers/media_provider.dart';
import 'widgets/media_thumbnail.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trashListProvider.notifier).fetchTrash();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<Media> mediaList) {
    setState(() {
      _selectedIds.addAll(mediaList.map((m) => m.id));
      _isSelectionMode = true;
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _restoreSelected() async {
    final ids = _selectedIds.toList();
    _deselectAll(); // Exit selection mode immediately
    await ref.read(trashListProvider.notifier).restoreMedias(ids);
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final ids = _selectedIds.toList();
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogDeleteSelectedTitle),
        content: Text(l10n.dialogDeleteSelectedContent(ids.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.actionDeletePermanently),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deselectAll();
      await ref.read(trashListProvider.notifier).deletePermanentlyMedias(ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trashListAsync = ref.watch(trashListProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(icon: const Icon(Icons.close), onPressed: _deselectAll)
            : null,
        title: Text(
          _isSelectionMode
              ? l10n.selectedTitle(_selectedIds.length)
              : l10n.trashTitle,
        ),
        actions: [
          trashListAsync.when(
            data: (mediaList) {
              if (mediaList.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  if (!_isSelectionMode)
                    IconButton(
                      icon: const Icon(Icons.checklist),
                      onPressed: () => _selectAll(
                        mediaList,
                      ), // Start selection mode with all selected is common?
                      // Actually typically 'Select' button enters selection mode.
                      // User request: "Multi-select and Delete All".
                      // Let's make this button enter selection mode or Select All if already in mode?
                      // Let's verify behavior: Usually a "Select" button enters selection mode.
                    ),

                  if (_isSelectionMode) ...[
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      onPressed: () {
                        if (_selectedIds.length == mediaList.length) {
                          _deselectAll(); // or just clear selection but keep mode? Usually deselect all removes selection.
                        } else {
                          _selectAll(mediaList);
                        }
                      },
                      tooltip: l10n.actionSelectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.restore),
                      onPressed: _selectedIds.isEmpty ? null : _restoreSelected,
                      tooltip: l10n.actionRestore,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever),
                      onPressed: _selectedIds.isEmpty
                          ? null
                          : () => _deleteSelected(context),
                      tooltip: l10n.actionDeletePermanently,
                    ),
                  ] else ...[
                    // Non-selection mode actions if any (e.g. Empty Trash? Not requested yet but related)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton(
                        onPressed: () {
                          _selectAll(mediaList);
                        },
                        child: Text(
                          l10n.actionSelectAll,
                        ), // Explicit "Select All" as requested/implied?
                        // "Select All and Delete All" usually go together.
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: trashListAsync.when(
        data: (mediaList) {
          if (mediaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.trashEmpty,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: mediaList.length,
            itemBuilder: (context, index) {
              final media = mediaList[index];
              final isSelected = _selectedIds.contains(media.id);

              return _TrashItem(
                media: media,
                isSelectionMode: _isSelectionMode,
                isSelected: isSelected,
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleItemSelection(media.id);
                  } else {
                    _showSingleItemDialog(context, media, ref);
                  }
                },
                onLongPress: () {
                  _toggleItemSelection(media.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showSingleItemDialog(BuildContext context, Media media, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trashDialogTitle),
        content: Text(l10n.trashDialogContent),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(trashListProvider.notifier)
                  .deletePermanently(media.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.actionDeletePermanently),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(trashListProvider.notifier).restoreMedia(media.id);
            },
            child: Text(l10n.actionRestore),
          ),
        ],
      ),
    );
  }
}

class _TrashItem extends StatelessWidget {
  final Media media;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TrashItem({
    required this.media,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transformAlignment: Alignment.center,
      transform: isSelected
          ? (Matrix4.identity()..scale(0.85))
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(isSelected ? 12 : 0),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 3)
            : null,
        boxShadow: isSelected
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
        borderRadius: BorderRadius.circular(isSelected ? 9 : 0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaThumbnail(media: media),

            // Touch Ripple & Interaction
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                splashColor: colorScheme.onSurface.withOpacity(0.1),
                highlightColor: colorScheme.onSurface.withOpacity(0.05),
              ),
            ),

            if (media.mimeType.startsWith('video/'))
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),

            // Selection Indicator (Top Right)
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

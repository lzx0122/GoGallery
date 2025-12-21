import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/media.dart';
import 'providers/grid_settings_provider.dart';
import 'providers/media_provider.dart';
import 'providers/media_selection_provider.dart';
import 'widgets/photo_grid_item.dart';
import 'widgets/full_image_viewer.dart';
import 'widgets/media_thumbnail.dart';
import 'widgets/custom_bottom_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../screens/photo_editor_screen.dart';
import '../../../../services/image_processing_service.dart';
import 'trash_screen.dart';

enum _DuplicateAction { cancel, upload, uploadAll, cancelAll }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  double _baseScale = 1.0;
  int _baseColumnCount = 3;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _isProcessingDuplicates = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseColumnCount = ref.read(gridColumnCountProvider);
    _baseScale = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final newScale = details.scale;
    int newCount = (_baseColumnCount / newScale).round();
    newCount = newCount.clamp(2, 6);

    if (newCount != ref.read(gridColumnCountProvider)) {
      HapticFeedback.selectionClick();
      ref.read(gridColumnCountProvider.notifier).set(newCount);
    }
  }

  void _showFullImage({Media? media, File? file}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullImageViewer(media: media, file: file),
      ),
    );
  }

  Future<void> _scrollToItem(String id) async {
    final mediaList = ref.read(mediaListProvider).value;
    if (mediaList == null) return;

    final groupedMedia = _groupMediaByDate(mediaList);

    double offset = 0;
    final columnCount = ref.read(gridColumnCountProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - (columnCount - 1) * 2.0) / columnCount;

    // Header height estimation:
    // DateHeaderDelegate min/max extent is 48.0
    const headerHeight = 48.0;

    bool found = false;

    for (final entry in groupedMedia.entries) {
      final groupItems = entry.value;
      final indexInGroup = groupItems.indexWhere((m) => m.id == id);

      offset += headerHeight; // Add header height

      if (indexInGroup != -1) {
        final row = indexInGroup ~/ columnCount;
        offset += row * (itemWidth + 2.0);
        found = true;
        break;
      } else {
        // Add height of this group's grid
        final rows = (groupItems.length / columnCount).ceil();
        offset += rows * (itemWidth + 2.0);
      }
    }

    if (found && _scrollController.hasClients) {
      await _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _scrollToDate(DateTime date) async {
    final mediaList = ref.read(mediaListProvider).value;
    if (mediaList == null) return;

    // groupedMedia keys are sorted descending (Newest first)
    final groupedMedia = _groupMediaByDate(mediaList);

    double offset = 0;
    final columnCount = ref.read(gridColumnCountProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - (columnCount - 1) * 2.0) / columnCount;
    const headerHeight = 48.0;

    bool found = false;
    final targetDate = DateTime(date.year, date.month, date.day);

    for (final entry in groupedMedia.entries) {
      final groupDate = entry.key;

      // Since list is descending:
      // If groupDate > targetDate, this group is NEWER, so we skip it (add its height)
      if (groupDate.isAfter(targetDate)) {
        offset += headerHeight;
        final rows = (entry.value.length / columnCount).ceil();
        offset += rows * (itemWidth + 2.0);
      } else {
        // Found the first group where groupDate <= targetDate
        // This is our scroll target
        found = true;
        break;
      }
    }

    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        found ? offset : _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickDateAndJump() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1970),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await _scrollToDate(picked);
    }
  }

  Future<void> _deleteSelected(Set<String> ids) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.actionDelete),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(mediaListProvider.notifier).deleteMedias(ids.toList());
        ref.read(mediaSelectionProvider.notifier).clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting items: $e')));
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        final results = await Future.wait(
          images.map((image) async {
            final file = File(image.path);
            return await ref
                .read(mediaListProvider.notifier)
                .uploadMedia(
                  file,
                  highlightDuplicate: false,
                  takenAt: await file.lastModified(),
                );
          }),
        );

        final List<({File file, String existingId})> duplicates = [];
        final List<String> duplicateIds = [];

        for (int i = 0; i < results.length; i++) {
          if (results[i].status == UploadStatus.duplicate &&
              results[i].existingId != null) {
            duplicates.add((
              file: File(images[i].path),
              existingId: results[i].existingId!,
            ));
            duplicateIds.add(results[i].existingId!);
          }
        }

        if (mounted && duplicates.isNotEmpty) {
          // Clear all initial highlights first (though highlightDuplicate: false should prevent them)
          await ref
              .read(mediaListProvider.notifier)
              .clearHighlights(duplicateIds);
          await _processDuplicateQueue(duplicates);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
      }
    }
  }

  Future<void> _processDuplicateQueue(
    List<({File file, String existingId})> queue,
  ) async {
    setState(() {
      _isProcessingDuplicates = true;
    });

    _DuplicateAction? autoAction;

    for (int i = 0; i < queue.length; i++) {
      if (!mounted) return;
      final item = queue[i];

      if (autoAction == _DuplicateAction.uploadAll) {
        ref
            .read(mediaListProvider.notifier)
            .uploadMedia(
              item.file,
              force: true,
              takenAt: await item.file.lastModified(),
            );
        continue;
      }

      try {
        // Highlight current item
        await ref
            .read(mediaListProvider.notifier)
            .setHighlight(item.existingId);
        await _scrollToItem(item.existingId);

        // Find existing media
        final mediaList = ref.read(mediaListProvider).value;
        Media? existingMedia;
        if (mediaList != null) {
          try {
            existingMedia = mediaList.firstWhere(
              (m) => m.id == item.existingId,
            );
          } catch (_) {}
        }

        final decision = await _showDuplicateBottomSheet(
          item,
          i + 1,
          queue.length,
          existingMedia,
        );

        if (mounted) {
          // Clear highlight regardless of decision
          ref.read(mediaListProvider.notifier).clearHighlight(item.existingId);

          if (decision == _DuplicateAction.upload) {
            ref
                .read(mediaListProvider.notifier)
                .uploadMedia(
                  item.file,
                  force: true,
                  takenAt: await item.file.lastModified(),
                );
          } else if (decision == _DuplicateAction.uploadAll) {
            autoAction = _DuplicateAction.uploadAll;
            ref
                .read(mediaListProvider.notifier)
                .uploadMedia(
                  item.file,
                  force: true,
                  takenAt: await item.file.lastModified(),
                );
          } else if (decision == _DuplicateAction.cancelAll) {
            break;
          }
        }
      } catch (e) {
        debugPrint('Error processing duplicate item: $e');
        // Ensure highlight is cleared even if error occurs
        if (mounted) {
          ref.read(mediaListProvider.notifier).clearHighlight(item.existingId);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isProcessingDuplicates = false;
      });
    }
  }

  Future<void> _editMedia(Media media) async {
    final l10n = AppLocalizations.of(context)!;
    File? fileToEdit;

    // 1. Get File
    if (media.localFile != null && media.localFile!.existsSync()) {
      fileToEdit = media.localFile!;
    } else {
      // Download to temp
      try {
        // Show loading
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.editorDownloadingImage)));
        }

        final url = Uri.parse(media.url);
        debugPrint('Downloading image from: $url');

        final user = ref.read(authProvider).value;
        final token = user?.token;
        final headers = token != null
            ? {'Authorization': 'Bearer $token'}
            : <String, String>{};

        final response = await http.get(url, headers: headers);

        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          // Use id or hash
          final ext = path.extension(media.originalFilename).isEmpty
              ? '.jpg'
              : path.extension(media.originalFilename);
          fileToEdit = File('${tempDir.path}/${media.id}_edit$ext');
          await fileToEdit.writeAsBytes(response.bodyBytes);
        } else {
          debugPrint('Download failed with status: ${response.statusCode}');
          throw Exception(
            'Failed to download image (Status: ${response.statusCode})',
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.editorPrepareFailed(e.toString()))),
          );
        }
        return;
      }
    }

    if (!mounted || fileToEdit == null) return;

    // 2. Open Editor
    final resultBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoEditorScreen(imageFile: fileToEdit!),
      ),
    );

    // 3. Handle Result
    if (resultBytes != null) {
      // Save to file and upload
      try {
        final tempDir = await getTemporaryDirectory();
        final fileName =
            'edited_${DateTime.now().millisecondsSinceEpoch}.png'; // Editor output is likely PNG or original format. ProImageEditor usually returns standard bytes.
        final savedFile = File('${tempDir.path}/$fileName');
        await savedFile.writeAsBytes(resultBytes);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.editorSavingImage)));

          // Upload as new media
          await ref.read(mediaListProvider.notifier).uploadMedia(savedFile);

          // Reset selection if any
          ref.read(mediaSelectionProvider.notifier).clear();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.editorSaveFailed(e.toString()))),
          );
        }
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  Future<_DuplicateAction> _showDuplicateBottomSheet(
    ({File file, String existingId}) item,
    int current,
    int total,
    Media? existingMedia,
  ) async {
    final completer = Completer<_DuplicateAction>();

    // Pre-fetch file stats
    final int newFileSize = await item.file.length();
    final DateTime newFileDate = await item.file.lastModified();

    if (!mounted) return _DuplicateAction.cancel;

    final controller = _scaffoldKey.currentState?.showBottomSheet(
      (context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${l10n.uploadDuplicate} ($current/$total)",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Comparison Cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing Media Card
                  Expanded(
                    child: _buildComparisonCard(
                      context: context,
                      title: l10n.duplicateExisting,
                      isNew: false,
                      image: existingMedia != null
                          ? MediaThumbnail(media: existingMedia)
                          : const Icon(Icons.broken_image),
                      size: existingMedia != null
                          ? _formatSize(existingMedia.sizeBytes)
                          : "-",
                      date: existingMedia != null
                          ? (existingMedia.takenAt != null
                                ? _formatDate(existingMedia.takenAt!)
                                : _formatDate(existingMedia.uploadedAt))
                          : "-",
                      onTap: () => _showFullImage(media: existingMedia),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // New File Card
                  Expanded(
                    child: _buildComparisonCard(
                      context: context,
                      title: l10n.duplicateNew,
                      isNew: true,
                      image: Image.file(item.file, fit: BoxFit.cover),
                      size: _formatSize(newFileSize),
                      date: _formatDate(newFileDate),
                      onTap: () => _showFullImage(file: item.file),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Primary Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (!completer.isCompleted) {
                          completer.complete(_DuplicateAction.cancel);
                        }
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(l10n.duplicateSkip),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!completer.isCompleted) {
                          completer.complete(_DuplicateAction.upload);
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(l10n.duplicateKeep),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Batch Actions
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    if (!completer.isCompleted) {
                      completer.complete(_DuplicateAction.cancelAll);
                    }
                  },
                  icon: const Icon(Icons.layers_outlined),
                  label: Text(l10n.duplicateSkipRemaining(total - current)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: TextButton.icon(
                  onPressed: () {
                    if (!completer.isCompleted) {
                      completer.complete(_DuplicateAction.uploadAll);
                    }
                  },
                  icon: Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  label: Text(
                    l10n.duplicateForceUploadAll,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16), // Safe area
            ],
          ),
        );
      },
      backgroundColor: Colors.transparent,
      enableDrag: false,
    );

    controller?.closed.then((_) {
      if (!completer.isCompleted) {
        completer.complete(_DuplicateAction.cancel);
      }
    });

    // If controller is null (shouldn't happen), complete with cancel
    if (controller == null && !completer.isCompleted) {
      completer.complete(_DuplicateAction.cancel);
    }

    // Wrap the completer to close the sheet when completed
    return completer.future.then((action) {
      controller?.close();
      return action;
    });
  }

  Widget _buildComparisonCard({
    required BuildContext context,
    required String title,
    required bool isNew,
    required Widget image,
    required String size,
    required String date,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isNew
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: isNew ? Border.all(color: colorScheme.primary, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: onTap,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: image,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: isNew ? null : 8,
                right: isNew ? 8 : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isNew
                        ? colorScheme.primary
                        : colorScheme.scrim.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.scrim.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  size,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<DateTime, List<Media>> _groupMediaByDate(List<Media> mediaList) {
    final groups = <DateTime, List<Media>>{};
    for (final media in mediaList) {
      final date = media.takenAt ?? media.uploadedAt;
      final key = DateTime(date.year, date.month, date.day);
      if (!groups.containsKey(key)) {
        groups[key] = [];
      }
      groups[key]!.add(media);
    }
    // Sort keys descending
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedGroups = <DateTime, List<Media>>{};
    for (final key in sortedKeys) {
      sortedGroups[key] = groups[key]!;
    }
    return sortedGroups;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final gridColumnCount = ref.watch(gridColumnCountProvider);
    final mediaListAsync = ref.watch(mediaListProvider);
    final selectedIds = ref.watch(mediaSelectionProvider);
    final isSelecting = selectedIds.isNotEmpty;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: _currentIndex == 0
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverAppBar(
                          floating: true,
                          snap: true,
                          backgroundColor: isSelecting
                              ? colorScheme.surfaceContainerHighest
                              : colorScheme.surface.withOpacity(0.95),
                          surfaceTintColor: Colors.transparent,
                          leading: isSelecting
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    ref
                                        .read(mediaSelectionProvider.notifier)
                                        .clear();
                                  },
                                )
                              : null,
                          title: isSelecting
                              ? Text(
                                  '${selectedIds.length}',
                                  style: theme.textTheme.titleLarge,
                                )
                              : Text(
                                  l10n.appTitle,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                          centerTitle: false,
                          actions: isSelecting
                              ? [
                                  if (selectedIds.length == 1)
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () {
                                        final selectedId = selectedIds.first;
                                        final mediaList = ref
                                            .read(mediaListProvider)
                                            .value;
                                        final media = mediaList?.firstWhere(
                                          (m) => m.id == selectedId,
                                        );

                                        if (media != null) {
                                          _editMedia(media);
                                        }
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.share_outlined),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Share feature coming soon',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      _deleteSelected(selectedIds);
                                    },
                                  ),
                                ]
                              : [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                    ),
                                    onPressed: _pickDateAndJump,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.map_outlined),
                                    onPressed: () => context.push('/map'),
                                  ),
                                  if (user != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 16.0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => context.push('/profile'),
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor:
                                              colorScheme.primaryContainer,
                                          backgroundImage:
                                              (user.photoUrl != null &&
                                                  user.photoUrl!.startsWith(
                                                    'http',
                                                  ))
                                              ? NetworkImage(user.photoUrl!)
                                              : null,
                                          child:
                                              (user.photoUrl == null ||
                                                  !user.photoUrl!.startsWith(
                                                    'http',
                                                  ))
                                              ? Text(
                                                  (user.name != null &&
                                                          user.name!.isNotEmpty)
                                                      ? user.name!
                                                            .substring(0, 1)
                                                            .toUpperCase()
                                                      : 'U',
                                                  style: TextStyle(
                                                    color: colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                ],
                        ),
                        ...mediaListAsync.when(
                          data: (mediaList) {
                            if (mediaList.isEmpty) {
                              return [
                                SliverFillRemaining(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          size: 64,
                                          color: colorScheme.outline,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          l10n.homeEmptyTitle,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          l10n.homeEmptyDescription,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ];
                            }

                            final groupedMedia = _groupMediaByDate(mediaList);

                            return groupedMedia.entries.expand((entry) {
                              return [
                                SliverToBoxAdapter(
                                  child: _DateHeader(date: entry.key),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2.0,
                                  ),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: gridColumnCount,
                                          mainAxisSpacing: 2.0,
                                          crossAxisSpacing: 2.0,
                                          childAspectRatio: 1.0,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final media = entry.value[index];
                                      final isSelected = selectedIds.contains(
                                        media.id,
                                      );
                                      return PhotoGridItem(
                                        media: media,
                                        isSelected: isSelected,
                                        onTap: () {
                                          if (isSelecting) {
                                            ref
                                                .read(
                                                  mediaSelectionProvider
                                                      .notifier,
                                                )
                                                .toggle(media.id);
                                          } else {
                                            _showFullImage(media: media);
                                          }
                                        },
                                        onMap: () {
                                          context.push('/map?id=${media.id}');
                                        },
                                        onSelect: () {
                                          ref
                                              .read(
                                                mediaSelectionProvider.notifier,
                                              )
                                              .select(media.id);
                                        },
                                        onDelete: () {
                                          _deleteSelected({media.id});
                                        },
                                        onEdit: () {
                                          _editMedia(media);
                                        },
                                      );
                                    }, childCount: entry.value.length),
                                  ),
                                ),
                              ];
                            }).toList();
                          },
                          loading: () => [
                            const SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                          error: (err, stack) => [
                            SliverFillRemaining(
                              child: Center(child: Text('Error: $err')),
                            ),
                          ],
                        ),
                        // Add some bottom padding for the FAB and Floating Nav Bar
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  )
                : const TrashScreen(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavigation(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton:
          (_currentIndex != 0 || _isProcessingDuplicates || isSelecting)
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: FloatingActionButton(
                onPressed: _pickAndUploadImage, // 原本的 icon 改放在 child
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 2,
                tooltip: l10n.actionUpload,
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                ), // 建議補上這個，長按按鈕時會顯示文字提示 (Accessibility)
              ),
            ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          color: colorScheme.surface.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                _formatDateTitle(context, date, l10n),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              if (!_isToday(date) && !_isYesterday(date))
                Text(
                  DateFormat.y(
                    Localizations.localeOf(context).toString(),
                  ).format(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTitle(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return l10n.dateToday;
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return l10n.dateYesterday;
    } else {
      final locale = Localizations.localeOf(context).toString();
      return DateFormat.MMMd(locale).format(date);
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }
}

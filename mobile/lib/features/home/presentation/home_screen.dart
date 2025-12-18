import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/grid_settings_provider.dart';
import 'providers/media_provider.dart';
import 'widgets/photo_grid_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _baseScale = 1.0;
  int _baseColumnCount = 3;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

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

  Future<void> _scrollToItem(String id) async {
    final mediaList = ref.read(mediaListProvider).value;
    if (mediaList == null) return;

    final index = mediaList.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final columnCount = ref.read(gridColumnCountProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    // Assuming 2.0 spacing
    final itemWidth = (screenWidth - (columnCount - 1) * 2.0) / columnCount;
    final row = index ~/ columnCount;

    // Calculate offset: row * itemHeight + spacing
    // itemHeight = itemWidth (aspect ratio 1.0)
    final offset = row * (itemWidth + 2.0);

    // Add some padding to show context (e.g. center it or show a bit above)
    // Let's try to center it in the viewport if possible, or at least bring it to top
    // Viewport height is roughly screenHeight - kToolbarHeight - statusBarHeight
    // But simple animateTo is usually enough.

    // Ensure we don't scroll past bounds (ScrollController handles this mostly)
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        final result = await ref
            .read(mediaListProvider.notifier)
            .uploadMedia(file);

        if (result.status == UploadStatus.duplicate && mounted) {
          if (result.existingId != null) {
            await _scrollToItem(result.existingId!);
          }

          // Show SnackBar
          ScaffoldMessenger.of(context)
              .showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.uploadDuplicate,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        child: Text(
                          AppLocalizations.of(context)!.actionCancel,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ref
                              .read(mediaListProvider.notifier)
                              .uploadMedia(file, force: true);
                        },
                        child: Text(
                          AppLocalizations.of(context)!.actionUpload,
                          style: const TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .closed
              .then((_) {
                if (result.existingId != null) {
                  ref
                      .read(mediaListProvider.notifier)
                      .clearHighlight(result.existingId!);
                }
              });
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final gridColumnCount = ref.watch(gridColumnCountProvider);
    final mediaListAsync = ref.watch(mediaListProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colorScheme.surface.withOpacity(0.95),
              surfaceTintColor: Colors.transparent,
              title: Text(
                l10n.appTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: false,
              actions: [
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage:
                            (user.photoUrl != null &&
                                user.photoUrl!.startsWith('http'))
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child:
                            (user.photoUrl == null ||
                                !user.photoUrl!.startsWith('http'))
                            ? Text(
                                (user.name != null && user.name!.isNotEmpty)
                                    ? user.name!.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            mediaListAsync.when(
              data: (mediaList) {
                if (mediaList.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.homeEmptyTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.homeEmptyDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridColumnCount,
                      mainAxisSpacing: 2.0,
                      crossAxisSpacing: 2.0,
                      childAspectRatio: 1.0,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final media = mediaList[index];
                      return PhotoGridItem(
                        media: media,
                        onTap: () {
                          // TODO: Navigate to photo details
                        },
                        onDelete: () {
                          ref
                              .read(mediaListProvider.notifier)
                              .deleteMedia(media.id);
                        },
                        onEdit: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit feature coming soon'),
                            ),
                          );
                        },
                      );
                    }, childCount: mediaList.length),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
            ),
            // Add some bottom padding for the FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadImage,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(l10n.actionUpload),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
    );
  }
}

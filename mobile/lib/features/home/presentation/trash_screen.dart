import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../domain/media.dart';
import 'providers/media_provider.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh trash list when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trashListProvider.notifier).fetchTrash();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trashListAsync = ref.watch(trashListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash Bin'),
      ),
      body: trashListAsync.when(
        data: (mediaList) {
          if (mediaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Trash is empty',
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
              return _TrashItem(media: media);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _TrashItem extends ConsumerWidget {
  final Media media;

  const _TrashItem({required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        _showActionDialog(context, ref);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: media.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
          if (media.mimeType.startsWith('video/'))
            const Center(
              child: Icon(Icons.play_circle_outline,
                  color: Colors.white, size: 32),
            ),
        ],
      ),
    );
  }

  void _showActionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore or Delete?'),
        content: const Text(
            'Do you want to restore this item or delete it permanently?'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(trashListProvider.notifier)
                  .deletePermanently(media.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Permanently'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(trashListProvider.notifier).restoreMedia(media.id);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}

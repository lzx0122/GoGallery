import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/media.dart';

class MediaThumbnail extends ConsumerWidget {
  final Media media;
  final BoxFit fit;

  const MediaThumbnail({
    super.key,
    required this.media,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = ref.watch(authProvider).value;
    final token = user?.token;

    if (media.localFile != null) {
      return Image.file(media.localFile!, fit: fit);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (media.blurHash.isNotEmpty) BlurHash(hash: media.blurHash),
        if (media.url.startsWith('http'))
          CachedNetworkImage(
            key: ValueKey(token),
            imageUrl: media.url,
            fit: fit,
            httpHeaders: token != null
                ? {'Authorization': 'Bearer $token'}
                : null,
            placeholder: (context, url) => media.blurHash.isNotEmpty
                ? const SizedBox.shrink()
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
    );
  }
}

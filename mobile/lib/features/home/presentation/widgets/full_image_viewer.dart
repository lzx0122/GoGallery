import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/media.dart';

class FullImageViewer extends StatelessWidget {
  final Media? media;
  final File? file;

  const FullImageViewer({super.key, this.media, this.file});

  @override
  Widget build(BuildContext context) {
    final hasLocation = media?.latitude != null && media?.longitude != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (hasLocation)
            IconButton(
              icon: const Icon(Icons.map),
              color: Colors.white,
              tooltip: 'Show on Map',
              onPressed: () {
                context.push('/map?id=${media!.id}');
              },
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (file != null) {
      return Image.file(file!, fit: BoxFit.contain);
    }

    if (media != null) {
      if (media!.localFile != null) {
        return Image.file(media!.localFile!, fit: BoxFit.contain);
      }
      return CachedNetworkImage(
        imageUrl: media!.url,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white, size: 48),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

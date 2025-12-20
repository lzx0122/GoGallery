import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/l10n/generated/app_localizations.dart';
import '../../home/presentation/providers/media_provider.dart';
import '../../home/domain/media.dart';

class MapScreen extends ConsumerWidget {
  final String? initialMediaId;

  const MapScreen({super.key, this.initialMediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaListAsync = ref.watch(mediaListProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapTitle)),
      body: mediaListAsync.when(
        data: (mediaList) {
          final mediaWithLocation = mediaList
              .where((m) => m.latitude != null && m.longitude != null)
              .toList();

          if (mediaWithLocation.isEmpty) {
            return Center(child: Text(l10n.mapNoData));
          }

          // Calculate center
          LatLng initialCenter;
          double initialZoom = 13.0;

          if (initialMediaId != null) {
            final targetMedia = mediaWithLocation
                .where((m) => m.id == initialMediaId)
                .firstOrNull;
            if (targetMedia != null) {
              initialCenter = LatLng(
                targetMedia.latitude!,
                targetMedia.longitude!,
              );
              initialZoom = 16.0; // Zoom in closer for specific photo
            } else {
              // Fallback if ID not found
              final firstMedia = mediaWithLocation.first;
              initialCenter = LatLng(
                firstMedia.latitude!,
                firstMedia.longitude!,
              );
            }
          } else {
            final firstMedia = mediaWithLocation.first;
            initialCenter = LatLng(firstMedia.latitude!, firstMedia.longitude!);
          }

          return FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: initialZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.gogallery.mobile',
              ),
              MarkerLayer(
                markers: mediaWithLocation.map((media) {
                  return Marker(
                    point: LatLng(media.latitude!, media.longitude!),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        _showImageDialog(context, media);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: media.url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showImageDialog(BuildContext context, Media media) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: media.url,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

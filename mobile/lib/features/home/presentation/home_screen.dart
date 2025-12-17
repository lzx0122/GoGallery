import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/photo.dart';
import 'providers/grid_settings_provider.dart';
import 'widgets/photo_grid_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _baseScale = 1.0;
  int _baseColumnCount = 3;

  void _handleScaleStart(ScaleStartDetails details) {
    _baseColumnCount = ref.read(gridColumnCountProvider);
    _baseScale = 1.0;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Calculate new column count based on scale
    // Scale > 1 (Zoom in) -> Fewer columns
    // Scale < 1 (Zoom out) -> More columns
    final newScale = details.scale;

    // Use a smoother divisor to make it easier to trigger
    int newCount = (_baseColumnCount / newScale).round();

    // Debug print to check if gesture is detected
    debugPrint('Scale: $newScale, New Count: $newCount');

    // Clamp between 2 and 6 columns
    newCount = newCount.clamp(2, 6);

    if (newCount != ref.read(gridColumnCountProvider)) {
      HapticFeedback.selectionClick();
      ref.read(gridColumnCountProvider.notifier).set(newCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final gridColumnCount = ref.watch(gridColumnCountProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colorScheme.surface.withOpacity(0.95),
              surfaceTintColor: Colors.transparent,
              title: Text(
                'Gallery',
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
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(
                                user.name?.substring(0, 1).toUpperCase() ?? 'U',
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumnCount,
                  mainAxisSpacing: 2.0,
                  crossAxisSpacing: 2.0,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final photo = kMockPhotos[index];
                  return PhotoGridItem(
                    photo: photo,
                    onTap: () {
                      // TODO: Navigate to photo details
                    },
                  );
                }, childCount: kMockPhotos.length),
              ),
            ),
            // Add some bottom padding for the FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement upload functionality
        },
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text('Upload'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
    );
  }
}

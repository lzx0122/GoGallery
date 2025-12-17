class Photo {
  final String id;
  final String url;
  final String title;
  final String? description;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.url,
    required this.title,
    this.description,
    required this.createdAt,
  });
}

final List<Photo> kMockPhotos = [
  Photo(
    id: '1',
    url: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    title: 'Mountain View',
    description: 'A beautiful view of the mountains.',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Photo(
    id: '2',
    url: 'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    title: 'Serene Lake',
    description: 'Calm waters reflecting the sky.',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Photo(
    id: '3',
    url: 'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    title: 'Forest Path',
    description: 'Walking through the woods.',
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  Photo(
    id: '4',
    url: 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    title: 'Misty Morning',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Photo(
    id: '5',
    url: 'https://images.unsplash.com/photo-1501854140884-074bf86ee911?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    title: 'Sunset Beach',
    description: 'Golden hour at the beach.',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];

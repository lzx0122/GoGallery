import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return {};
  }

  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
    }
  }

  void select(String id) {
    if (!state.contains(id)) {
      state = {...state}..add(id);
    }
  }

  void deselect(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    }
  }

  void clear() {
    state = {};
  }

  void selectAll(List<String> ids) {
    state = Set.from(ids);
  }

  bool get isSelecting => state.isNotEmpty;
}

final mediaSelectionProvider =
    NotifierProvider<MediaSelectionNotifier, Set<String>>(
      MediaSelectionNotifier.new,
    );

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the number of columns in the photo grid.
/// Defaults to 3 columns.
class GridColumnCount extends Notifier<int> {
  @override
  int build() => 3;

  void set(int count) {
    state = count;
  }
}

final gridColumnCountProvider = NotifierProvider<GridColumnCount, int>(
  GridColumnCount.new,
);

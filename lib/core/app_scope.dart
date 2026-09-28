import 'package:flutter/widgets.dart';

import '../stores/books_store.dart';
import '../stores/library_store.dart';
import '../stores/reader_settings_store.dart';

/// Exposes the app's stores to the widget tree without extra packages.
/// The stores themselves are [ChangeNotifier]s; listen to them with
/// [ListenableBuilder] where you need rebuilds.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.books,
    required this.library,
    required this.readerSettings,
    required super.child,
  });

  final BooksStore books;
  final LibraryStore library;
  final ReaderSettingsStore readerSettings;

  /// Safe to call from `initState` (no dependency is registered because
  /// the stores never get replaced).
  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

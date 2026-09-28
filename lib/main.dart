import 'package:flutter/material.dart';

import 'core/app_scope.dart';
import 'core/app_theme.dart';
import 'pages/app_shell.dart';
import 'stores/books_store.dart';
import 'stores/library_store.dart';
import 'stores/reader_settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final library = LibraryStore();
  final readerSettings = ReaderSettingsStore();
  final books = BooksStore();

  // Local state is cheap, so wait for it; the network load runs in the background.
  await Future.wait([library.load(), readerSettings.load()]);
  books.bootstrap();

  runApp(
    AppScope(
      books: books,
      library: library,
      readerSettings: readerSettings,
      child: const PageOnApp(),
    ),
  );
}

class PageOnApp extends StatelessWidget {
  const PageOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAGEON Archive',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}

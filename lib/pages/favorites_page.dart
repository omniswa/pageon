import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/book_card.dart';
import 'placeholder_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([scope.books, scope.library]),
        builder: (context, _) {
          final favorites = scope.library.favoritesOf(scope.books.books);
          if (favorites.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'No favorites yet',
              message: 'Tap the heart on any book to save it here.',
            );
          }
          return CustomScrollView(
            slivers: [SliverBookGrid(books: favorites)],
          );
        },
      ),
    );
  }
}

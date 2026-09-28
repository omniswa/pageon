import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../core/app_theme.dart';
import '../widgets/book_card.dart';
import 'placeholder_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([scope.books, scope.library]),
          builder: (context, _) {
            // Most recently favorited first.
            final favorites = scope.library.favoritesOf(scope.books.books);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Favorites', style: AppText.display(34)),
                        const SizedBox(height: 6),
                        Text(
                          favorites.isEmpty
                              ? 'Books you love, saved in one place'
                              : '${favorites.length} saved · newest first',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (favorites.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.favorite_border_rounded,
                      title: 'No favorites yet',
                      message: 'Tap the heart on any book to save it here.',
                    ),
                  )
                else
                  SliverBookGrid(books: favorites),
              ],
            );
          },
        ),
      ),
    );
  }
}

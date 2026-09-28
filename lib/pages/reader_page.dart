import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_scope.dart';
import '../models/book.dart';
import '../models/chapter.dart';
import '../models/reader_settings.dart';
import '../models/reading_progress.dart';
import '../services/book_content_service.dart';
import '../stores/library_store.dart';
import '../stores/reader_settings_store.dart';
import '../widgets/reader_settings_sheet.dart';

void openReader(BuildContext context, Book book) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ReaderPage(book: book)),
  );
}

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.book});
  final Book book;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final BookContentService _content = BookContentService();
  late final LibraryStore _library;
  late final ReaderSettingsStore _settings;
  PageController? _pageController;

  List<Chapter> _chapters = [];
  int _currentIndex = 0;

  /// Scroll fraction to restore in the resumed chapter. Cleared as soon as
  /// the user navigates to another chapter.
  double _restoreScroll = 0;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final scope = AppScope.of(context);
    _library = scope.library;
    _settings = scope.readerSettings;

    final saved = _library.progressFor(widget.book.id);
    _currentIndex = saved?.chapter ?? 0;
    _restoreScroll = saved?.scroll ?? 0;
    _load();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _applyChapters(List<Chapter> chapters) {
    _chapters = chapters;
    _currentIndex = _currentIndex.clamp(0, chapters.length - 1);
    _pageController ??= PageController(initialPage: _currentIndex);
    _loading = false;
    _error = null;
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = _chapters.isEmpty;
      _error = null;
    });

    final cached = await _content.loadCached(widget.book.id);
    if (cached != null && cached.isNotEmpty && mounted && _chapters.isEmpty) {
      setState(() => _applyChapters(cached));
    }

    try {
      final fresh = await _content.fetchAndExtract(
        widget.book,
        force: force || cached == null,
      );
      if (!mounted) return;
      setState(() => _applyChapters(fresh));
    } on ChapterCooldownException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_chapters.isEmpty) _error = e.toString();
      });
      if (_chapters.isNotEmpty) _showSnack(e.toString());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_chapters.isEmpty) _error = 'Could not load this book.';
      });
      if (_chapters.isNotEmpty) {
        _showSnack('Refresh failed — showing what was already loaded.');
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveProgress(int index, double scroll) {
    _library.saveProgress(
      widget.book.id,
      ReadingProgress(
        chapter: index,
        totalChapters: _chapters.length,
        scroll: scroll,
      ),
    );
  }

  void _goTo(int index) {
    if (index < 0 || index >= _chapters.length) return;
    _pageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _openChapterList(ReaderSettings s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: s.theme.surface,
      showDragHandle: true,
      builder: (_) => withReaderTheme(
        context,
        s.theme,
        DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, controller) => ListView.builder(
            controller: controller,
            itemCount: _chapters.length,
            itemBuilder: (context, index) {
              final selected = index == _currentIndex;
              return ListTile(
                title: Text(
                  _chapters[index].title,
                  style: s.font.style(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: s.theme.text,
                  ),
                ),
                trailing: selected
                    ? Icon(Icons.menu_book_rounded,
                        size: 18, color: s.theme.text)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _goTo(index);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final s = _settings.value;
        final t = s.theme;

        return Scaffold(
          backgroundColor: t.background,
          appBar: AppBar(
            backgroundColor: t.background,
            foregroundColor: t.text,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: t.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            title: Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: s.font.style(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            actions: _chapters.isEmpty
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.text_fields_rounded),
                      tooltip: 'Reading settings',
                      onPressed: () =>
                          showReaderSettingsSheet(context, _settings),
                    ),
                    IconButton(
                      icon: const Icon(Icons.list_rounded),
                      tooltip: 'Chapters',
                      onPressed: () => _openChapterList(s),
                    ),
                  ],
          ),
          body: SafeArea(child: _buildBody(s)),
          bottomNavigationBar: _chapters.isEmpty ? null : _buildNavBar(s),
        );
      },
    );
  }

  Widget _buildBody(ReaderSettings s) {
    final color = s.theme.text;

    if (_loading && _chapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Downloading book…', style: TextStyle(color: color)),
          ],
        ),
      );
    }

    if (_error != null && _chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: color.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center, style: TextStyle(color: color)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _load(force: true),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _chapters.length,
      onPageChanged: (index) {
        _restoreScroll = 0;
        setState(() => _currentIndex = index);
        _saveProgress(index, 0);
      },
      itemBuilder: (context, index) => _ChapterView(
        key: ValueKey(_chapters[index].number),
        chapter: _chapters[index],
        settings: s,
        initialScroll: index == _currentIndex ? _restoreScroll : 0,
        onScrollSettled: (fraction) => _saveProgress(index, fraction),
      ),
    );
  }

  Widget _buildNavBar(ReaderSettings s) {
    final t = s.theme;
    final atFirst = _currentIndex == 0;
    final atLast = _currentIndex == _chapters.length - 1;
    final style = TextButton.styleFrom(foregroundColor: t.text);

    return SafeArea(
      top: false,
      child: Container(
        color: t.surface,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(
          children: [
            TextButton.icon(
              style: style,
              onPressed: atFirst ? null : () => _goTo(_currentIndex - 1),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Previous'),
            ),
            const Spacer(),
            Text(
              '${_currentIndex + 1} / ${_chapters.length}',
              style:
                  TextStyle(color: t.text.withValues(alpha: 0.6), fontSize: 12),
            ),
            const Spacer(),
            TextButton(
              style: style,
              onPressed: atLast ? null : () => _goTo(_currentIndex + 1),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('Next'), Icon(Icons.chevron_right_rounded)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single scrollable chapter. Restores its saved scroll position once
/// laid out and reports where the user stopped scrolling.
class _ChapterView extends StatefulWidget {
  const _ChapterView({
    super.key,
    required this.chapter,
    required this.settings,
    required this.initialScroll,
    required this.onScrollSettled,
  });

  final Chapter chapter;
  final ReaderSettings settings;
  final double initialScroll;
  final ValueChanged<double> onScrollSettled;

  @override
  State<_ChapterView> createState() => _ChapterViewState();
}

class _ChapterViewState extends State<_ChapterView> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialScroll > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final max = _controller.position.maxScrollExtent;
        _controller.jumpTo((widget.initialScroll * max).clamp(0.0, max));
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollEndNotification && n.depth == 0) {
      final max = n.metrics.maxScrollExtent;
      widget.onScrollSettled(
          max > 0 ? (n.metrics.pixels / max).clamp(0.0, 1.0) : 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: SingleChildScrollView(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chapter.title,
              style: s.font.style(
                fontSize: s.fontSize + 6,
                fontWeight: FontWeight.w700,
                color: s.theme.text,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.chapter.content,
              textAlign: s.align.textAlign,
              style: s.font.style(
                fontSize: s.fontSize,
                color: s.theme.text,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

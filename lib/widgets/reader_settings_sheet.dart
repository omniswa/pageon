import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/reader_settings.dart';
import '../stores/reader_settings_store.dart';

/// Wraps [child] in a Material theme matching the reader theme, so modal
/// sheets opened from the reader look consistent (including dark mode).
Widget withReaderTheme(BuildContext context, ReaderTheme t, Widget child) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: t.brightness,
    surface: t.surface,
  ).copyWith(onSurface: t.text);
  return Theme(
    data: Theme.of(context).copyWith(colorScheme: scheme),
    child: child,
  );
}

Future<void> showReaderSettingsSheet(
  BuildContext context,
  ReaderSettingsStore store,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: store.value.theme.surface,
    showDragHandle: true,
    builder: (_) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => withReaderTheme(
        context,
        store.value.theme,
        _SettingsBody(store: store),
      ),
    ),
  );
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({required this.store});
  final ReaderSettingsStore store;

  @override
  Widget build(BuildContext context) {
    final s = store.value;
    final color = s.theme.text;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Theme', color),
            Row(
              children: [
                for (final t in ReaderTheme.values)
                  Expanded(
                    child: _ThemeSwatch(
                      theme: t,
                      selected: t == s.theme,
                      onTap: () => store.update((v) => v.copyWith(theme: t)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _Label('Font', color),
            Wrap(
              spacing: 8,
              children: [
                for (final f in ReaderFont.values)
                  ChoiceChip(
                    label: Text(f.label, style: f.style(fontSize: 14)),
                    selected: f == s.font,
                    onSelected: (_) => store.update((v) => v.copyWith(font: f)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _Label('Alignment', color),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ReaderAlign>(
                showSelectedIcon: false,
                segments: [
                  for (final a in ReaderAlign.values)
                    ButtonSegment(
                      value: a,
                      icon: Icon(a.icon, size: 18),
                      label: Text(a.label),
                    ),
                ],
                selected: {s.align},
                onSelectionChanged: (v) =>
                    store.update((x) => x.copyWith(align: v.first)),
              ),
            ),
            const SizedBox(height: 20),
            _Label('Text size', color),
            Row(
              children: [
                Text('A', style: TextStyle(fontSize: 13, color: color)),
                Expanded(
                  child: Slider(
                    value: s.fontSize,
                    min: ReaderSettings.minFontSize,
                    max: ReaderSettings.maxFontSize,
                    divisions:
                        (ReaderSettings.maxFontSize - ReaderSettings.minFontSize)
                            .round(),
                    label: s.fontSize.round().toString(),
                    onChanged: (v) =>
                        store.update((x) => x.copyWith(fontSize: v)),
                  ),
                ),
                Text('A', style: TextStyle(fontSize: 24, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.6),
            )),
      );
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 64,
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : Colors.grey.withValues(alpha: 0.35),
              width: selected ? 2.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aa',
                  style: TextStyle(
                      color: theme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              Text(theme.label,
                  style: TextStyle(color: theme.text, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ReaderTheme {
  paper('Paper', Color(0xFFFBF9F4), Color(0xFF2B2620), Color(0xFFFFFFFF),
      Brightness.light),
  sepia('Sepia', Color(0xFFF3E7D0), Color(0xFF4A3A26), Color(0xFFEBDDBF),
      Brightness.light),
  dark('Dark', Color(0xFF16181C), Color(0xFFD5D3CE), Color(0xFF22252B),
      Brightness.dark);

  const ReaderTheme(
    this.label,
    this.background,
    this.text,
    this.surface,
    this.brightness,
  );

  final String label;
  final Color background;
  final Color text;

  /// Used for bars and sheets that sit on top of the page.
  final Color surface;
  final Brightness brightness;
}

enum ReaderFont {
  serif('Serif'),
  sans('Sans'),
  mono('Mono');

  const ReaderFont(this.label);
  final String label;

  TextStyle style({
    double? fontSize,
    Color? color,
    double? height,
    FontWeight? fontWeight,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      color: color,
      height: height,
      fontWeight: fontWeight,
    );
    return switch (this) {
      ReaderFont.serif => GoogleFonts.literata(textStyle: base),
      ReaderFont.sans => GoogleFonts.inter(textStyle: base),
      ReaderFont.mono => GoogleFonts.jetBrainsMono(textStyle: base),
    };
  }
}

enum ReaderAlign {
  left('Left', TextAlign.left, Icons.format_align_left_rounded),
  justify('Justify', TextAlign.justify, Icons.format_align_justify_rounded);

  const ReaderAlign(this.label, this.textAlign, this.icon);
  final String label;
  final TextAlign textAlign;
  final IconData icon;
}

class ReaderSettings {
  static const double minFontSize = 13;
  static const double maxFontSize = 26;

  final ReaderTheme theme;
  final ReaderFont font;
  final ReaderAlign align;
  final double fontSize;

  const ReaderSettings({
    this.theme = ReaderTheme.paper,
    this.font = ReaderFont.serif,
    this.align = ReaderAlign.left,
    this.fontSize = 17,
  });

  ReaderSettings copyWith({
    ReaderTheme? theme,
    ReaderFont? font,
    ReaderAlign? align,
    double? fontSize,
  }) =>
      ReaderSettings(
        theme: theme ?? this.theme,
        font: font ?? this.font,
        align: align ?? this.align,
        fontSize: fontSize ?? this.fontSize,
      );

  factory ReaderSettings.fromJson(Map<String, dynamic> json) {
    const d = ReaderSettings();
    return ReaderSettings(
      theme: ReaderTheme.values.asNameMap()[json['theme']] ?? d.theme,
      font: ReaderFont.values.asNameMap()[json['font']] ?? d.font,
      align: ReaderAlign.values.asNameMap()[json['align']] ?? d.align,
      fontSize: ((json['fontSize'] as num?)?.toDouble() ?? d.fontSize)
          .clamp(minFontSize, maxFontSize),
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme.name,
        'font': font.name,
        'align': align.name,
        'fontSize': fontSize,
      };
}

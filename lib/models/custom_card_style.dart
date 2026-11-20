class CardCustomization {
  final double scale;
  final String aspectRatio;
  final bool isLandscape;
  final double bottomHeight;
  final int titleLines;

  const CardCustomization({
    this.scale = 1.0,
    this.aspectRatio = '2:3',
    this.isLandscape = false,
    this.bottomHeight = 66.0,
    this.titleLines = 1,
  });

  CardCustomization copyWith({
    double? scale,
    String? aspectRatio,
    bool? isLandscape,
    double? bottomHeight,
    int? titleLines,
  }) {
    return CardCustomization(
      scale: scale ?? this.scale,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      isLandscape: isLandscape ?? this.isLandscape,
      bottomHeight: bottomHeight ?? this.bottomHeight,
      titleLines: titleLines ?? this.titleLines,
    );
  }

  double get ratioValue {
    if (isLandscape) return 16.0 / 9.0;
    return switch (aspectRatio) {
      '3:4' => 3.0 / 4.0,
      '1:1' => 1.0,
      '9:16' => 9.0 / 16.0,
      _ => 2.0 / 3.0,
    };
  }

  double cardWidth(bool isDesktop, [int styleIndex = 0]) {
    if (isLandscape) {
      final baseWidth = isDesktop ? 230.0 : 185.0;
      return baseWidth * scale;
    }
    final baseWidth = switch (styleIndex) {
      0 => (isDesktop ? 175.0 : 140.0),
      2 => (isDesktop ? 165.0 : 125.0),
      _ => (isDesktop ? 155.0 : 120.0),
    };
    return baseWidth * scale;
  }

  double posterHeight(int styleIndex, bool isDesktop) {
    final w = cardWidth(isDesktop, styleIndex);
    if (isLandscape) {
      return w / (16.0 / 9.0);
    }
    if (styleIndex == 0) {
      if (aspectRatio == '2:3') {
        final basePosterH = isDesktop ? 215.0 : 162.0;
        return basePosterH * scale;
      }
      return w / ratioValue;
    }
    return w / ratioValue;
  }

  double getBottomHeight(int styleIndex, bool isDesktop) {
    final lineHeight = isDesktop ? 20.0 : 18.0;
    return switch (styleIndex) {
      0 => (isDesktop ? 48.0 : 46.0) + (titleLines * lineHeight),
      1 => (isDesktop ? 12.0 : 10.0) + (titleLines * lineHeight),
      2 => 8.0 + (titleLines * (isDesktop ? 22.0 : 20.0)) + 8.0 + 26.0 + 6.0,
      3 => 38.0,
      4 => 0.0,
      _ => (isDesktop ? 48.0 : 46.0) + (titleLines * lineHeight),
    };
  }

  double getExtraHeight(int styleIndex, bool isDesktop) {
    return getBottomHeight(styleIndex, isDesktop);
  }

  double getCardHeight(int styleIndex, bool isDesktop) {
    final posterH = posterHeight(styleIndex, isDesktop);
    final extra = getExtraHeight(styleIndex, isDesktop);
    final shadowMargin = styleIndex == 2 ? 8.0 : 0.0;
    return posterH + extra + shadowMargin;
  }

  double getCardAspectRatio(int styleIndex, bool isDesktop) {
    final w = cardWidth(isDesktop, styleIndex);
    final h = getCardHeight(styleIndex, isDesktop);
    return h > 0 ? (w / h) : 0.65;
  }

  double totalHeight(bool isDesktop) {
    return getCardHeight(0, isDesktop);
  }

  Map<String, dynamic> toJson() => {
        'scale': scale,
        'aspectRatio': aspectRatio,
        'isLandscape': isLandscape,
        'bottomHeight': bottomHeight,
        'titleLines': titleLines,
      };

  factory CardCustomization.fromJson(Map<String, dynamic> json) {
    final scaleVal = (json['scale'] as num?)?.toDouble() ??
        (json['customScale'] as num?)?.toDouble() ??
        1.0;
    final ratioStr = json['aspectRatio'] as String? ?? '2:3';
    final isLandscape = json['isLandscape'] as bool? ?? false;
    final bottomH = (json['bottomHeight'] as num?)?.toDouble() ??
        (json['containerHeight'] as num?)?.toDouble() ??
        66.0;
    final lines = (json['titleLines'] as num?)?.toInt() ?? 1;

    return CardCustomization(
      scale: scaleVal.clamp(0.70, 1.40),
      aspectRatio: ratioStr,
      isLandscape: isLandscape,
      bottomHeight: bottomH.clamp(45.0, 95.0),
      titleLines: lines.clamp(1, 3),
    );
  }

  static const defaultStyle = CardCustomization();
  static const defaultCustomization = CardCustomization();
  static const exoticStyle = CardCustomization();
  static const minimalExoticStyle = CardCustomization();
  static const saikouStyle = CardCustomization();
  static const modernStyle = CardCustomization();
}

typedef CustomCardStyle = CardCustomization;

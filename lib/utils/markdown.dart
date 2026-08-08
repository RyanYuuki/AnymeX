import 'package:markdown/markdown.dart';

String parseMarkdown(String markdown) {
  // raw text then wrapped in a para tag
  final nodes = [Element('p', document.parse(markdown))];
  return renderToHtml(nodes);
}

final document = Document(
  blockSyntaxes: const [
    _HeaderSyntax(),
    _SpoilerBlockSyntax(),
    _CenterBlockSyntax(),
    _FencedCodeBlockSyntax(),
    HorizontalRuleSyntax(),
    BlockquoteSyntax(),
    UnorderedListSyntax(),
    OrderedListSyntax(),
  ],
  inlineSyntaxes: [
    EmphasisSyntax.asterisk(),
    EmphasisSyntax.underscore(),
    StrikethroughSyntax(),
    CodeSyntax(),
    LinkSyntax(),
    AutolinkExtensionSyntax(),
    ImageSyntax(),
    _ImageSyntax(),
    _YouTubeSyntax(),
    _VideoSyntax(),
    _MentionSyntax(),
    _LineBreakSyntax(),
  ],
  encodeHtml: false,
  withDefaultBlockSyntaxes: false,
  withDefaultInlineSyntaxes: false,
  extensionSet: null,
  linkResolver: null,
  imageLinkResolver: null,
);


class _HeaderSyntax extends HeaderSyntax {
  const _HeaderSyntax();

  static final _pattern = RegExp(r'^ {0,3}(#{1,6})(?:.*?)?(?:(#*)\s*)?$');

  @override
  RegExp get pattern => _pattern;

  @override
  Node parse(BlockParser parser) {
    final node = super.parse(parser) as Element;

   
    final children = node.children;
    if (children != null && children.isNotEmpty) {
      final parsedContent = BlockParser([
        Line(children[0].textContent),
      ], parser.document)
          .parseLines();

      children.clear();
      children.addAll(parsedContent);
    }

    return node;
  }
}

abstract class _DelimitedBlockSyntax extends BlockSyntax {
  const _DelimitedBlockSyntax({
    required this.tag,
    required this.startDelimiter,
    required this.endDelimiter,
  });

  final String tag;
  final String startDelimiter;
  final String endDelimiter;

  void finalizeElement(Element element);

  @override
  Node parse(BlockParser parser) {
    final lines = parseChildLines(parser);
    if (lines.length < 3) return Element.withTag(tag);

    final prefix = lines.first.content.isNotEmpty
        ? BlockParser([lines.first], parser.document).parseLines()
        : const [];
    final postfix = lines.last.content.isNotEmpty
        ? BlockParser([lines.last], parser.document).parseLines()
        : const [];
    final children =
        BlockParser(lines.sublist(1, lines.length - 1), parser.document)
            .parseLines();

    final element = Element(tag, children);
    finalizeElement(element);
    return prefix.isEmpty && postfix.isEmpty
        ? element
        : Element('p', [...prefix, element, ...postfix]);
  }

  @override
  List<Line> parseChildLines(BlockParser parser) {
    final childLines = <Line>[];
    final text = parser.current.content;

    int startIndex = text.indexOf(startDelimiter);
    childLines.add(Line(text.substring(0, startIndex)));

    startIndex += startDelimiter.length;
    if (startIndex < text.length) {
      final lineEnd = Line(text.substring(startIndex));
      if (_close(parser, childLines, lineEnd)) return childLines;
    } else {
      parser.advance();
    }

    while (!parser.isDone) {
      if (_close(parser, childLines, parser.current)) return childLines;
    }

    return childLines;
  }

  bool _close(BlockParser parser, List<Line> childLines, Line line) {
    final text = line.content;
    int endIndex = text.indexOf(endDelimiter);

    if (endIndex < 0) {
      childLines.add(line);
      parser.advance();
      return false;
    }

    childLines.add(Line(text.substring(0, endIndex)));
    childLines.add(Line(text.substring(endIndex + endDelimiter.length)));

    parser.advance();
    return true;
  }
}

class _SpoilerBlockSyntax extends _DelimitedBlockSyntax {
  const _SpoilerBlockSyntax()
      : super(
            tag: 'details',
            startDelimiter: _startDelimiter,
            endDelimiter: '!~');

  static const _startDelimiter = '~!';
  static final _pattern = RegExp(_startDelimiter);

  @override
  RegExp get pattern => _pattern;

  @override
  void finalizeElement(Element element) {
    element.children?.insert(0, Element.text('summary', 'Spoiler'));
  }
}

class _CenterBlockSyntax extends _DelimitedBlockSyntax {
  const _CenterBlockSyntax()
      : super(
            tag: 'center',
            startDelimiter: _delimiter,
            endDelimiter: _delimiter);

  static const _delimiter = '~~~';
  static final _pattern = RegExp(_delimiter);

  @override
  RegExp get pattern => _pattern;

  @override
  void finalizeElement(Element element) {}
}


class _FencedCodeBlockSyntax extends FencedCodeBlockSyntax {
  const _FencedCodeBlockSyntax();

  static final _pattern =
      RegExp(r'^([ ]{0,3})(?<backtick>`{3,})(?<backtickInfo>[^`]*)$');

  @override
  RegExp get pattern => _pattern;
}

class _LineBreakSyntax extends InlineSyntax {
  _LineBreakSyntax() : super(r'\n', startCharacter: 10);

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Element.empty('br'));
    return true;
  }
}


class _ImageSyntax extends InlineSyntax {
  _ImageSyntax()
      : super(r'img((?:\d+%?)?)\(((?:https:\/\/)[^)]+)\)',
            caseSensitive: false);

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(
      Element.empty('img')
        ..attributes['width'] = match.group(1)!
        ..attributes['src'] = match.group(2)!,
    );
    return true;
  }
}

/// YouTube 
class _YouTubeSyntax extends InlineSyntax {
  _YouTubeSyntax()
      : super(
          r'youtube\s?\(\s*(?:(?:https:\/\/)?(?:www\.)?(?:(?:(?:music\.)?youtube\.com\/watch\?v=)|(?:youtu\.be\/)))?([^?&#)]+)(?:[^)]*)\)',
          caseSensitive: false,
        );

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Element.text('youtube', match.group(1)!));
    return true;
  }
}

class _VideoSyntax extends InlineSyntax {
  _VideoSyntax() : super(r'webm\(([^)]+)\)', caseSensitive: false);

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(
      Element('video',
          [Element.empty('source')..attributes['src'] = match.group(1)!]),
    );
    return true;
  }
}

class _MentionSyntax extends InlineSyntax {
  _MentionSyntax() : super(r'\B@([A-Za-z0-9]+)', startCharacter: 64);

  @override
  bool onMatch(InlineParser parser, Match match) {
    final name = match.group(1)!;
    parser.addNode(
      Element.text('a', '@$name')
        ..attributes['href'] = 'https://anilist.co/user/$name',
    );
    return true;
  }
}

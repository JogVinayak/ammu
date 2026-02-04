import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Word-by-word guided reading - matches React implementation
/// When enabled: renders content with word highlighting (past=visible, active=highlighted, future=faded)
/// When disabled: shows original child widget unchanged
///
/// Accepts either:
/// - [guidedJson]: Pre-processed JSON from server (preferred for performance)
/// - [textContent]: Raw markdown to parse on client (fallback)
class GuidedReadingOverlay extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  final String textContent;
  final String? guidedJson;
  final String? title;
  final bool isEnabled;
  final double initialSpeed;
  final Color highlightColor;
  final VoidCallback? onComplete;
  final VoidCallback? onDisable;

  const GuidedReadingOverlay({
    super.key,
    required this.child,
    required this.scrollController,
    required this.textContent,
    this.guidedJson,
    this.title,
    this.isEnabled = false,
    this.initialSpeed = 0.5,
    this.highlightColor = const Color(0xFF14B8A6),
    this.onComplete,
    this.onDisable,
  });

  @override
  State<GuidedReadingOverlay> createState() => _GuidedReadingOverlayState();
}

class _GuidedReadingOverlayState extends State<GuidedReadingOverlay> {
  late List<_WordInfo> _words;
  late List<_Paragraph> _paragraphs;
  int _activeIndex = 0;
  double _speed = 0.5;
  bool _isPlaying = false;
  Timer? _timer;

  // Speed: 0.0 = 100 WPM, 1.0 = 350 WPM
  int get _baseWpm => (100 + (_speed * 250)).toInt();

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;
    _parseContent();
  }

  void _parseContent() {
    _words = [];
    _paragraphs = [];

    // Try to use pre-processed JSON from server (more efficient)
    if (widget.guidedJson != null && widget.guidedJson!.isNotEmpty) {
      try {
        final json = jsonDecode(widget.guidedJson!) as Map<String, dynamic>;
        final paragraphsList = json['paragraphs'] as List<dynamic>? ?? [];

        for (int pIdx = 0; pIdx < paragraphsList.length; pIdx++) {
          final p = paragraphsList[pIdx] as Map<String, dynamic>;
          final words = (p['words'] as List<dynamic>? ?? []).cast<String>();
          final startIndex = p['startWordIndex'] as int? ?? 0;
          final endIndex = p['endWordIndex'] as int? ?? words.length;
          final isHeading = p['isHeading'] as bool? ?? p['heading'] as bool? ?? false;
          final isList = p['isList'] as bool? ?? p['list'] as bool? ?? false;

          for (int i = 0; i < words.length; i++) {
            _words.add(_WordInfo(
              word: words[i],
              paragraphIndex: pIdx,
              globalIndex: startIndex + i,
            ));
          }

          _paragraphs.add(_Paragraph(
            text: p['text'] as String? ?? '',
            isHeading: isHeading,
            isList: isList,
            startWordIndex: startIndex,
            endWordIndex: endIndex,
          ));
        }
        return;
      } catch (e) {
        // Fall through to markdown parsing if JSON parsing fails
        debugPrint('Failed to parse guided JSON: $e');
      }
    }

    // Fallback: Parse markdown on client
    final paragraphTexts = widget.textContent
        .split(RegExp(r'\n\s*\n|\n(?=[#\-\*\d])'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    int globalIndex = 0;
    for (int pIdx = 0; pIdx < paragraphTexts.length; pIdx++) {
      final text = paragraphTexts[pIdx].trim();
      final isHeading = text.startsWith('#');
      final isList = text.startsWith('-') || text.startsWith('*') || text.startsWith('+') ||
          RegExp(r'^\d+\.').hasMatch(text);

      // Clean markdown formatting
      var cleanText = text;
      cleanText = cleanText.replaceAll(RegExp(r'^#{1,6}\s*'), ''); // Remove headings
      cleanText = cleanText.replaceAll(RegExp(r'^[-*+]\s*'), ''); // Remove list markers
      cleanText = cleanText.replaceAll(RegExp(r'^\d+\.\s*'), ''); // Remove numbered list

      final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final startIndex = globalIndex;

      for (final word in words) {
        final cleanWord = _stripMarkdownFromWord(word);
        if (cleanWord.isNotEmpty) {
          _words.add(_WordInfo(word: cleanWord, paragraphIndex: pIdx, globalIndex: globalIndex));
          globalIndex++;
        }
      }

      _paragraphs.add(_Paragraph(
        text: cleanText,
        isHeading: isHeading,
        isList: isList,
        startWordIndex: startIndex,
        endWordIndex: globalIndex,
      ));
    }
  }

  /// Strip inline markdown from a word
  String _stripMarkdownFromWord(String word) {
    var result = word;
    // Bold **text** or __text__
    result = result.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1) ?? '');
    // Italic *text* or _text_
    result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1) ?? '');
    // Inline code `text`
    result = result.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1) ?? '');
    // Links [text](url)
    result = result.replaceAllMapped(RegExp(r'\[(.+?)\]\(.+?\)'), (m) => m.group(1) ?? '');
    // Remove remaining asterisks/underscores at boundaries
    result = result.replaceAll(RegExp(r'^[*_]+|[*_]+$'), '');
    return result.trim();
  }

  @override
  void didUpdateWidget(GuidedReadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textContent != widget.textContent ||
        oldWidget.guidedJson != widget.guidedJson) {
      _parseContent();
      _reset();
    }
    if (oldWidget.isEnabled != widget.isEnabled && !widget.isEnabled) {
      _pauseReading();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Adaptive delay based on word characteristics (like React version)
  int _getWordDelay(String word) {
    final baseDelay = (60000 / _baseWpm).toInt();
    final clean = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    // Fast: short/common words
    const commonWords = ['a', 'the', 'is', 'in', 'to', 'of', 'and', 'as', 'it', 'for', 'on', 'with', 'be', 'at', 'by'];
    if (commonWords.contains(clean) || clean.length <= 2) {
      return (baseDelay * 0.6).toInt();
    }

    // Slow: long/complex words
    if (clean.length >= 10) {
      return (baseDelay * 1.6).toInt();
    }

    // Pause: end of sentence
    if (word.contains('.') || word.contains('!') || word.contains('?')) {
      return (baseDelay * 2.2).toInt();
    }

    // Small pause: comma, semicolon
    if (word.contains(',') || word.contains(';') || word.contains(':')) {
      return (baseDelay * 1.3).toInt();
    }

    return baseDelay;
  }

  void _startReading() {
    if (_words.isEmpty) return;
    setState(() => _isPlaying = true);
    _scheduleNextWord();
  }

  void _pauseReading() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    _isPlaying ? _pauseReading() : _startReading();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _activeIndex = 0;
      _isPlaying = false;
    });
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _scheduleNextWord() {
    if (!_isPlaying || _activeIndex >= _words.length) return;

    final delay = _getWordDelay(_words[_activeIndex].word);
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || !_isPlaying) return;

      setState(() {
        _activeIndex++;
        if (_activeIndex >= _words.length) {
          _isPlaying = false;
          widget.onComplete?.call();
        }
      });

      _scheduleNextWord();
    });
  }

  void _onProgressTap(double progress) {
    setState(() {
      _activeIndex = (progress * _words.length).toInt().clamp(0, _words.length - 1);
    });
  }

  void _onWordTap(int index) {
    setState(() {
      _activeIndex = index;
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // When disabled, show original content
    if (!widget.isEnabled) {
      return widget.child;
    }

    // When enabled, show word-by-word reading view
    return Column(
      children: [
        _buildControlBar(context),
        Expanded(
          child: _buildReadingContent(context),
        ),
        _buildProgressBar(context),
      ],
    );
  }

  Widget _buildReadingContent(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title if provided
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Render paragraphs with word-by-word highlighting
          for (int pIdx = 0; pIdx < _paragraphs.length; pIdx++) ...[
            _buildParagraph(context, _paragraphs[pIdx]),
            if (pIdx < _paragraphs.length - 1)
              SizedBox(
                height: _paragraphs[pIdx].isHeading
                    ? AppSpacing.md
                    : _paragraphs[pIdx].isList
                        ? AppSpacing.sm
                        : AppSpacing.md,
              ),
          ],

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, _Paragraph paragraph) {
    final paragraphWords = _words
        .where((w) => w.globalIndex >= paragraph.startWordIndex && w.globalIndex < paragraph.endWordIndex)
        .toList();

    // Build the words wrap
    final wordsWidget = Wrap(
      spacing: 6,
      runSpacing: 12,
      children: paragraphWords.map((wordInfo) {
        final isActive = wordInfo.globalIndex == _activeIndex;
        final isPast = wordInfo.globalIndex < _activeIndex;

        // Size based on paragraph type
        final fontSize = paragraph.isHeading ? 24.0 : 18.0;
        final fontWeight = paragraph.isHeading ? FontWeight.w700 : FontWeight.w400;

        // Colors: active=highlighted bg, past=dark text, future=very faded
        final textColor = isActive
            ? Colors.white
            : isPast
                ? AppColors.textPrimary
                : AppColors.textSecondary.withAlpha(60);

        return GestureDetector(
          onTap: () => _onWordTap(wordInfo.globalIndex),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: isActive ? widget.highlightColor : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              wordInfo.word,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        );
      }).toList(),
    );

    // For list items, add a bullet point
    if (paragraph.isList) {
      return Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 12),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withAlpha(150),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(child: wordsWidget),
          ],
        ),
      );
    }

    return wordsWidget;
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = _words.isEmpty ? 0.0 : _activeIndex / _words.length;

    return Container(
      height: 3,
      color: AppColors.background,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(color: widget.highlightColor),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    final progress = _words.isEmpty ? 0.0 : _activeIndex / _words.length;
    final wordsRead = _activeIndex;
    final totalWords = _words.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scrubber
          GestureDetector(
            onTapDown: (d) {
              final box = context.findRenderObject() as RenderBox;
              _onProgressTap((box.globalToLocal(d.globalPosition).dx / box.size.width).clamp(0.0, 1.0));
            },
            onHorizontalDragUpdate: (d) {
              final box = context.findRenderObject() as RenderBox;
              _onProgressTap((box.globalToLocal(d.globalPosition).dx / box.size.width).clamp(0.0, 1.0));
            },
            child: Container(
              height: 24,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(2)),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(color: widget.highlightColor, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 32) * progress - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: widget.highlightColor,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: widget.highlightColor.withAlpha(80), blurRadius: 4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Controls
          Row(
            children: [
              _ControlButton(icon: Icons.replay_rounded, onPressed: _reset, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              _ControlButton(
                icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onPressed: _togglePlayPause,
                color: Colors.white,
                backgroundColor: widget.highlightColor,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.speed_rounded, size: 18, color: AppColors.textSecondary),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: widget.highlightColor.withAlpha(180),
                    inactiveTrackColor: AppColors.background,
                    thumbColor: widget.highlightColor,
                    overlayColor: widget.highlightColor.withAlpha(40),
                  ),
                  child: Slider(value: _speed, onChanged: (v) => setState(() => _speed = v), min: 0.0, max: 1.0),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  '$_baseWpm wpm',
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ControlButton(icon: Icons.close_rounded, onPressed: widget.onDisable, color: AppColors.textSecondary),
            ],
          ),
          // Word count
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$wordsRead / $totalWords words',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary.withAlpha(150),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color? backgroundColor;
  final double size;

  const _ControlButton({
    required this.icon,
    this.onPressed,
    required this.color,
    this.backgroundColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.all(backgroundColor != null ? 8 : 6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

/// Represents a word with its position info
class _WordInfo {
  final String word;
  final int paragraphIndex;
  final int globalIndex;

  _WordInfo({
    required this.word,
    required this.paragraphIndex,
    required this.globalIndex,
  });
}

/// Represents a paragraph/block of text
class _Paragraph {
  final String text;
  final bool isHeading;
  final bool isList;
  final int startWordIndex;
  final int endWordIndex;

  _Paragraph({
    required this.text,
    required this.isHeading,
    this.isList = false,
    required this.startWordIndex,
    required this.endWordIndex,
  });
}

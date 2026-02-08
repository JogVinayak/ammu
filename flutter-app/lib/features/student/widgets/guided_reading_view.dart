import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Word-by-word guided reading with smooth torch-like spotlight effect
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

class _GuidedReadingOverlayState extends State<GuidedReadingOverlay>
    with SingleTickerProviderStateMixin {
  late List<_Word> _words;
  late List<_Paragraph> _paragraphs;

  // Use double for smooth interpolation between word indices
  double _position = 0.0; // Current "spotlight" position (can be fractional)
  int _targetIndex = 0;   // Target word index
  double _speed = 0.5;
  bool _isPlaying = false;
  Timer? _timer;

  // Animation for smooth position interpolation
  late AnimationController _animController;

  // Speed range: 50 WPM (slow) to 500 WPM (fast)
  int get _baseWpm => (50 + (_speed * 450)).toInt();
  int get _wordCount => _words.length;
  int get _wordsRead => _position.floor();

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;

    _animController = AnimationController(
      vsync: this,
    );
    _animController.addListener(_onAnimationTick);

    _parseContent();
  }

  void _onAnimationTick() {
    setState(() {
      // Smoothly interpolate position towards target
      _position = _animController.value * _targetIndex;
    });
  }

  void _parseContent() {
    _words = [];
    _paragraphs = [];

    if (widget.guidedJson != null && widget.guidedJson!.isNotEmpty) {
      try {
        final json = jsonDecode(widget.guidedJson!) as Map<String, dynamic>;
        final paragraphsList = json['paragraphs'] as List<dynamic>? ?? [];

        int globalIndex = 0;
        for (int pIdx = 0; pIdx < paragraphsList.length; pIdx++) {
          final p = paragraphsList[pIdx] as Map<String, dynamic>;
          final words = (p['words'] as List<dynamic>? ?? []).cast<String>();
          final isHeading = p['isHeading'] as bool? ?? p['heading'] as bool? ?? false;
          final headingLevel = p['headingLevel'] as int? ?? (isHeading ? 1 : 0);
          final isList = p['isList'] as bool? ?? p['list'] as bool? ?? false;
          final isCodeBlock = p['isCodeBlock'] as bool? ?? false;
          final isBlockquote = p['isBlockquote'] as bool? ?? false;

          final startIndex = globalIndex;

          for (int i = 0; i < words.length; i++) {
            _words.add(_Word(
              text: words[i],
              paragraphIndex: pIdx,
              globalIndex: globalIndex,
              isLastInParagraph: i == words.length - 1,
            ));
            globalIndex++;
          }

          _paragraphs.add(_Paragraph(
            text: p['text'] as String? ?? '',
            isHeading: isHeading,
            headingLevel: headingLevel,
            isList: isList,
            isCodeBlock: isCodeBlock,
            isBlockquote: isBlockquote,
            startWordIndex: startIndex,
            endWordIndex: globalIndex,
          ));
        }
        return;
      } catch (e) {
        debugPrint('Failed to parse guided JSON: $e');
      }
    }

    // Fallback: Parse markdown
    final lines = widget.textContent.split('\n');
    int globalIndex = 0;
    int pIdx = 0;

    bool inCodeBlock = false;
    List<String> codeBlockLines = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().startsWith('```')) {
        if (inCodeBlock) {
          // End of code block - store as raw code, no word-by-word highlighting
          final rawCode = codeBlockLines.join('\n');
          if (rawCode.trim().isNotEmpty) {
            _paragraphs.add(_Paragraph(
              text: '',
              rawCode: rawCode,
              isHeading: false, headingLevel: 0, isList: false,
              isCodeBlock: true, isBlockquote: false,
              startWordIndex: globalIndex, endWordIndex: globalIndex,
            ));
            pIdx++;
          }
          inCodeBlock = false;
          codeBlockLines.clear();
        } else {
          inCodeBlock = true;
        }
        continue;
      }

      if (inCodeBlock) {
        codeBlockLines.add(line);
        continue;
      }

      if (line.trim().isEmpty) continue;

      final trimmedLine = line.trim();

      int headingLevel = 0;
      bool isHeading = false;
      if (trimmedLine.startsWith('######')) { headingLevel = 6; isHeading = true; }
      else if (trimmedLine.startsWith('#####')) { headingLevel = 5; isHeading = true; }
      else if (trimmedLine.startsWith('####')) { headingLevel = 4; isHeading = true; }
      else if (trimmedLine.startsWith('###')) { headingLevel = 3; isHeading = true; }
      else if (trimmedLine.startsWith('##')) { headingLevel = 2; isHeading = true; }
      else if (trimmedLine.startsWith('#')) { headingLevel = 1; isHeading = true; }

      final isList = trimmedLine.startsWith('-') || trimmedLine.startsWith('*') ||
                     trimmedLine.startsWith('+') || RegExp(r'^\d+\.').hasMatch(trimmedLine);
      final isBlockquote = trimmedLine.startsWith('>');

      var cleanText = trimmedLine;
      cleanText = cleanText.replaceAll(RegExp(r'^#{1,6}\s*'), '');
      cleanText = cleanText.replaceAll(RegExp(r'^[-*+]\s*'), '');
      cleanText = cleanText.replaceAll(RegExp(r'^\d+\.\s*'), '');
      cleanText = cleanText.replaceAll(RegExp(r'^>\s*'), '');

      final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.isEmpty) continue;

      final startIndex = globalIndex;

      for (int j = 0; j < words.length; j++) {
        final cleanWord = _stripMarkdownFromWord(words[j]);
        if (cleanWord.isNotEmpty) {
          _words.add(_Word(text: cleanWord, paragraphIndex: pIdx, globalIndex: globalIndex, isLastInParagraph: j == words.length - 1));
          globalIndex++;
        }
      }

      _paragraphs.add(_Paragraph(
        text: cleanText, isHeading: isHeading, headingLevel: headingLevel,
        isList: isList, isCodeBlock: false, isBlockquote: isBlockquote,
        startWordIndex: startIndex, endWordIndex: globalIndex,
      ));
      pIdx++;
    }
  }

  String _stripMarkdownFromWord(String word) {
    var result = word;
    result = result.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'_(.+?)_'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1) ?? '');
    result = result.replaceAllMapped(RegExp(r'\[(.+?)\]\(.+?\)'), (m) => m.group(1) ?? '');
    result = result.replaceAll(RegExp(r'^[*_]+|[*_]+$'), '');
    return result.trim();
  }

  @override
  void didUpdateWidget(GuidedReadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textContent != widget.textContent || oldWidget.guidedJson != widget.guidedJson) {
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
    _animController.removeListener(_onAnimationTick);
    _animController.dispose();
    super.dispose();
  }

  int _getWordDelay(_Word word) {
    final baseDelay = (60000 / _baseWpm).toInt();
    final text = word.text;
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

    const commonWords = ['a', 'the', 'is', 'in', 'to', 'of', 'and', 'as', 'it', 'for', 'on', 'with', 'be', 'at', 'by'];
    if (commonWords.contains(clean) || clean.length <= 2) {
      return (baseDelay * 0.6).toInt();
    }
    if (clean.length >= 10) {
      return (baseDelay * 1.6).toInt();
    }
    if (text.contains('.') || text.contains('!') || text.contains('?')) {
      return (baseDelay * 2.2).toInt();
    }
    if (text.contains(',') || text.contains(';') || text.contains(':')) {
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
    _animController.stop();
    setState(() => _isPlaying = false);
  }

  void _togglePlayPause() {
    _isPlaying ? _pauseReading() : _startReading();
  }

  void _reset() {
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _position = 0.0;
      _targetIndex = 0;
      _isPlaying = false;
    });
    _animController.value = 0.0;
    if (widget.scrollController.hasClients) {
      widget.scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _scheduleNextWord() {
    if (!_isPlaying || _targetIndex >= _words.length) return;

    final delay = _getWordDelay(_words[_targetIndex]);

    // Calculate animation duration - smooth glide to next word
    // Use about 70% of word delay for the animation for slower, smoother movement
    final animDuration = (delay * 0.7).toInt().clamp(150, 400);

    _timer = Timer(Duration(milliseconds: delay - animDuration), () {
      if (!mounted || !_isPlaying) return;
      _advanceToNextWord(animDuration);
    });
  }

  void _advanceToNextWord(int animDuration) {
    if (_targetIndex >= _words.length - 1) {
      setState(() {
        _isPlaying = false;
        _position = _words.length.toDouble();
        widget.onComplete?.call();
      });
      return;
    }

    final fromPosition = _position;
    final toIndex = _targetIndex + 1;

    _targetIndex = toIndex;

    // Animate smoothly from current position to next word
    _animController.duration = Duration(milliseconds: animDuration);

    // Calculate the animation range
    final startValue = fromPosition / toIndex;
    _animController.value = startValue.clamp(0.0, 1.0);

    _animController.animateTo(1.0, curve: Curves.linear).then((_) {
      if (_isPlaying && mounted) {
        _scheduleNextWord();
      }
    });
  }

  void _onProgressTap(double progress) {
    final targetIndex = (progress * _wordCount).toInt().clamp(0, _wordCount - 1);
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _position = targetIndex.toDouble();
      _targetIndex = targetIndex;
    });
    if (_targetIndex > 0) {
      _animController.value = 1.0;
    }
  }

  void _onWordTap(int index) {
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _position = index.toDouble();
      _targetIndex = index;
      _isPlaying = false;
    });
    if (_targetIndex > 0) {
      _animController.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) {
      return widget.child;
    }

    return Column(
      children: [
        _buildControlBar(context),
        Expanded(child: _buildReadingContent(context)),
        _buildProgressBar(context),
      ],
    );
  }

  Widget _buildReadingContent(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null && widget.title!.isNotEmpty) ...[
            Text(
              widget.title!,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 28),
          ],
          for (int pIdx = 0; pIdx < _paragraphs.length; pIdx++) ...[
            _buildParagraph(context, _paragraphs[pIdx]),
            if (pIdx < _paragraphs.length - 1)
              SizedBox(height: _getSpacingAfterParagraph(_paragraphs[pIdx])),
          ],
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  double _getSpacingAfterParagraph(_Paragraph paragraph) {
    if (paragraph.isHeading) {
      return paragraph.headingLevel == 1 ? 16 : 12;
    }
    if (paragraph.isCodeBlock) return 20;
    if (paragraph.isBlockquote) return 16;
    if (paragraph.isList) return 4; // Tight spacing for consecutive list items
    return 16; // Regular paragraph spacing
  }

  Widget _buildParagraph(BuildContext context, _Paragraph paragraph) {
    final paragraphWords = _words
        .where((w) => w.globalIndex >= paragraph.startWordIndex && w.globalIndex < paragraph.endWordIndex)
        .toList();

    TextStyle getBaseStyle() {
      // Notion-like typography
      if (paragraph.isHeading) {
        switch (paragraph.headingLevel) {
          case 1:
            return const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            );
          case 2:
            return const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              height: 1.35,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            );
          case 3:
            return const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textPrimary,
            );
          default:
            return const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.textPrimary,
            );
        }
      }
      // Regular body text - Notion-like
      return const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.7,
        letterSpacing: 0.1,
        color: AppColors.textPrimary,
      );
    }

    final baseStyle = getBaseStyle();

    // Use AnimatedBuilder for smooth continuous updates
    Widget textWidget = AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Wrap(
          spacing: 0,
          runSpacing: 10,
          children: [
            for (int i = 0; i < paragraphWords.length; i++) ...[
              _buildWordWidget(paragraphWords[i], baseStyle),
              if (!paragraphWords[i].isLastInParagraph)
                _buildSpaceWidget(paragraphWords[i], baseStyle),
            ],
          ],
        );
      },
    );

    // Code blocks - Notion-like dark theme
    if (paragraph.isCodeBlock && paragraph.rawCode != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark code background
          borderRadius: BorderRadius.circular(6),
        ),
        child: SelectableText(
          paragraph.rawCode!,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.6,
            letterSpacing: 0.3,
            color: Color(0xFFD4D4D4), // Light gray code text
          ),
        ),
      );
    }

    // Blockquote - Notion-like subtle style
    if (paragraph.isBlockquote) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Color(0xFFE0E0E0), // Subtle gray border
              width: 3,
            ),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          child: textWidget,
        ),
      );
    }

    // List items - Notion-like clean bullets
    if (paragraph.isList) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 10),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withAlpha(180),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Expanded(child: textWidget),
          ],
        ),
      );
    }

    return textWidget;
  }

  double _getIntensityAtPosition(double pos) {
    final distance = (pos - _position).abs();
    // Tight spotlight - only current word and space during transition
    const spotlightRadius = 0.7;
    if (distance >= spotlightRadius) return 0.0;
    // Sharp falloff - mostly full brightness, quick fade at edges
    double intensity = (1.0 - (distance / spotlightRadius)).clamp(0.0, 1.0);
    return intensity;
  }

  Widget _buildWordWidget(_Word word, TextStyle baseStyle) {
    final wordIndex = word.globalIndex;
    final intensity = _getIntensityAtPosition(wordIndex.toDouble());
    final isPast = wordIndex < _position - 0.5;

    // Check adjacent elements for continuous highlight
    final prevSpaceIntensity = _getIntensityAtPosition(wordIndex - 0.5);
    final nextSpaceIntensity = _getIntensityAtPosition(wordIndex + 0.5);

    // Text color based on spotlight intensity - Notion-like subtle transitions
    Color textColor;
    if (intensity > 0.1) {
      // Highlighted text - white on teal
      textColor = Color.lerp(AppColors.textPrimary, Colors.white, intensity)!;
    } else if (isPast) {
      // Already read - full color
      textColor = AppColors.textPrimary;
    } else {
      // Not yet read - subtle gray (more readable than before)
      textColor = const Color(0xFFBDBDBD);
    }

    final bgOpacity = intensity > 0.1 ? intensity : 0.0;

    // Only round corners on outer edges (not where it connects to adjacent highlighted elements)
    final hasLeftNeighbor = prevSpaceIntensity > 0.1 && !word.globalIndex.isNegative;
    final hasRightNeighbor = nextSpaceIntensity > 0.1 && !word.isLastInParagraph;

    final borderRadius = BorderRadius.horizontal(
      left: hasLeftNeighbor ? Radius.zero : const Radius.circular(3),
      right: hasRightNeighbor ? Radius.zero : const Radius.circular(3),
    );

    return GestureDetector(
      onTap: () => _onWordTap(word.globalIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: bgOpacity > 0
              ? widget.highlightColor.withAlpha((bgOpacity * 255).round())
              : Colors.transparent,
          borderRadius: borderRadius,
        ),
        child: Text(word.text, style: baseStyle.copyWith(color: textColor)),
      ),
    );
  }

  Widget _buildSpaceWidget(_Word wordBefore, TextStyle baseStyle) {
    final spacePosition = wordBefore.globalIndex + 0.5;
    final intensity = _getIntensityAtPosition(spacePosition);
    final isPast = spacePosition < _position - 0.5;

    // Check adjacent words for continuous highlight
    final prevWordIntensity = _getIntensityAtPosition(wordBefore.globalIndex.toDouble());
    final nextWordIntensity = _getIntensityAtPosition((wordBefore.globalIndex + 1).toDouble());

    Color textColor;
    if (intensity > 0.1) {
      textColor = Color.lerp(AppColors.textPrimary, Colors.white, intensity)!;
    } else if (isPast) {
      textColor = AppColors.textPrimary;
    } else {
      textColor = const Color(0xFFBDBDBD);
    }

    final bgOpacity = intensity > 0.1 ? intensity : 0.0;

    // Space should have no border radius when connecting highlighted words
    final hasLeftNeighbor = prevWordIntensity > 0.1;
    final hasRightNeighbor = nextWordIntensity > 0.1;

    BorderRadius borderRadius;
    if (hasLeftNeighbor && hasRightNeighbor) {
      borderRadius = BorderRadius.zero; // Middle of highlight - no rounding
    } else if (hasLeftNeighbor) {
      borderRadius = const BorderRadius.horizontal(right: Radius.circular(3));
    } else if (hasRightNeighbor) {
      borderRadius = const BorderRadius.horizontal(left: Radius.circular(3));
    } else {
      borderRadius = BorderRadius.circular(3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
      decoration: BoxDecoration(
        color: bgOpacity > 0
            ? widget.highlightColor.withAlpha((bgOpacity * 255).round())
            : Colors.transparent,
        borderRadius: borderRadius,
      ),
      child: Text(' ', style: baseStyle.copyWith(color: textColor)),
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = _wordCount == 0 ? 0.0 : _position / _wordCount;

    return Container(
      height: 2,
      color: const Color(0xFFF5F5F5),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: widget.highlightColor,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(1)),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBar(BuildContext context) {
    final progress = _wordCount == 0 ? 0.0 : _position / _wordCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
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
              height: 20,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.0, 1.0),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: widget.highlightColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 40) * progress.clamp(0.0, 1.0) - 5,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: widget.highlightColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Controls row
          Row(
            children: [
              _ControlButton(
                icon: Icons.refresh_rounded,
                onPressed: _reset,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              _ControlButton(
                icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onPressed: _togglePlayPause,
                color: Colors.white,
                backgroundColor: widget.highlightColor,
                size: 20,
              ),
              const SizedBox(width: 16),
              // Speed control
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Speed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: widget.highlightColor.withAlpha(200),
                          inactiveTrackColor: const Color(0xFFEEEEEE),
                          thumbColor: widget.highlightColor,
                          overlayColor: widget.highlightColor.withAlpha(30),
                        ),
                        child: Slider(
                          value: _speed,
                          onChanged: (v) => setState(() => _speed = v),
                          min: 0.0,
                          max: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '$_baseWpm',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      ' wpm',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _ControlButton(
                icon: Icons.close_rounded,
                onPressed: widget.onDisable,
                color: AppColors.textSecondary,
              ),
            ],
          ),
          // Word count
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_position.floor()} of $_wordCount words',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary.withAlpha(180),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) => builder(context, child);
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
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final hasBackground = backgroundColor != null;
    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(hasBackground ? 8 : 6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(hasBackground ? 8 : 6),
        hoverColor: hasBackground ? null : const Color(0x0A000000),
        child: Padding(
          padding: EdgeInsets.all(hasBackground ? 10 : 6),
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

class _Word {
  final String text;
  final int paragraphIndex;
  final int globalIndex;
  final bool isLastInParagraph;

  _Word({
    required this.text,
    required this.paragraphIndex,
    required this.globalIndex,
    required this.isLastInParagraph,
  });
}

class _Paragraph {
  final String text;
  final String? rawCode; // For code blocks - stores original formatted code
  final bool isHeading;
  final int headingLevel;
  final bool isList;
  final bool isCodeBlock;
  final bool isBlockquote;
  final int startWordIndex;
  final int endWordIndex;

  _Paragraph({
    required this.text,
    this.rawCode,
    required this.isHeading,
    this.headingLevel = 0,
    this.isList = false,
    this.isCodeBlock = false,
    this.isBlockquote = false,
    required this.startWordIndex,
    required this.endWordIndex,
  });
}

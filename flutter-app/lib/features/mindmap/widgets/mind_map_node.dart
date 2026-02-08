import 'package:flutter/material.dart';
import '../data/concept_categories.dart';

class MindMapNode extends StatefulWidget {
  final ConceptCategory category;
  final bool isRoot;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool isSelected;

  const MindMapNode({
    super.key,
    required this.category,
    this.isRoot = false,
    this.isExpanded = false,
    this.onTap,
    this.onDoubleTap,
    this.isSelected = false,
  });

  @override
  State<MindMapNode> createState() => _MindMapNodeState();
}

class _MindMapNodeState extends State<MindMapNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final size = widget.isRoot ? 120.0 : 100.0;
    final fontSize = widget.isRoot ? 14.0 : 12.0;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  category.color,
                  category.color.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.isRoot ? 60 : 16),
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(0.4),
                  blurRadius: _isHovered ? 20 : 12,
                  spreadRadius: _isHovered ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
                if (widget.isSelected)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
              ],
              border: Border.all(
                color: widget.isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                width: widget.isSelected ? 3 : 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.isRoot ? 60 : 16),
                onTap: widget.onTap,
                onDoubleTap: widget.onDoubleTap,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        color: Colors.white,
                        size: widget.isRoot ? 32 : 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      if (category.children.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${category.children.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small chip-style node for child categories
class MindMapChipNode extends StatefulWidget {
  final ConceptCategory category;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final bool isSelected;

  const MindMapChipNode({
    super.key,
    required this.category,
    this.onTap,
    this.onDoubleTap,
    this.isSelected = false,
  });

  @override
  State<MindMapChipNode> createState() => _MindMapChipNodeState();
}

class _MindMapChipNodeState extends State<MindMapChipNode> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final category = widget.category;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                category.color,
                category.color.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: category.color.withOpacity(_isHovered ? 0.5 : 0.3),
                blurRadius: _isHovered ? 12 : 6,
                spreadRadius: _isHovered ? 1 : 0,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: widget.isSelected
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                category.icon,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AnimatedBuilder helper for building widgets based on animation value
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

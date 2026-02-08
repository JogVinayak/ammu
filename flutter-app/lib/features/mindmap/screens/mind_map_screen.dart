import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/concept_categories.dart';
import '../widgets/mind_map_node.dart';
import '../widgets/notes_list_dialog.dart';

class MindMapScreen extends ConsumerStatefulWidget {
  const MindMapScreen({super.key});

  @override
  ConsumerState<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends ConsumerState<MindMapScreen>
    with TickerProviderStateMixin {
  ConceptCategory? _selectedCategory;
  ConceptCategory? _expandedCategory;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onNodeTap(ConceptCategory category) {
    setState(() {
      if (_expandedCategory?.id == category.id) {
        _expandedCategory = null;
      } else {
        _expandedCategory = category;
      }
      _selectedCategory = category;
    });
  }

  void _onNodeDoubleTap(ConceptCategory category) {
    showDialog(
      context: context,
      builder: (context) => NotesListDialog(category: category),
    );
  }

  void _resetView() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark slate
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade400,
                    Colors.blue.shade400,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_tree, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'FAANG Interview Roadmap',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.center_focus_strong, color: Colors.white70),
            onPressed: _resetView,
            tooltip: 'Reset view',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white70),
            onPressed: () => _showHelpDialog(),
            tooltip: 'Help',
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend bar
          _buildLegendBar(),
          // Mind map
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.5,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(200),
                child: Center(
                  child: SizedBox(
                    width: 1200,
                    height: 900,
                    child: CustomPaint(
                      painter: MindMapConnectionsPainter(
                        root: FaangRoadmap.root,
                        expandedCategory: _expandedCategory,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Root node at center
                          Positioned(
                            left: 540,
                            top: 390,
                            child: MindMapNode(
                              category: FaangRoadmap.root,
                              isRoot: true,
                              isSelected: _selectedCategory?.id == FaangRoadmap.root.id,
                              onTap: () => _onNodeTap(FaangRoadmap.root),
                              onDoubleTap: () => _onNodeDoubleTap(FaangRoadmap.root),
                            ),
                          ),
                          // Main category nodes arranged in a circle
                          ..._buildMainCategoryNodes(),
                          // Child nodes if category is expanded
                          if (_expandedCategory != null)
                            ..._buildChildNodes(_expandedCategory!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Selected category info bar
          if (_selectedCategory != null) _buildInfoBar(),
        ],
      ),
    );
  }

  List<Widget> _buildMainCategoryNodes() {
    final categories = FaangRoadmap.root.children;
    final count = categories.length;
    final centerX = 600.0;
    final centerY = 450.0;
    final radius = 280.0;

    return List.generate(count, (index) {
      final angle = (2 * math.pi * index / count) - (math.pi / 2);
      final x = centerX + radius * math.cos(angle) - 50;
      final y = centerY + radius * math.sin(angle) - 50;

      return Positioned(
        left: x,
        top: y,
        child: MindMapNode(
          category: categories[index],
          isExpanded: _expandedCategory?.id == categories[index].id,
          isSelected: _selectedCategory?.id == categories[index].id,
          onTap: () => _onNodeTap(categories[index]),
          onDoubleTap: () => _onNodeDoubleTap(categories[index]),
        ),
      );
    });
  }

  List<Widget> _buildChildNodes(ConceptCategory parent) {
    final children = parent.children;
    if (children.isEmpty) return [];

    // Find parent position
    final categories = FaangRoadmap.root.children;
    final parentIndex = categories.indexWhere((c) => c.id == parent.id);
    if (parentIndex == -1) return [];

    final centerX = 600.0;
    final centerY = 450.0;
    final parentRadius = 280.0;
    final parentAngle = (2 * math.pi * parentIndex / categories.length) - (math.pi / 2);
    final parentX = centerX + parentRadius * math.cos(parentAngle);
    final parentY = centerY + parentRadius * math.sin(parentAngle);

    // Position children in an arc around the parent
    final childRadius = 130.0;
    final arcSpread = math.pi * 0.6; // 60% of a semicircle
    final startAngle = parentAngle - arcSpread / 2;

    return List.generate(children.length, (index) {
      final childAngle = startAngle + (arcSpread * index / (children.length - 1).clamp(1, 100));
      final x = parentX + childRadius * math.cos(childAngle);
      final y = parentY + childRadius * math.sin(childAngle);

      return Positioned(
        left: x - 60,
        top: y - 20,
        child: MindMapChipNode(
          category: children[index],
          isSelected: _selectedCategory?.id == children[index].id,
          onTap: () => setState(() => _selectedCategory = children[index]),
          onDoubleTap: () => _onNodeDoubleTap(children[index]),
        ),
      );
    });
  }

  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildLegendItem('Data Structures', FaangRoadmap.dsaColor),
            _buildLegendItem('Algorithms', const Color(0xFF0EA5E9)),
            _buildLegendItem('System Design', FaangRoadmap.systemDesignColor),
            _buildLegendItem('Behavioral', FaangRoadmap.behavioralColor),
            _buildLegendItem('Languages', FaangRoadmap.languageColor),
            _buildLegendItem('Math', FaangRoadmap.mathColor),
            _buildLegendItem('OS', FaangRoadmap.osColor),
            _buildLegendItem('Networking', FaangRoadmap.networkColor),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, color: Colors.white70, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Tap to expand • Double-tap for notes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar() {
    final category = _selectedCategory!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(
          top: BorderSide(color: category.color.withOpacity(0.5), width: 2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(category.icon, color: category.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color: category.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
                if (category.keywords.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: category.keywords.take(5).map((keyword) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: category.color.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          keyword,
                          style: TextStyle(
                            color: category.color,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _onNodeDoubleTap(category),
            icon: const Icon(Icons.article_outlined, size: 18),
            label: const Text('View Notes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: category.color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.help_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'How to Use',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(Icons.touch_app, 'Tap', 'Expand/collapse a category'),
            const SizedBox(height: 12),
            _buildHelpItem(Icons.ads_click, 'Double-tap', 'View notes for that topic'),
            const SizedBox(height: 12),
            _buildHelpItem(Icons.pinch, 'Pinch', 'Zoom in/out'),
            const SizedBox(height: 12),
            _buildHelpItem(Icons.pan_tool, 'Drag', 'Pan around the map'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String action, String description) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom painter for drawing connections between nodes
class MindMapConnectionsPainter extends CustomPainter {
  final ConceptCategory root;
  final ConceptCategory? expandedCategory;

  MindMapConnectionsPainter({
    required this.root,
    this.expandedCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = 600.0;
    final centerY = 450.0;
    final rootCenter = Offset(centerX, centerY);

    final categories = root.children;
    final count = categories.length;
    final radius = 280.0;

    // Draw connections from root to main categories
    for (var i = 0; i < count; i++) {
      final angle = (2 * math.pi * i / count) - (math.pi / 2);
      final endX = centerX + radius * math.cos(angle);
      final endY = centerY + radius * math.sin(angle);
      final endPoint = Offset(endX, endY);

      final gradient = LinearGradient(
        colors: [
          root.color.withOpacity(0.6),
          categories[i].color.withOpacity(0.6),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromPoints(rootCenter, endPoint),
        )
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw curved path
      final path = Path();
      path.moveTo(rootCenter.dx, rootCenter.dy);

      final controlPoint1 = Offset(
        rootCenter.dx + (endPoint.dx - rootCenter.dx) * 0.4,
        rootCenter.dy + (endPoint.dy - rootCenter.dy) * 0.1,
      );
      final controlPoint2 = Offset(
        rootCenter.dx + (endPoint.dx - rootCenter.dx) * 0.6,
        endPoint.dy - (endPoint.dy - rootCenter.dy) * 0.1,
      );

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        endPoint.dx, endPoint.dy,
      );

      canvas.drawPath(path, paint);

      // Draw child connections if this category is expanded
      if (expandedCategory?.id == categories[i].id) {
        _drawChildConnections(
          canvas,
          categories[i],
          endPoint,
          angle,
        );
      }
    }
  }

  void _drawChildConnections(
    Canvas canvas,
    ConceptCategory parent,
    Offset parentCenter,
    double parentAngle,
  ) {
    final children = parent.children;
    if (children.isEmpty) return;

    final childRadius = 130.0;
    final arcSpread = math.pi * 0.6;
    final startAngle = parentAngle - arcSpread / 2;

    for (var i = 0; i < children.length; i++) {
      final childAngle = startAngle + (arcSpread * i / (children.length - 1).clamp(1, 100));
      final endX = parentCenter.dx + childRadius * math.cos(childAngle);
      final endY = parentCenter.dy + childRadius * math.sin(childAngle);
      final endPoint = Offset(endX, endY);

      final paint = Paint()
        ..color = parent.color.withOpacity(0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(parentCenter, endPoint, paint);

      // Draw small dot at connection point
      final dotPaint = Paint()
        ..color = parent.color.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(endPoint, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MindMapConnectionsPainter oldDelegate) {
    return oldDelegate.expandedCategory != expandedCategory;
  }
}

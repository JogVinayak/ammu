import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/mindmap_models.dart';

class MindmapEditorScreen extends ConsumerStatefulWidget {
  final String? mindmapId;

  const MindmapEditorScreen({super.key, this.mindmapId});

  @override
  ConsumerState<MindmapEditorScreen> createState() => _MindmapEditorScreenState();
}

class _MindmapEditorScreenState extends ConsumerState<MindmapEditorScreen> {
  final _titleController = TextEditingController();
  final List<MindmapNode> _nodes = [];
  MindmapNode? _selectedNode;
  bool _isLoading = false;
  bool _isSaving = false;

  bool get isEditing => widget.mindmapId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadMindmap();
    } else {
      _nodes.add(const MindmapNode(
        id: 'root',
        label: 'Main Topic',
        x: 150,
        y: 100,
      ));
    }
  }

  Future<void> _loadMindmap() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
      _titleController.text = 'Physics Concepts';
      _nodes.addAll([
        const MindmapNode(id: 'n1', label: 'Physics', x: 150, y: 50),
        const MindmapNode(id: 'n2', label: 'Mechanics', x: 50, y: 150, childIds: ['n1']),
        const MindmapNode(id: 'n3', label: 'Thermodynamics', x: 250, y: 150, childIds: ['n1']),
      ]);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addNode() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Node'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Node Label',
              hintText: 'Enter node label',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _nodes.add(MindmapNode(
                      id: 'n${_nodes.length + 1}',
                      label: controller.text,
                      x: 100 + (_nodes.length * 30).toDouble(),
                      y: 200,
                      childIds: _selectedNode != null ? [_selectedNode!.id] : [],
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editNode(MindmapNode node) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: node.label);
        return AlertDialog(
          title: const Text('Edit Node'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Node Label',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _nodes.remove(node);
                });
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    final index = _nodes.indexOf(node);
                    _nodes[index] = node.copyWith(label: controller.text);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMindmap() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Mindmap updated' : 'Mindmap created'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Mindmap' : 'Create Mindmap'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveMindmap,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading mindmap...')
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Mindmap Title',
                      hintText: 'Enter title',
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: InteractiveViewer(
                      boundaryMargin: const EdgeInsets.all(100),
                      minScale: 0.5,
                      maxScale: 2.0,
                      child: Stack(
                        children: [
                          CustomPaint(
                            painter: _ConnectionPainter(_nodes),
                            size: Size.infinite,
                          ),
                          ..._nodes.map((node) => Positioned(
                                left: node.x,
                                top: node.y,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedNode = _selectedNode == node ? null : node;
                                    });
                                  },
                                  onDoubleTap: () => _editNode(node),
                                  onPanUpdate: (details) {
                                    setState(() {
                                      final index = _nodes.indexOf(node);
                                      _nodes[index] = node.copyWith(
                                        x: node.x + details.delta.dx,
                                        y: node.y + details.delta.dy,
                                      );
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedNode == node
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.button),
                                      border: Border.all(
                                        color: _selectedNode == node
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      node.label,
                                      style: TextStyle(
                                        color: _selectedNode == node
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Tip: Tap to select, double-tap to edit, drag to move',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNode,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ConnectionPainter extends CustomPainter {
  final List<MindmapNode> nodes;

  _ConnectionPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      for (final parentId in node.childIds) {
        final parent = nodes.firstWhere(
          (n) => n.id == parentId,
          orElse: () => node,
        );
        if (parent != node) {
          canvas.drawLine(
            Offset(node.x + 50, node.y + 15),
            Offset(parent.x + 50, parent.y + 15),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter oldDelegate) => true;
}

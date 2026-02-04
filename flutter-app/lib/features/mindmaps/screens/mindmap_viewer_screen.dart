import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/mindmap_models.dart';
import '../providers/mindmaps_provider.dart';

class MindmapViewerScreen extends ConsumerWidget {
  final String mindmapId;

  const MindmapViewerScreen({super.key, required this.mindmapId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mindmapAsync = ref.watch(mindmapDetailProvider(mindmapId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindmap'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/mindmaps/$mindmapId/edit'),
          ),
        ],
      ),
      body: mindmapAsync.when(
        data: (mindmap) {
          if (mindmap == null) {
            return const AppErrorWidget(message: 'Mindmap not found');
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mindmap.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (mindmap.description != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        mindmap.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${mindmap.nodeCount} nodes',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${mindmap.updatedAt.day}/${mindmap.updatedAt.month}/${mindmap.updatedAt.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
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
                    maxScale: 3.0,
                    child: Stack(
                      children: [
                        CustomPaint(
                          painter: _ConnectionPainter(mindmap.nodes),
                          size: Size.infinite,
                        ),
                        ...mindmap.nodes.map((node) => Positioned(
                              left: node.x,
                              top: node.y,
                              child: GestureDetector(
                                onTap: () => _showNodeDetails(context, node),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.button),
                                    border: Border.all(
                                      color: AppColors.primary,
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
                                    style: const TextStyle(
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
                  'Pinch to zoom, drag to pan, tap node for details',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(message: 'Loading mindmap...'),
        error: (error, _) => AppErrorWidget(message: error.toString()),
      ),
    );
  }

  void _showNodeDetails(BuildContext context, MindmapNode node) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (node.noteId != null) ...[
              AppButton(
                text: 'View Linked Note',
                icon: Icons.description,
                variant: AppButtonVariant.outline,
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/notes/${node.noteId}');
                },
                isFullWidth: true,
              ),
            ] else ...[
              Text(
                'No linked note',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
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

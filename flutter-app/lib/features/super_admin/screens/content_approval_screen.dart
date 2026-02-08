import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';

class ContentApprovalScreen extends ConsumerStatefulWidget {
  const ContentApprovalScreen({super.key});

  @override
  ConsumerState<ContentApprovalScreen> createState() => _ContentApprovalScreenState();
}

class _ContentApprovalScreenState extends ConsumerState<ContentApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _accentColor = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch pending notes and mindmaps from API
    final pendingNotes = <Map<String, dynamic>>[];
    final pendingMindmaps = <Map<String, dynamic>>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Approval'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accentColor,
          labelColor: _accentColor,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Notes'),
                  if (pendingNotes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildBadge(pendingNotes.length),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Mindmaps'),
                  if (pendingMindmaps.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildBadge(pendingMindmaps.length),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingList(context, pendingNotes, 'note'),
          _buildPendingList(context, pendingMindmaps, 'mindmap'),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPendingList(
    BuildContext context,
    List<Map<String, dynamic>> items,
    String type,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(context, type);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh pending items
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _ApprovalCard(
            title: item['title'] ?? '',
            type: type,
            schoolName: item['schoolName'] ?? 'Unknown School',
            creatorName: item['creatorName'] ?? 'Unknown',
            submittedAt: item['submittedAt'] != null
                ? DateTime.parse(item['submittedAt'])
                : DateTime.now(),
            onApprove: () => _showApprovalDialog(context, item, true),
            onReject: () => _showApprovalDialog(context, item, false),
            onTap: () {
              // TODO: Navigate to content preview
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No pending ${type}s',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All ${type}s have been reviewed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showApprovalDialog(
    BuildContext context,
    Map<String, dynamic> item,
    bool isApproval,
  ) {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproval ? 'Approve Content' : 'Reject Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApproval
                  ? 'Are you sure you want to approve "${item['title']}"?'
                  : 'Please provide a reason for rejection:',
            ),
            if (!isApproval) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Call approve/reject API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isApproval
                        ? 'Content approved successfully'
                        : 'Content rejected',
                  ),
                  backgroundColor: isApproval ? AppColors.success : AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? AppColors.success : AppColors.error,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final String title;
  final String type;
  final String schoolName;
  final String creatorName;
  final DateTime submittedAt;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTap;

  const _ApprovalCard({
    required this.title,
    required this.type,
    required this.schoolName,
    required this.creatorName,
    required this.submittedAt,
    required this.onApprove,
    required this.onReject,
    required this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: type == 'note'
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Icon(
                      type == 'note' ? Icons.article : Icons.account_tree,
                      color: type == 'note'
                          ? AppColors.primary
                          : AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          schoolName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    creatorName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(submittedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

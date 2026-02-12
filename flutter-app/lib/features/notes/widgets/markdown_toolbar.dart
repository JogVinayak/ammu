import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class MarkdownToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onStrikethrough;
  final VoidCallback onInlineCode;
  final ValueChanged<int> onHeading;
  final VoidCallback onBulletList;
  final VoidCallback onNumberedList;
  final VoidCallback onChecklist;
  final VoidCallback onQuote;
  final VoidCallback onCodeBlock;
  final VoidCallback onDivider;
  final VoidCallback onTable;
  final VoidCallback onLink;
  final VoidCallback onImage;
  final bool isUploadingImage;

  const MarkdownToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onStrikethrough,
    required this.onInlineCode,
    required this.onHeading,
    required this.onBulletList,
    required this.onNumberedList,
    required this.onChecklist,
    required this.onQuote,
    required this.onCodeBlock,
    required this.onDivider,
    required this.onTable,
    required this.onLink,
    required this.onImage,
    required this.isUploadingImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            // Text formatting
            _ToolbarBtn(icon: Icons.format_bold, tooltip: 'Bold', onPressed: onBold),
            _ToolbarBtn(icon: Icons.format_italic, tooltip: 'Italic', onPressed: onItalic),
            _ToolbarBtn(icon: Icons.strikethrough_s, tooltip: 'Strikethrough', onPressed: onStrikethrough),
            _ToolbarBtn(icon: Icons.code, tooltip: 'Inline Code', onPressed: onInlineCode),
            const _ToolbarSeparator(),
            // Headings
            _HeadingDropdown(onHeading: onHeading),
            const _ToolbarSeparator(),
            // Lists
            _ToolbarBtn(icon: Icons.format_list_bulleted, tooltip: 'Bullet List', onPressed: onBulletList),
            _ToolbarBtn(icon: Icons.format_list_numbered, tooltip: 'Numbered List', onPressed: onNumberedList),
            _ToolbarBtn(icon: Icons.check_box_outlined, tooltip: 'Checklist', onPressed: onChecklist),
            const _ToolbarSeparator(),
            // Blocks
            _ToolbarBtn(icon: Icons.format_quote, tooltip: 'Quote', onPressed: onQuote),
            _ToolbarBtn(icon: Icons.data_object, tooltip: 'Code Block', onPressed: onCodeBlock),
            _ToolbarBtn(icon: Icons.horizontal_rule, tooltip: 'Divider', onPressed: onDivider),
            _ToolbarBtn(icon: Icons.table_chart_outlined, tooltip: 'Table', onPressed: onTable),
            const _ToolbarSeparator(),
            // Insert
            _ToolbarBtn(icon: Icons.link, tooltip: 'Link', onPressed: onLink),
            if (isUploadingImage)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              _ToolbarBtn(icon: Icons.camera_alt, tooltip: 'Add Photo', onPressed: onImage),
          ],
        ),
      ),
    );
  }
}

class _ToolbarSeparator extends StatelessWidget {
  const _ToolbarSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 1,
        height: 20,
        color: AppColors.border,
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarBtn({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _HeadingDropdown extends StatelessWidget {
  final ValueChanged<int> onHeading;

  const _HeadingDropdown({required this.onHeading});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Heading',
      onSelected: onHeading,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 1,
          child: Text('Heading 1', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('Heading 2', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ),
        PopupMenuItem(
          value: 3,
          child: Text('Heading 3', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.title, size: 20, color: AppColors.textSecondary),
            Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_theme.dart';

class AppFlowyEditorWrapper extends ConsumerStatefulWidget {
  final String initialMarkdown;
  final VoidCallback? onImageRequested;

  const AppFlowyEditorWrapper({
    super.key,
    required this.initialMarkdown,
    this.onImageRequested,
  });

  @override
  ConsumerState<AppFlowyEditorWrapper> createState() =>
      AppFlowyEditorWrapperState();
}

class AppFlowyEditorWrapperState
    extends ConsumerState<AppFlowyEditorWrapper> {
  late EditorState _editorState;
  late EditorScrollController _scrollController;

  /// Export the current document as a markdown string.
  String exportToMarkdown() {
    final md = documentToMarkdown(_editorState.document);
    // Strip base URL from image paths to keep them relative
    final prefs = ref.read(sharedPreferencesProvider);
    final serverAddress = prefs.getString(StorageKeys.serverIp);
    final baseUrl = ApiConstants.baseUrl(serverAddress);
    return md.replaceAll(baseUrl, '');
  }

  /// Reinitialize the editor with new markdown content.
  void loadMarkdown(String markdown) {
    _scrollController.dispose();
    _editorState.dispose();
    _initEditor(markdown);
    if (mounted) setState(() {});
  }

  /// Insert an image node at the current cursor position.
  void insertImageUrl(String url) {
    final selection = _editorState.selection;
    if (selection == null) return;

    final transaction = _editorState.transaction;
    transaction.insertNode(
      selection.end.path.next,
      imageNode(url: url),
    );
    _editorState.apply(transaction);
  }

  @override
  void initState() {
    super.initState();
    _initEditor(widget.initialMarkdown);
  }

  void _initEditor(String markdown) {
    // Convert relative image URLs to full URLs for display
    final prefs = ref.read(sharedPreferencesProvider);
    final serverAddress = prefs.getString(StorageKeys.serverIp);
    final baseUrl = ApiConstants.baseUrl(serverAddress);
    final processedMd = _expandImageUrls(markdown, baseUrl);

    final doc = processedMd.trim().isEmpty
        ? Document.blank()
        : markdownToDocument(processedMd);
    _editorState = EditorState(document: doc);
    _scrollController = EditorScrollController(
      editorState: _editorState,
      shrinkWrap: false,
    );
  }

  /// Expand relative image paths to full URLs for rendering.
  String _expandImageUrls(String markdown, String baseUrl) {
    // Match markdown image syntax: ![alt](/v1/notes/...)
    return markdown.replaceAllMapped(
      RegExp(r'!\[([^\]]*)\]\((/v1/[^)]+)\)'),
      (match) => '![${match.group(1)}]($baseUrl${match.group(2)})',
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editorState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile =
        Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android;

    return isMobile ? _buildMobileEditor() : _buildDesktopEditor();
  }

  Widget _buildMobileEditor() {
    return Column(
      children: [
        Expanded(
          child: AppFlowyEditor(
            editorState: _editorState,
            editorScrollController: _scrollController,
            editorStyle: _buildMobileEditorStyle(),
            blockComponentBuilders: _buildBlockComponentBuilders(),
            characterShortcutEvents: _buildCharacterShortcuts(),
            editable: true,
          ),
        ),
        MobileToolbarV2(
          editorState: _editorState,
          toolbarItems: [
            textDecorationMobileToolbarItemV2,
            headingMobileToolbarItem,
            blocksMobileToolbarItem,
            listMobileToolbarItem,
            linkMobileToolbarItem,
            codeMobileToolbarItem,
            dividerMobileToolbarItem,
          ],
          child: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildDesktopEditor() {
    return FloatingToolbar(
      items: [
        paragraphItem,
        ...headingItems,
        ...markdownFormatItems,
        quoteItem,
        bulletedListItem,
        numberedListItem,
        linkItem,
      ],
      editorState: _editorState,
      editorScrollController: _scrollController,
      textDirection: Directionality.of(context),
      child: AppFlowyEditor(
        editorState: _editorState,
        editorScrollController: _scrollController,
        editorStyle: _buildDesktopEditorStyle(),
        blockComponentBuilders: _buildBlockComponentBuilders(),
        characterShortcutEvents: _buildCharacterShortcuts(),
        commandShortcutEvents: standardCommandShortcutEvents,
        editable: true,
      ),
    );
  }

  List<CharacterShortcutEvent> _buildCharacterShortcuts() {
    // Replace the default slash command with one that includes an image item
    final shortcuts = standardCharacterShortcutEvents
        .where((e) => e.key != 'show the slash menu')
        .toList();

    shortcuts.add(
      customSlashCommand([
        ...standardSelectionMenuItems,
        _imageSelectionMenuItem(),
      ]),
    );

    return shortcuts;
  }

  SelectionMenuItem _imageSelectionMenuItem() {
    return SelectionMenuItem(
      getName: () => 'Image',
      icon: (editorState, isSelected, style) => Icon(
        Icons.image_outlined,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: 18,
      ),
      keywords: ['image', 'photo', 'picture', 'camera'],
      handler: (editorState, menuService, context) {
        menuService.dismiss();
        widget.onImageRequested?.call();
      },
    );
  }

  EditorStyle _buildMobileEditorStyle() {
    return EditorStyle.mobile(
      cursorColor: AppColors.primary,
      dragHandleColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
    );
  }

  EditorStyle _buildDesktopEditorStyle() {
    return EditorStyle.desktop(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
    );
  }

  Map<String, BlockComponentBuilder> _buildBlockComponentBuilders() {
    final map = {...standardBlockComponentBuilderMap};

    // Custom image block with auth headers
    map[ImageBlockKeys.type] = _AuthImageBlockComponentBuilder(
      prefs: ref.read(sharedPreferencesProvider),
    );

    // Custom placeholder for paragraph
    map[ParagraphBlockKeys.type] = ParagraphBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        placeholderText: (node) =>
            node.delta?.isEmpty ?? true
                ? 'Type something or press / for commands...'
                : '',
      ),
    );

    return map;
  }
}

/// Custom image block builder that adds auth headers for backend images.
class _AuthImageBlockComponentBuilder extends BlockComponentBuilder {
  final SharedPreferences prefs;

  _AuthImageBlockComponentBuilder({required this.prefs});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return _AuthImageBlockWidget(
      key: node.key,
      node: node,
      prefs: prefs,
      configuration: configuration,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class _AuthImageBlockWidget extends BlockComponentStatefulWidget {
  final SharedPreferences prefs;

  const _AuthImageBlockWidget({
    super.key,
    required super.node,
    required this.prefs,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<_AuthImageBlockWidget> createState() => _AuthImageBlockWidgetState();
}

class _AuthImageBlockWidgetState extends State<_AuthImageBlockWidget>
    with BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  @override
  Widget build(BuildContext context) {
    final url = widget.node.attributes[ImageBlockKeys.url] as String? ?? '';
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    final needsAuth =
        url.contains('/v1/notes/') || url.contains('/v1/');

    Map<String, String>? headers;
    if (needsAuth) {
      headers = {};
      final accessToken = widget.prefs.getString(StorageKeys.accessToken);
      final tenantId = widget.prefs.getString(StorageKeys.tenantId);
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      if (tenantId != null && tenantId.isNotEmpty) {
        headers['X-Tenant-Id'] = tenantId;
      }
      if (url.contains('ngrok')) {
        headers['ngrok-skip-browser-warning'] = 'true';
      }
    }

    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          headers: headers,
          fit: BoxFit.contain,
          width: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey.shade200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 100,
              color: Colors.grey.shade200,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 32, color: Colors.grey),
                    SizedBox(height: 4),
                    Text('Failed to load image',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

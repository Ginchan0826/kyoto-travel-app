import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../application/itinerary_providers.dart';
import '../domain/canvas_element.dart';
import '../domain/design_page.dart';
import '../domain/spot.dart';
import '../domain/timeline_template.dart';
import 'canvas_element_content.dart';
import 'timeline_template_editor.dart';

enum _EditorMode { select, draw }

const List<Color> _penColors = [
  Colors.black,
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.orange,
];

const List<Color?> _backgroundColors = [
  null,
  Colors.white,
  Color(0xFFFFF8E1),
  Color(0xFFE8F5E9),
  Color(0xFFE3F2FD),
  Color(0xFFFCE4EC),
  Color(0xFFF3E5F5),
];

/// 1ページ分のデザインキャンバス編集画面。
/// 画像・スポットのテキストカードの配置、手書きペンでの落書き、背景色の変更ができる。
class PageCanvasEditorPage extends ConsumerStatefulWidget {
  const PageCanvasEditorPage({
    super.key,
    required this.itineraryId,
    required this.pageId,
    required this.pageNumber,
    this.isCover = false,
  });

  final String itineraryId;
  final String pageId;
  final int pageNumber;
  final bool isCover;

  @override
  ConsumerState<PageCanvasEditorPage> createState() =>
      _PageCanvasEditorPageState();
}

class _PageCanvasEditorPageState extends ConsumerState<PageCanvasEditorPage> {
  List<CanvasElement>? _elements;
  int? _backgroundColor;
  bool _initialized = false;
  bool _useTemplate = false;
  TimelineTemplateData _template = TimelineTemplateData.empty();
  final List<List<CanvasElement>> _undoStack = [];
  String? _selectedId;
  bool _isUploading = false;

  _EditorMode _mode = _EditorMode.select;
  Color _drawColor = _penColors.first;
  double _drawStrokeWidth = 6;
  List<Offset>? _currentStrokePoints;

  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInitialElements();
  }

  DesignPage? _findPage(List<DesignPage> pages) {
    for (final page in pages) {
      if (page.id == widget.pageId) return page;
    }
    return null;
  }

  /// ページの内容を開いたタイミングで一度だけ読み込む。
  /// 以降はFirestoreのライブ更新を追わず、編集中の内容をローカルの状態のみで管理する
  /// （保存は都度 _persist() で行う）。
  Future<void> _loadInitialElements() async {
    try {
      final pages = await ref.read(pagesProvider(widget.itineraryId).future);
      final page = _findPage(pages);
      if (!mounted) return;
      setState(() {
        _elements = page?.elements ?? const [];
        _backgroundColor = page?.backgroundColor;
        _useTemplate = page?.useTemplate ?? false;
        _template = page?.template ?? TimelineTemplateData.empty();
        _initialized = true;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e.toString());
    }
  }

  Future<void> _saveTemplate(TimelineTemplateData data) async {
    setState(() => _template = data);
    try {
      await ref.read(itineraryRepositoryProvider).updatePageTemplate(
            itineraryId: widget.itineraryId,
            pageId: widget.pageId,
            useTemplate: _useTemplate,
            template: data,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _toggleUseTemplate(bool value) async {
    setState(() => _useTemplate = value);
    try {
      await ref.read(itineraryRepositoryProvider).updatePageTemplate(
            itineraryId: widget.itineraryId,
            pageId: widget.pageId,
            useTemplate: value,
            template: _template,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  void _pushUndoSnapshot() {
    if (_elements == null) return;
    _undoStack.add(List<CanvasElement>.from(_elements!));
  }

  Future<void> _persist() async {
    if (_elements == null) return;
    try {
      await ref.read(itineraryRepositoryProvider).updatePageElements(
            itineraryId: widget.itineraryId,
            pageId: widget.pageId,
            elements: _elements!,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _elements = _undoStack.removeLast();
      _selectedId = null;
    });
    _persist();
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await ref.read(itineraryRepositoryProvider).uploadPageImage(
            itineraryId: widget.itineraryId,
            file: File(picked.path),
          );
      const size = 300.0;
      final newElement = CanvasElement(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        type: 'image',
        x: (CanvasElement.canvasWidth - size) / 2,
        y: (CanvasElement.canvasHeight - size) / 2,
        width: size,
        height: size,
        imageUrl: url,
      );
      _pushUndoSnapshot();
      setState(() {
        _elements = [...?_elements, newElement];
        _selectedId = newElement.id;
      });
      await _persist();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('画像の追加に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _addSpot() async {
    List<Spot> spots;
    try {
      spots = await ref.read(spotsProvider(widget.itineraryId).future);
    } catch (_) {
      spots = const [];
    }
    if (!mounted) return;
    if (spots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('エディタータブでスポットを追加してから使えます。')),
      );
      return;
    }
    final selected = await showModalBottomSheet<Spot>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final spot in spots)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(spot.name),
                subtitle: spot.address.isNotEmpty ? Text(spot.address) : null,
                onTap: () => Navigator.of(context).pop(spot),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;

    const width = 260.0;
    const height = 100.0;
    final newElement = CanvasElement(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      type: 'text',
      x: (CanvasElement.canvasWidth - width) / 2,
      y: (CanvasElement.canvasHeight - height) / 2,
      width: width,
      height: height,
      text: selected.name,
    );
    _pushUndoSnapshot();
    setState(() {
      _elements = [...?_elements, newElement];
      _selectedId = newElement.id;
    });
    await _persist();
  }

  void _deleteSelected() {
    if (_selectedId == null || _elements == null) return;
    _pushUndoSnapshot();
    setState(() {
      _elements = _elements!.where((e) => e.id != _selectedId).toList();
      _selectedId = null;
    });
    _persist();
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _EditorMode.select ? _EditorMode.draw : _EditorMode.select;
      _selectedId = null;
    });
  }

  Future<void> _pickBackgroundColor() async {
    final color = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final color in _backgroundColors)
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(color?.toARGB32()),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color ?? Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: color == null
                        ? const Icon(Icons.block, size: 20)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _backgroundColor = color);
    await ref.read(itineraryRepositoryProvider).updatePageBackgroundColor(
          itineraryId: widget.itineraryId,
          pageId: widget.pageId,
          backgroundColor: color,
        );
  }

  @override
  Widget build(BuildContext context) {
    final itineraryAsync = ref.watch(itineraryProvider(widget.itineraryId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCover ? '表紙のデザイン' : 'ページ ${widget.pageNumber} のデザイン'),
        actions: _useTemplate
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  tooltip: '背景色を変更',
                  onPressed: _pickBackgroundColor,
                ),
                IconButton(
                  icon: Icon(_mode == _EditorMode.draw
                      ? Icons.pan_tool_alt_outlined
                      : Icons.edit_outlined),
                  tooltip: _mode == _EditorMode.draw ? '選択モードに切替' : '手書きモードに切替',
                  onPressed: _toggleMode,
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: '元に戻す',
                  onPressed: _undoStack.isEmpty ? null : _undo,
                ),
                if (_mode == _EditorMode.select && _selectedId != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '選択中の要素を削除',
                    onPressed: _deleteSelected,
                  ),
              ],
      ),
      body: Builder(
        builder: (context) {
          if (_loadError != null) {
            return Center(child: Text('読み込みに失敗しました: $_loadError'));
          }
          if (!_initialized) {
            return const Center(child: CircularProgressIndicator());
          }
          final title = widget.isCover ? itineraryAsync.value?.title : null;
          return Column(
            children: [
              SwitchListTile(
                title: const Text('タイムラインテンプレートを使う'),
                subtitle: const Text('DAY1/DAY2形式の旅程表テンプレートに切り替えます'),
                value: _useTemplate,
                onChanged: _toggleUseTemplate,
              ),
              const Divider(height: 1),
              Expanded(
                child: _useTemplate
                    ? TimelineTemplateEditor(
                        itineraryId: widget.itineraryId,
                        data: _template,
                        onChanged: _saveTemplate,
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: CanvasElement.canvasWidth /
                                    CanvasElement.canvasHeight,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final scale = constraints.maxWidth /
                                        CanvasElement.canvasWidth;
                                    return _buildCanvas(scale, title);
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (_mode == _EditorMode.draw) _buildDrawToolbar(),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: !_useTemplate && _mode == _EditorMode.select
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'addSpot',
                  onPressed: _addSpot,
                  tooltip: 'スポットを追加',
                  child: const Icon(Icons.place_outlined),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.extended(
                  heroTag: 'addImage',
                  onPressed: _isUploading ? null : _addImage,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('画像を追加'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildCanvas(double scale, String? overlayTitle) {
    final isDrawMode = _mode == _EditorMode.draw;

    return GestureDetector(
      onTap: isDrawMode ? null : () => setState(() => _selectedId = null),
      onPanStart: isDrawMode
          ? (details) {
              _pushUndoSnapshot();
              setState(() {
                _currentStrokePoints = [details.localPosition / scale];
              });
            }
          : null,
      onPanUpdate: isDrawMode
          ? (details) {
              setState(() {
                _currentStrokePoints = [
                  ...?_currentStrokePoints,
                  details.localPosition / scale,
                ];
              });
            }
          : null,
      onPanEnd: isDrawMode
          ? (_) {
              if (_currentStrokePoints != null &&
                  _currentStrokePoints!.length > 1) {
                final stroke = CanvasElement(
                  id: '${DateTime.now().microsecondsSinceEpoch}',
                  type: 'stroke',
                  points: _currentStrokePoints,
                  colorValue: _drawColor.toARGB32(),
                  strokeWidth: _drawStrokeWidth,
                );
                setState(() {
                  _elements = [...?_elements, stroke];
                  _currentStrokePoints = null;
                });
                _persist();
              } else {
                _undoStack.removeLast();
                setState(() => _currentStrokePoints = null);
              }
            }
          : null,
      child: Container(
        color: _backgroundColor != null
            ? Color(_backgroundColor!)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (overlayTitle != null)
              Positioned(
                top: 32,
                left: 24,
                right: 24,
                child: Text(
                  overlayTitle.isEmpty ? '（タイトル未設定）' : overlayTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            for (final element in _elements!)
              if (element.type == 'stroke')
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _StrokePainter(element: element, scale: scale),
                    ),
                  ),
                )
              else
                IgnorePointer(
                  ignoring: isDrawMode,
                  child: _CanvasElementView(
                    key: ValueKey(element.id),
                    element: element,
                    scale: scale,
                    isSelected: element.id == _selectedId,
                    onSelect: () => setState(() => _selectedId = element.id),
                    onChangeStart: _pushUndoSnapshot,
                    onChanged: (updated) {
                      setState(() {
                        _elements = _elements!
                            .map((e) => e.id == updated.id ? updated : e)
                            .toList();
                      });
                    },
                    onChangeEnd: _persist,
                  ),
                ),
            if (_currentStrokePoints != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _StrokePainter(
                      element: CanvasElement(
                        id: '',
                        type: 'stroke',
                        points: _currentStrokePoints,
                        colorValue: _drawColor.toARGB32(),
                        strokeWidth: _drawStrokeWidth,
                      ),
                      scale: scale,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final color in _penColors)
              GestureDetector(
                onTap: () => setState(() => _drawColor = color),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _drawColor == color
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                min: 2,
                max: 24,
                value: _drawStrokeWidth,
                onChanged: (value) => setState(() => _drawStrokeWidth = value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({required this.element, required this.scale});

  final CanvasElement element;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final points = element.points;
    if (points == null || points.isEmpty) return;

    final paint = Paint()
      ..color = Color(element.colorValue ?? 0xFF000000)
      ..strokeWidth = (element.strokeWidth ?? 6) * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      canvas.drawCircle(points.first * scale, paint.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.dx * scale, points.first.dy * scale);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx * scale, p.dy * scale);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return oldDelegate.element != element || oldDelegate.scale != scale;
  }
}

class _CanvasElementView extends StatefulWidget {
  const _CanvasElementView({
    super.key,
    required this.element,
    required this.scale,
    required this.isSelected,
    required this.onSelect,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final CanvasElement element;
  final double scale;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onChangeStart;
  final ValueChanged<CanvasElement> onChanged;
  final VoidCallback onChangeEnd;

  @override
  State<_CanvasElementView> createState() => _CanvasElementViewState();
}

class _CanvasElementViewState extends State<_CanvasElementView> {
  late CanvasElement _gestureStart;

  @override
  Widget build(BuildContext context) {
    final e = widget.element;
    return Positioned(
      left: e.x * widget.scale,
      top: e.y * widget.scale,
      child: GestureDetector(
        onTap: widget.onSelect,
        onScaleStart: (_) {
          widget.onSelect();
          widget.onChangeStart();
          _gestureStart = widget.element;
        },
        onScaleUpdate: (details) {
          final newWidth =
              (_gestureStart.width * details.scale).clamp(40.0, CanvasElement.canvasWidth);
          final newHeight =
              (_gestureStart.height * details.scale).clamp(40.0, CanvasElement.canvasHeight);
          widget.onChanged(
            _gestureStart.copyWith(
              x: _gestureStart.x + details.focalPointDelta.dx / widget.scale,
              y: _gestureStart.y + details.focalPointDelta.dy / widget.scale,
              width: newWidth,
              height: newHeight,
              rotation: _gestureStart.rotation + details.rotation,
            ),
          );
        },
        onScaleEnd: (_) => widget.onChangeEnd(),
        child: Transform.rotate(
          angle: e.rotation,
          child: CanvasElementContent(
            element: e,
            scale: widget.scale,
            isSelected: widget.isSelected,
          ),
        ),
      ),
    );
  }
}

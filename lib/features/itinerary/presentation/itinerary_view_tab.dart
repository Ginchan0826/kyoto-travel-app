import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/itinerary_providers.dart';
import '../domain/canvas_element.dart';
import '../domain/design_page.dart';
import 'canvas_element_content.dart';
import 'timeline_template_view.dart';

/// 「しおり画面」タブ：旅行本番で実際に開く閲覧用のページ送りビュー。
class ItineraryViewTab extends ConsumerStatefulWidget {
  const ItineraryViewTab({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  ConsumerState<ItineraryViewTab> createState() => _ItineraryViewTabState();
}

class _ItineraryViewTabState extends ConsumerState<ItineraryViewTab> {
  final _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itineraryAsync = ref.watch(itineraryProvider(widget.itineraryId));
    final pagesAsync = ref.watch(pagesProvider(widget.itineraryId));

    return itineraryAsync.when(
      data: (itinerary) => pagesAsync.when(
        data: (allPages) {
          final split = SplitPages.from(allPages);
          final pages = [
            if (itinerary.hasCover && split.cover != null) split.cover!,
            ...split.contentPages,
          ];
          if (pages.isEmpty) {
            return const Center(child: Text('まだページがありません。'));
          }
          if (_currentIndex >= pages.length) _currentIndex = pages.length - 1;
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final isDisplayedCover =
                      itinerary.hasCover && split.cover?.id == page.id;
                  return _DesignPageView(
                    page: page,
                    overlayTitle: isDisplayedCover ? itinerary.title : null,
                  );
                },
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('${_currentIndex + 1} / ${pages.length}'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
    );
  }
}

class _DesignPageView extends StatelessWidget {
  const _DesignPageView({required this.page, this.overlayTitle});

  final DesignPage page;
  final String? overlayTitle;

  @override
  Widget build(BuildContext context) {
    if (page.useTemplate) {
      return Container(
        margin: const EdgeInsets.all(16),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: TimelineTemplateView(data: page.template),
      );
    }
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: page.backgroundColor != null
            ? Color(page.backgroundColor!)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: CanvasElement.canvasWidth / CanvasElement.canvasHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / CanvasElement.canvasWidth;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (overlayTitle != null)
                    Positioned(
                      top: 32 * scale,
                      left: 24 * scale,
                      right: 24 * scale,
                      child: Text(
                        overlayTitle!.isEmpty ? '（タイトル未設定）' : overlayTitle!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  for (final element in page.elements)
                    if (element.type == 'stroke')
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ViewStrokePainter(element: element, scale: scale),
                        ),
                      )
                    else
                      Positioned(
                        left: element.x * scale,
                        top: element.y * scale,
                        child: Transform.rotate(
                          angle: element.rotation,
                          child: CanvasElementContent(
                            element: element,
                            scale: scale,
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ViewStrokePainter extends CustomPainter {
  const _ViewStrokePainter({required this.element, required this.scale});

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
  bool shouldRepaint(covariant _ViewStrokePainter oldDelegate) {
    return oldDelegate.element != element || oldDelegate.scale != scale;
  }
}

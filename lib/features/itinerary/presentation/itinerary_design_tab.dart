import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/itinerary_providers.dart';
import '../domain/design_page.dart';
import '../domain/itinerary.dart';
import 'page_canvas_editor_page.dart';

/// 「デザイン編集」タブ：表紙の有無、ページの追加/削除/並び替えを行う。
/// タイトルはエディター（右上の編集アイコン）から編集する一つのタイトルに統一している。
class ItineraryDesignTab extends ConsumerWidget {
  const ItineraryDesignTab({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider(itineraryId));
    final pagesAsync = ref.watch(pagesProvider(itineraryId));

    return itineraryAsync.when(
      data: (itinerary) => pagesAsync.when(
        data: (pages) {
          if (itinerary.hasCover &&
              !pages.any((p) => p.isCover)) {
            // 旧バージョンで作成されたしおりには表紙ページがないため、初回表示時に補完する。
            Future.microtask(
              () => ref
                  .read(itineraryRepositoryProvider)
                  .ensureCoverPage(itineraryId),
            );
          }
          final split = SplitPages.from(pages);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _CoverSection(itinerary: itinerary, coverPage: split.cover),
              const SizedBox(height: 24),
              Text('ページ', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _PageList(itineraryId: itineraryId, pages: split.contentPages),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('ページの読み込みに失敗しました: $error'),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
    );
  }
}

class _CoverSection extends ConsumerWidget {
  const _CoverSection({required this.itinerary, required this.coverPage});

  final Itinerary itinerary;
  final DesignPage? coverPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('表紙を使う'),
              subtitle: const Text('OFFにすると1ページ目から本文になります。タイトルは右上の編集アイコンから変更できます。'),
              value: itinerary.hasCover,
              onChanged: (value) {
                ref.read(itineraryRepositoryProvider).updateHasCover(
                      itineraryId: itinerary.id,
                      hasCover: value,
                    );
              },
            ),
            if (itinerary.hasCover) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: coverPage == null
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PageCanvasEditorPage(
                              itineraryId: itinerary.id,
                              pageId: coverPage!.id,
                              pageNumber: 0,
                              isCover: true,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('表紙をデザインする'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PageList extends ConsumerWidget {
  const _PageList({required this.itineraryId, required this.pages});

  final String itineraryId;
  final List<DesignPage> pages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('まだページがありません。下のボタンから追加できます。'),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < pages.length; i++)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('ページ ${i + 1}'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PageCanvasEditorPage(
                      itineraryId: itineraryId,
                      pageId: pages[i].id,
                      pageNumber: i + 1,
                    ),
                  ),
                );
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: '上に移動',
                    onPressed: i == 0
                        ? null
                        : () => _movePage(ref, i, i - 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: '下に移動',
                    onPressed: i == pages.length - 1
                        ? null
                        : () => _movePage(ref, i, i + 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '削除',
                    onPressed: () {
                      ref.read(itineraryRepositoryProvider).deletePage(
                            itineraryId: itineraryId,
                            pageId: pages[i].id,
                          );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _movePage(WidgetRef ref, int fromIndex, int toIndex) {
    final orderedIds = pages.map((p) => p.id).toList();
    final id = orderedIds.removeAt(fromIndex);
    orderedIds.insert(toIndex, id);
    ref.read(itineraryRepositoryProvider).reorderPages(
          itineraryId: itineraryId,
          orderedPageIds: orderedIds,
        );
  }
}

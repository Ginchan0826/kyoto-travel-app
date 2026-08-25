import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../application/itinerary_providers.dart';
import '../domain/itinerary.dart';
import 'itinerary_form_page.dart';
import 'itinerary_workspace_page.dart';

class ItineraryListPage extends ConsumerWidget {
  const ItineraryListPage({super.key});

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('しおりを削除しますか？'),
        content: Text('「$title」を削除すると元に戻せません。スポットやページも全て削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(myItinerariesProvider);
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('京都 観光しおり'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: itinerariesAsync.when(
        data: (itineraries) {
          if (itineraries.isEmpty) {
            return const Center(child: Text('まだしおりがありません。右下のボタンから作成しましょう。'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itineraries.length,
            itemBuilder: (context, index) {
              final Itinerary itinerary = itineraries[index];
              final isOwner =
                  currentUid != null && itinerary.isOwner(currentUid);

              final card = Card(
                child: ListTile(
                  title: Text(itinerary.title),
                  subtitle:
                      itinerary.memo.isNotEmpty ? Text(itinerary.memo) : null,
                  trailing: isOwner
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: '削除',
                          onPressed: () async {
                            final confirmed =
                                await _confirmDelete(context, itinerary.title);
                            if (confirmed) {
                              await ref
                                  .read(itineraryRepositoryProvider)
                                  .deleteItinerary(itinerary.id);
                            }
                          },
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ItineraryWorkspacePage(itineraryId: itinerary.id),
                      ),
                    );
                  },
                ),
              );

              if (!isOwner) return card;

              return Dismissible(
                key: ValueKey(itinerary.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
                confirmDismiss: (_) => _confirmDelete(context, itinerary.title),
                onDismissed: (_) {
                  ref
                      .read(itineraryRepositoryProvider)
                      .deleteItinerary(itinerary.id);
                },
                child: card,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ItineraryFormPage()),
          );
        },
        tooltip: 'しおりを作成',
        child: const Icon(Icons.add),
      ),
    );
  }
}

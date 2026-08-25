import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../itinerary/application/itinerary_providers.dart';
import 'touring_spot_list_page.dart';

/// 「観光」タブのトップ：観光中に使うしおりを選ぶ画面。
class TouringItineraryListPage extends ConsumerWidget {
  const TouringItineraryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itinerariesAsync = ref.watch(myItinerariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('観光')),
      body: itinerariesAsync.when(
        data: (itineraries) {
          if (itineraries.isEmpty) {
            return const Center(child: Text('まだしおりがありません。「しおり」タブから作成しましょう。'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itineraries.length,
            itemBuilder: (context, index) {
              final itinerary = itineraries[index];
              return Card(
                child: ListTile(
                  title: Text(itinerary.title),
                  subtitle:
                      itinerary.memo.isNotEmpty ? Text(itinerary.memo) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TouringSpotListPage(
                          itineraryId: itinerary.id,
                          itineraryTitle: itinerary.title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
      ),
    );
  }
}

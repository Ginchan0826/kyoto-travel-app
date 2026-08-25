import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../itinerary/application/itinerary_providers.dart';
import 'touring_spot_chat_page.dart';

/// 「観光」タブ：選んだしおりに登録されているスポットの一覧。
class TouringSpotListPage extends ConsumerWidget {
  const TouringSpotListPage({
    super.key,
    required this.itineraryId,
    required this.itineraryTitle,
  });

  final String itineraryId;
  final String itineraryTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotsAsync = ref.watch(spotsProvider(itineraryId));

    return Scaffold(
      appBar: AppBar(title: Text(itineraryTitle)),
      body: spotsAsync.when(
        data: (spots) {
          if (spots.isEmpty) {
            return const Center(child: Text('このしおりにはまだスポットが登録されていません。'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(spot.name),
                  subtitle: spot.address.isNotEmpty ? Text(spot.address) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TouringSpotChatPage(
                          itineraryId: itineraryId,
                          spot: spot,
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

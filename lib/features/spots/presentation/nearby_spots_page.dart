import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/location_providers.dart';
import '../application/tourist_spot_providers.dart';
import 'tourist_spot_form_page.dart';

class NearbySpotsPage extends ConsumerWidget {
  const NearbySpotsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbySpotsAsync = ref.watch(nearbySpotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('現在地周辺の観光名所'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: '観光スポットを登録',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TouristSpotFormPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentPositionProvider);
          ref.invalidate(allTouristSpotsProvider);
          await ref.read(nearbySpotsProvider.future);
        },
        child: nearbySpotsAsync.when(
          data: (nearbySpots) {
            if (nearbySpots.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('登録されている観光スポットがありません。右上のボタンから登録できます。'),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: nearbySpots.length,
              itemBuilder: (context, index) {
                final nearby = nearbySpots[index];
                final spot = nearby.spot;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(spot.name),
                    subtitle: Text([
                      if (spot.address.isNotEmpty) spot.address,
                      if (spot.memo.isNotEmpty) spot.memo,
                    ].join('\n')),
                    trailing: Text(
                      nearby.distanceMeters >= 1000
                          ? '${(nearby.distanceMeters / 1000).toStringAsFixed(1)} km'
                          : '${nearby.distanceMeters.toStringAsFixed(0)} m',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(_messageForError(error)),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(currentPositionProvider);
                        ref.invalidate(allTouristSpotsProvider);
                      },
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _messageForError(Object error) {
    if (error is LocationPermissionDeniedException) {
      return '位置情報の利用が許可されていません。端末の設定から位置情報の利用を許可してください。';
    }
    if (error.toString().contains('LocationServiceDisabledException')) {
      return '位置情報サービスが無効になっています。端末の設定から位置情報をオンにしてください。';
    }
    return '観光スポットの取得に失敗しました: $error';
  }
}

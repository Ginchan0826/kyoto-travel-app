import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../application/itinerary_providers.dart';
import '../data/itinerary_repository.dart';
import '../domain/itinerary.dart';
import '../domain/spot.dart';
import 'spot_form_page.dart';

/// 「エディター」タブ：しおりの実データ（メモ・共同編集者・スポット）を編集する。
class ItineraryEditorTab extends ConsumerWidget {
  const ItineraryEditorTab({super.key, required this.itineraryId});

  final String itineraryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider(itineraryId));
    final spotsAsync = ref.watch(spotsProvider(itineraryId));
    final currentUid = ref.watch(authStateChangesProvider).value?.uid;

    return itineraryAsync.when(
      data: (itinerary) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          if (itinerary.memo.isNotEmpty) ...[
            Text(itinerary.memo),
            const SizedBox(height: 24),
          ],
          _CollaboratorSection(
            itinerary: itinerary,
            isOwner: currentUid != null && itinerary.isOwner(currentUid),
          ),
          const SizedBox(height: 24),
          Text('スポット一覧', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          spotsAsync.when(
            data: (spots) => _SpotList(itineraryId: itineraryId, spots: spots),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('スポットの読み込みに失敗しました: $error'),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
    );
  }
}

class _CollaboratorSection extends ConsumerWidget {
  const _CollaboratorSection({required this.itinerary, required this.isOwner});

  final Itinerary itinerary;
  final bool isOwner;

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setState(() {
                isSubmitting = true;
                errorMessage = null;
              });
              try {
                await ref.read(itineraryRepositoryProvider).addCollaboratorByEmail(
                      itineraryId: itinerary.id,
                      email: emailController.text.trim(),
                    );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              } on CollaboratorNotFoundException catch (e) {
                setState(() => errorMessage = e.toString());
              } catch (e) {
                setState(() => errorMessage = '招待に失敗しました: $e');
              } finally {
                setState(() => isSubmitting = false);
              }
            }

            return AlertDialog(
              title: const Text('共同編集者を招待'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '招待するユーザーのメールアドレス',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'メールアドレスを入力してください。';
                        }
                        return null;
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: const Text('招待する'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('共同編集者', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                tooltip: '招待する',
                onPressed: () => _showInviteDialog(context, ref),
              ),
          ],
        ),
        if (itinerary.collaboratorEmails.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text('まだ共同編集者はいません。'),
          )
        else
          ...List.generate(itinerary.collaboratorEmails.length, (index) {
            final email = itinerary.collaboratorEmails[index];
            final uid = itinerary.collaboratorIds[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(email),
              trailing: isOwner
                  ? IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: '解除',
                      onPressed: () {
                        ref.read(itineraryRepositoryProvider).removeCollaborator(
                              itineraryId: itinerary.id,
                              uid: uid,
                            );
                      },
                    )
                  : null,
            );
          }),
      ],
    );
  }
}

class _SpotList extends ConsumerWidget {
  const _SpotList({required this.itineraryId, required this.spots});

  final String itineraryId;
  final List<Spot> spots;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (spots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('まだスポットが登録されていません。右下のボタンから追加できます。'),
      );
    }

    return Column(
      children: spots
          .map(
            (spot) => Card(
              child: ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(spot.name),
                subtitle: _buildSubtitle(spot),
                isThreeLine: spot.address.isNotEmpty && spot.memo.isNotEmpty,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '削除',
                  onPressed: () {
                    ref.read(itineraryRepositoryProvider).deleteSpot(
                          itineraryId: itineraryId,
                          spotId: spot.id,
                        );
                  },
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget? _buildSubtitle(Spot spot) {
    final lines = [
      if (spot.address.isNotEmpty) spot.address,
      if (spot.memo.isNotEmpty) spot.memo,
    ];
    if (lines.isEmpty) return null;
    return Text(lines.join('\n'));
  }
}

/// エディタータブ用のスポット追加画面を開くヘルパー。
void openAddSpotPage(BuildContext context, WidgetRef ref, String itineraryId) {
  final nextOrder = ref.read(spotsProvider(itineraryId)).value?.length ?? 0;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SpotFormPage(itineraryId: itineraryId, nextOrder: nextOrder),
    ),
  );
}

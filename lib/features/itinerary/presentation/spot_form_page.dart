import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../spots/application/tourist_spot_providers.dart';
import '../../spots/domain/tourist_spot.dart';
import '../application/itinerary_providers.dart';
import '../data/places_repository.dart';
import '../domain/place_suggestion.dart';

class SpotFormPage extends ConsumerStatefulWidget {
  const SpotFormPage({super.key, required this.itineraryId, required this.nextOrder});

  final String itineraryId;
  final int nextOrder;

  @override
  ConsumerState<SpotFormPage> createState() => _SpotFormPageState();
}

class _SpotFormPageState extends ConsumerState<SpotFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _memoController = TextEditingController();
  final _sessionToken = '${DateTime.now().microsecondsSinceEpoch}';

  bool _isSaving = false;
  bool _isSearching = false;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _openingHoursController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      try {
        final results = await ref.read(placesRepositoryProvider).autocomplete(
              input: value,
              sessionToken: _sessionToken,
            );
        if (mounted) setState(() => _suggestions = results);
      } on PlacesApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.message)));
        }
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _suggestions = [];
      _nameController.text = suggestion.description;
    });
    FocusScope.of(context).unfocus();
    try {
      final details = await ref.read(placesRepositoryProvider).getDetails(
            placeId: suggestion.placeId,
            sessionToken: _sessionToken,
          );
      setState(() {
        _nameController.text = details.name;
        _addressController.text = details.address;
        _openingHoursController.text = details.openingHoursText;
      });
    } on PlacesApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  void _selectTouristSpot(TouristSpot spot) {
    setState(() {
      _nameController.text = spot.name;
      _addressController.text = spot.address;
      _openingHoursController.text = spot.openingHours;
      if (_memoController.text.isEmpty) {
        _memoController.text = spot.memo;
      }
      _suggestions = [];
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(itineraryRepositoryProvider).addSpot(
            itineraryId: widget.itineraryId,
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            openingHours: _openingHoursController.text.trim(),
            memo: _memoController.text.trim(),
            order: widget.nextOrder,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final touristSpotsAsync = ref.watch(allTouristSpotsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('スポットを追加')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'スポット名（Google検索で自動入力できます）',
                  border: const OutlineInputBorder(),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                onChanged: _onNameChanged,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'スポット名を入力してください。';
                  }
                  return null;
                },
              ),
              if (_suggestions.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 4),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final suggestion in _suggestions)
                          ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(suggestion.description),
                            onTap: () => _selectSuggestion(suggestion),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '住所（任意）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _openingHoursController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: '営業時間（任意）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'メモ（任意）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('追加する'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '保存済みスポットから選ぶ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '「検索」タブで調べた観光名所から選んで入力できます。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              touristSpotsAsync.when(
                data: (spots) {
                  if (spots.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('まだ保存されたスポットがありません。'),
                    );
                  }
                  return Column(
                    children: [
                      for (final spot in spots)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.bookmark_border),
                            title: Text(spot.name),
                            subtitle:
                                spot.address.isNotEmpty ? Text(spot.address) : null,
                            onTap: () => _selectTouristSpot(spot),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Row(
                  children: [
                    Expanded(child: Text('読み込みに失敗しました: $error')),
                    TextButton(
                      onPressed: () => ref.invalidate(allTouristSpotsProvider),
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
}

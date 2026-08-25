import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../itinerary/application/itinerary_providers.dart';
import '../../itinerary/data/places_repository.dart';
import '../../itinerary/domain/place_suggestion.dart';
import '../application/tourist_spot_providers.dart';

/// 観光スポットのマスタデータをGoogle検索（Places API）から登録するフォーム。
class TouristSpotFormPage extends ConsumerStatefulWidget {
  const TouristSpotFormPage({super.key});

  @override
  ConsumerState<TouristSpotFormPage> createState() =>
      _TouristSpotFormPageState();
}

class _TouristSpotFormPageState extends ConsumerState<TouristSpotFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _memoController = TextEditingController();
  final _sessionToken = '${DateTime.now().microsecondsSinceEpoch}';

  double? _latitude;
  double? _longitude;

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
    setState(() {
      _latitude = null;
      _longitude = null;
    });
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
        _latitude = details.latitude;
        _longitude = details.longitude;
      });
    } on PlacesApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('検索結果からスポットを選択してください。')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(touristSpotRepositoryProvider).addSpot(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            openingHours: _openingHoursController.text.trim(),
            memo: _memoController.text.trim(),
            latitude: _latitude!,
            longitude: _longitude!,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('観光スポットを登録')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'スポット名（Google検索から選択）',
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
              if (_latitude == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '検索結果一覧からスポットを選択すると住所・位置情報が自動入力されます。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: '住所（自動入力）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _openingHoursController,
                readOnly: true,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: '営業時間（自動入力）',
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
                    : const Text('登録する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

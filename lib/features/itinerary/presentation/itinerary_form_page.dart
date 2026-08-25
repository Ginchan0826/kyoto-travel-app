import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../application/itinerary_providers.dart';
import '../domain/itinerary.dart';

/// しおりの新規作成・編集フォーム。
/// [itinerary] を渡すと編集モード、渡さないと新規作成モードになる。
class ItineraryFormPage extends ConsumerStatefulWidget {
  const ItineraryFormPage({super.key, this.itinerary});

  final Itinerary? itinerary;

  @override
  ConsumerState<ItineraryFormPage> createState() => _ItineraryFormPageState();
}

class _ItineraryFormPageState extends ConsumerState<ItineraryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;

  bool _isSaving = false;

  bool get _isEditing => widget.itinerary != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.itinerary?.title);
    _memoController = TextEditingController(text: widget.itinerary?.memo);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final repository = ref.read(itineraryRepositoryProvider);

    try {
      if (_isEditing) {
        await repository.updateItinerary(
          itineraryId: widget.itinerary!.id,
          title: _titleController.text.trim(),
          memo: _memoController.text.trim(),
        );
      } else {
        final user = ref.read(authStateChangesProvider).value;
        if (user == null) return;
        await repository.createItinerary(
          title: _titleController.text.trim(),
          memo: _memoController.text.trim(),
          ownerId: user.uid,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'しおりを編集' : 'しおりを作成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'しおりのタイトル',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タイトルを入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memoController,
                maxLines: 4,
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
                    : const Text('保存する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../auth/application/auth_providers.dart';
import '../../itinerary/domain/spot.dart';
import '../application/tour_guide_providers.dart';
import '../data/spot_chat_history_repository.dart';
import '../data/tour_guide_repository.dart';

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

/// スポットについてAIガイドとチャットできる画面。
/// アカウント×スポットごとにやり取りをFirestoreへ保存し、再訪時に続きから表示する。
class TouringSpotChatPage extends ConsumerStatefulWidget {
  const TouringSpotChatPage({
    super.key,
    required this.itineraryId,
    required this.spot,
  });

  final String itineraryId;
  final Spot spot;

  @override
  ConsumerState<TouringSpotChatPage> createState() => _TouringSpotChatPageState();
}

class _TouringSpotChatPageState extends ConsumerState<TouringSpotChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];

  ChatSession? _session;
  bool _isLoadingHistory = true;
  bool _isSending = false;
  String? _initError;
  String? _uid;
  String? _chatKey;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) {
      setState(() {
        _initError = 'ログイン情報を取得できませんでした。';
        _isLoadingHistory = false;
      });
      return;
    }
    _uid = uid;
    _chatKey = SpotChatHistoryRepository.chatKey(
      itineraryId: widget.itineraryId,
      spotId: widget.spot.id,
    );

    final repository = ref.read(tourGuideRepositoryProvider);
    final historyRepository = ref.read(spotChatHistoryRepositoryProvider);

    try {
      final records =
          await historyRepository.getMessages(uid: uid, chatKey: _chatKey!);

      if (records.isEmpty) {
        // 初回：過去のやり取りがないので、簡単な紹介を自動生成する。
        final session = repository.startChat(
          spotName: widget.spot.name,
          spotAddress: widget.spot.address,
          spotMemo: widget.spot.memo,
        );
        _session = session;
        setState(() => _isLoadingHistory = false);
        await _send(
          repository,
          session,
          'このスポットについて、一言で簡単に紹介してください。',
          showUserMessage: false,
        );
      } else {
        // 続きから：保存済みのやり取りをAIの文脈として引き継ぐ。
        final history = records
            .map((r) => Content(r.role, [TextPart(r.text)]))
            .toList();
        final session = repository.startChat(
          spotName: widget.spot.name,
          spotAddress: widget.spot.address,
          spotMemo: widget.spot.memo,
          history: history,
        );
        _session = session;
        setState(() {
          _messages.addAll(
            records
                .where((r) => r.visible)
                .map((r) => _ChatMessage(text: r.text, isUser: r.isUser)),
          );
          _isLoadingHistory = false;
        });
        _scrollToBottom();
      }
    } on TourGuideApiException catch (e) {
      setState(() {
        _initError = e.message;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _send(
    TourGuideRepository repository,
    ChatSession session,
    String message, {
    bool showUserMessage = true,
  }) async {
    setState(() {
      _isSending = true;
      if (showUserMessage) {
        _messages.add(_ChatMessage(text: message, isUser: true));
      }
    });
    _scrollToBottom();

    try {
      final reply = await repository.sendMessage(session, message);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
      unawaited(_persistExchange(userMessage: message, modelReply: reply, showUserMessage: showUserMessage));
    } on TourGuideApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  Future<void> _persistExchange({
    required String userMessage,
    required String modelReply,
    required bool showUserMessage,
  }) async {
    if (_uid == null || _chatKey == null) return;
    final historyRepository = ref.read(spotChatHistoryRepositoryProvider);
    await historyRepository.addMessage(
      uid: _uid!,
      chatKey: _chatKey!,
      role: 'user',
      text: userMessage,
      visible: showUserMessage,
    );
    await historyRepository.addMessage(
      uid: _uid!,
      chatKey: _chatKey!,
      role: 'model',
      text: modelReply,
      visible: true,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _onSubmit() {
    final text = _textController.text.trim();
    if (text.isEmpty || _session == null || _isSending) return;
    _textController.clear();
    _send(ref.read(tourGuideRepositoryProvider), _session!, text);
  }

  void _onQuickAction(String prompt) {
    if (_session == null || _isSending) return;
    _send(ref.read(tourGuideRepositoryProvider), _session!, prompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.spot.name)),
      body: _initError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('AIガイドを開始できませんでした: $_initError'),
              ),
            )
          : _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= _messages.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }
                          final message = _messages[index];
                          return Align(
                            alignment: message.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: message.isUser
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(message.text),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSending || _session == null
                                    ? null
                                    : () => _onQuickAction('このスポットの歴史を教えてください。'),
                                child: const Text('歴史'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isSending || _session == null
                                    ? null
                                    : () => _onQuickAction('このスポットの見どころを教えてください。'),
                                child: const Text('見どころ'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                decoration: const InputDecoration(
                                  hintText: '質問を入力',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _onSubmit(),
                                enabled: !_isSending && _session != null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed:
                                  _isSending || _session == null ? null : _onSubmit,
                              icon: const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

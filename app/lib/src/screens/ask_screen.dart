import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../errors/app_error_mapper.dart';
import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/voice_service.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';
import '../widgets/verification_badge_panel.dart';
import 'collections_screen.dart';

class AskScreenArguments {
  final Verse? verseContext;

  const AskScreenArguments({this.verseContext});
}

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();

  final List<_ChatMessage> _messages = <_ChatMessage>[];

  bool _sending = false;
  bool _listening = false;
  int? _speakingMessageIndex;
  String? _error;
  bool _routeArgsApplied = false;
  Verse? _attachedVerse;
  StreamSubscription<ChatStreamEvent>? _chatStreamSubscription;
  bool _streamCanceledByUser = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreMessages();
      _applyRouteArguments();
    });
  }

  @override
  void dispose() {
    _chatStreamSubscription?.cancel();
    _voiceService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _restoreMessages() {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);

    if (_messages.isNotEmpty) {
      return;
    }

    if (appState.chatHistory.isEmpty) {
      _messages.add(
        _ChatMessage(
          role: 'assistant',
          text: strings.t('ask_welcome'),
        ),
      );
      setState(() {});
      return;
    }

    _messages.addAll(
      appState.chatHistory.map(
        (entry) => _ChatMessage(role: entry.role, text: entry.text),
      ),
    );
    setState(() {});
    _scrollToBottom();
  }

  void _applyRouteArguments() {
    if (_routeArgsApplied) {
      return;
    }
    _routeArgsApplied = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! AskScreenArguments || args.verseContext == null) {
      return;
    }

    _attachedVerse = args.verseContext;
    final strings = AppStrings(context.read<AppState>().languageCode);
    final notice =
        '${strings.t('verse_context_attached')}: BG ${_attachedVerse!.ref}';

    if (_messages.every((item) => item.text != notice)) {
      _messages.add(_ChatMessage(role: 'assistant', text: notice));
    }

    if (_messageController.text.trim().isEmpty) {
      _messageController.text =
          '${strings.t('ask_verse_prefill')} BG ${_attachedVerse!.ref}.';
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    }

    setState(() {});
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);
    if (appState.offlineMode) {
      setState(() {
        _error = strings.t('offline_chat_notice');
      });
      return;
    }

    if (_listening) {
      await _voiceService.stopListening(
        onListeningStopped: () {
          if (mounted) {
            setState(() => _listening = false);
          }
        },
      );
    }

    final now = DateTime.now();
    _messageController.clear();
    _streamCanceledByUser = false;

    var assistantIndex = -1;
    setState(() {
      _error = null;
      _messages.add(_ChatMessage(role: 'user', text: text));
      _messages.add(const _ChatMessage(role: 'assistant', text: ''));
      assistantIndex = _messages.length - 1;
      _sending = true;
    });
    _scrollToBottom();

    await appState.addChatEntries(
      <ChatHistoryEntry>[
        ChatHistoryEntry(role: 'user', text: text, createdAt: now),
      ],
    );

    try {
      final history = appState.buildChatTurns(
        maxTurns: _attachedVerse == null ? 12 : 11,
      );
      if (_attachedVerse != null) {
        history.insert(
          0,
          ChatTurn(
            role: 'user',
            content: _buildVerseContextTurn(_attachedVerse!),
          ),
        );
      }

      ChatResponse response;
      try {
        response = await _sendWithStreaming(
          appState: appState,
          message: text,
          history: history,
          assistantIndex: assistantIndex,
        );
      } catch (_) {
        if (_streamCanceledByUser) {
          return;
        }

        final hasPartial = assistantIndex >= 0 &&
            assistantIndex < _messages.length &&
            _messages[assistantIndex].text.trim().isNotEmpty;
        if (hasPartial) {
          rethrow;
        }

        response = await appState.repository.chat(
          message: text,
          mode: appState.guidanceMode,
          language: appState.languageCode,
          history: history,
        );

        if (!mounted) {
          return;
        }
        setState(() {
          _messages[assistantIndex] = _ChatMessage(
            role: 'assistant',
            text: response.reply,
            response: response,
          );
        });
      }

      if (!mounted || _streamCanceledByUser) return;

      final assistantEntry = ChatHistoryEntry(
        role: 'assistant',
        text: response.reply,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages[assistantIndex] = _ChatMessage(
          role: 'assistant',
          text: response.reply,
          response: response,
        );
      });
      await appState.addChatEntries(<ChatHistoryEntry>[assistantEntry]);

      if (appState.voiceOutputEnabled) {
        try {
          final ttsLocale =
              languageOptionFromCode(appState.languageCode).ttsLocale;
          await _speakMessage(_messages.length - 1, response.reply, ttsLocale);
        } catch (error, stackTrace) {
          if (mounted) {
            setState(
              () => _error = AppErrorMapper.toUserMessage(
                error,
                strings,
                stackTrace: stackTrace,
                context: 'AskScreen.speakMessage',
              ),
            );
          }
        }
      }
    } catch (error, stackTrace) {
      if (!mounted || _streamCanceledByUser) return;
      setState(() {
        _error = AppErrorMapper.toUserMessage(
          error,
          strings,
          stackTrace: stackTrace,
          context: 'AskScreen.send',
        );
        if (assistantIndex >= 0 &&
            assistantIndex < _messages.length &&
            _messages[assistantIndex].text.trim().isEmpty) {
          _messages[assistantIndex] = _ChatMessage(
            role: 'assistant',
            text: strings.t('error_try_again_short'),
          );
        }
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
      _scrollToBottom();
    }
  }

  Future<ChatResponse> _sendWithStreaming({
    required AppState appState,
    required String message,
    required List<ChatTurn> history,
    required int assistantIndex,
  }) async {
    final completer = Completer<ChatResponse>();

    _chatStreamSubscription = appState.repository
        .streamChat(
          message: message,
          mode: appState.guidanceMode,
          language: appState.languageCode,
          history: history,
        )
        .listen(
      (event) {
        if (!mounted) {
          return;
        }

        if (event.token != null) {
          final current = _messages[assistantIndex];
          setState(() {
            _messages[assistantIndex] = _ChatMessage(
              role: 'assistant',
              text: '${current.text}${event.token}',
            );
          });
          _scrollToBottom();
          return;
        }

        final response = event.response;
        if (response != null) {
          setState(() {
            _messages[assistantIndex] = _ChatMessage(
              role: 'assistant',
              text: response.reply,
              response: response,
            );
          });
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted && !_streamCanceledByUser) {
          completer.completeError(
            const ApiException('Stream closed before completion'),
          );
        }
      },
      cancelOnError: true,
    );

    try {
      return await completer.future;
    } finally {
      await _chatStreamSubscription?.cancel();
      _chatStreamSubscription = null;
    }
  }

  Future<void> _stopGenerating() async {
    if (_chatStreamSubscription == null) {
      return;
    }

    _streamCanceledByUser = true;
    await _chatStreamSubscription?.cancel();
    _chatStreamSubscription = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _sending = false;
    });
  }

  String _buildVerseContextTurn(Verse verse) {
    final transliteration = verse.transliteration.trim();
    final transliterationText =
        transliteration.isEmpty ? '' : ' Transliteration: $transliteration.';

    return 'Use Bhagavad Gita verse BG ${verse.ref} as attached context. '
        'Sanskrit: ${verse.sanskrit}. '
        'Translation: ${verse.translation}.'
        '$transliterationText';
  }

  Future<void> _toggleListening() async {
    final appState = context.read<AppState>();
    final strings = AppStrings(appState.languageCode);

    if (!appState.voiceInputEnabled) {
      setState(() {
        _error = strings.t('voice_unavailable');
      });
      return;
    }

    if (_listening) {
      await _voiceService.stopListening(
        onListeningStopped: () {
          if (mounted) {
            setState(() => _listening = false);
          }
        },
      );
      return;
    }

    final locale = languageOptionFromCode(appState.languageCode).ttsLocale;
    bool ready = false;
    try {
      ready = await _voiceService.startListening(
        localeId: locale,
        onResult: (spokenText) {
          if (!mounted) {
            return;
          }
          setState(() {
            _messageController.text = spokenText;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
          });
        },
        onListeningStopped: () {
          if (mounted) {
            setState(() => _listening = false);
          }
        },
      );
    } catch (_) {
      ready = false;
    }

    if (!ready) {
      setState(() => _error = strings.t('voice_unavailable'));
      return;
    }

    setState(() {
      _error = null;
      _listening = true;
    });
  }

  Future<void> _speakMessage(
      int messageIndex, String text, String locale) async {
    if (_speakingMessageIndex == messageIndex) {
      await _voiceService.stopSpeaking();
      if (mounted) {
        setState(() => _speakingMessageIndex = null);
      }
      return;
    }

    setState(() => _speakingMessageIndex = messageIndex);
    try {
      await _voiceService.speak(text: text, localeId: locale);
    } finally {
      if (mounted) {
        setState(() => _speakingMessageIndex = null);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appState = context.watch<AppState>();
    final strings = AppStrings(appState.languageCode);
    final ttsLocale = languageOptionFromCode(appState.languageCode).ttsLocale;
    final chatAvailable = !appState.offlineMode;
    final canStopStreaming = _chatStreamSubscription != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('chat_title')),
      ),
      body: SpiritualBackground(
        child: Column(
          children: <Widget>[
            if (_attachedVerse != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    '${strings.t('verse_context')}: BG ${_attachedVerse!.ref}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
              ),
            if (appState.offlineMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    strings.t('offline_chat_notice'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final message = _messages[index];
                  // Find the user question that preceded this assistant message.
                  String? precedingQuestion;
                  if (message.role == 'assistant' && message.response != null) {
                    for (int i = index - 1; i >= 0; i--) {
                      if (_messages[i].role == 'user') {
                        precedingQuestion = _messages[i].text;
                        break;
                      }
                    }
                  }
                  return _MessageBubble(
                    message: message,
                    strings: strings,
                    speaking: _speakingMessageIndex == index,
                    onSpeakPressed: message.role == 'assistant' &&
                            message.text.trim().isNotEmpty
                        ? () => _speakMessage(index, message.text, ttsLocale)
                        : null,
                    onSavePressed:
                        (message.role == 'assistant' && message.response != null)
                            ? () => showAddToCollectionSheet(
                                  context: context,
                                  item: BookmarkItem.fromAnswer(
                                    answer: message.text,
                                    question: precedingQuestion ?? '',
                                  ),
                                )
                            : null,
                  );
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.35)),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    IconButton.filledTonal(
                      tooltip: _listening
                          ? strings.t('voice_stop')
                          : strings.t('voice_start'),
                      onPressed: _sending ? null : _toggleListening,
                      icon: Icon(_listening
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_sending && chatAvailable,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: chatAvailable ? (_) => _send() : null,
                        decoration: InputDecoration(
                          hintText: strings.t('ask_hint'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending
                          ? (canStopStreaming ? _stopGenerating : null)
                          : (chatAvailable ? _send : null),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        padding: const EdgeInsets.all(0),
                      ),
                      child: _sending
                          ? const Icon(Icons.stop_rounded)
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final AppStrings strings;
  final bool speaking;
  final VoidCallback? onSpeakPressed;
  final VoidCallback? onSavePressed;

  const _MessageBubble({
    required this.message,
    required this.strings,
    required this.speaking,
    required this.onSpeakPressed,
    this.onSavePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.primary.withValues(alpha: 0.95)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.35)),
                ),
                child: Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                ),
              ),
              if (!isUser && (onSpeakPressed != null || onSavePressed != null))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (onSpeakPressed != null)
                        TextButton.icon(
                          onPressed: onSpeakPressed,
                          icon: Icon(speaking
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded),
                          label: Text(speaking
                              ? strings.t('stop_audio')
                              : strings.t('speak')),
                        ),
                      if (onSavePressed != null)
                        TextButton.icon(
                          onPressed: onSavePressed,
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: Text(strings.t('save_answer')),
                        ),
                    ],
                  ),
                ),
              if (message.response != null) ...<Widget>[
                const SizedBox(height: 8),
                _AssistantContextCard(
                    response: message.response!, strings: strings),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantContextCard extends StatelessWidget {
  final ChatResponse response;
  final AppStrings strings;

  const _AssistantContextCard({required this.response, required this.strings});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            VerificationBadgePanel(
              strings: strings,
              verificationLevel: response.verificationLevel,
              verificationDetails: response.verificationDetails,
              provenance: response.provenance,
            ),
            const SizedBox(height: 10),
            Text(strings.t('supporting_verses'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            ...response.verses.map(
              (verse) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${verse.ref}: ${verse.translation}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${strings.t('action')}: ${response.actionStep}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${strings.t('reflect')}: ${response.reflectionPrompt}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String role;
  final String text;
  final ChatResponse? response;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.response,
  });
}

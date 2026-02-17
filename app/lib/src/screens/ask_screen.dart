import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/voice_service.dart';
import '../state/app_state.dart';
import '../widgets/spiritual_background.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreMessages();
    });
  }

  @override
  void dispose() {
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

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    final appState = context.read<AppState>();

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

    setState(() {
      _error = null;
      _messages.add(_ChatMessage(role: 'user', text: text));
      _sending = true;
    });
    _scrollToBottom();

    await appState.addChatEntries(
      <ChatHistoryEntry>[
        ChatHistoryEntry(role: 'user', text: text, createdAt: now),
      ],
    );

    try {
      final response = await appState.repository.chat(
        message: text,
        mode: appState.guidanceMode,
        language: appState.languageCode,
        history: appState.buildChatTurns(),
      );

      if (!mounted) return;

      final assistantEntry = ChatHistoryEntry(
        role: 'assistant',
        text: response.reply,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            text: response.reply,
            response: response,
          ),
        );
      });
      await appState.addChatEntries(<ChatHistoryEntry>[assistantEntry]);

      if (appState.voiceOutputEnabled) {
        try {
          final ttsLocale =
              languageOptionFromCode(appState.languageCode).ttsLocale;
          await _speakMessage(_messages.length - 1, response.reply, ttsLocale);
        } catch (error) {
          if (mounted) {
            setState(() => _error = error.toString());
          }
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _messages.add(
          const _ChatMessage(
            role: 'assistant',
            text: 'I could not process that right now. Please try again.',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('chat_title')),
      ),
      body: SpiritualBackground(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final message = _messages[index];
                  return _MessageBubble(
                    message: message,
                    strings: strings,
                    speaking: _speakingMessageIndex == index,
                    onSpeakPressed: message.role == 'assistant'
                        ? () => _speakMessage(index, message.text, ttsLocale)
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
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: strings.t('ask_hint'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _sending ? null : _send,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(52, 52),
                        padding: const EdgeInsets.all(0),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
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

  const _MessageBubble({
    required this.message,
    required this.strings,
    required this.speaking,
    required this.onSpeakPressed,
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
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton.icon(
                    onPressed: onSpeakPressed,
                    icon: Icon(speaking
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded),
                    label: Text(speaking
                        ? strings.t('stop_audio')
                        : strings.t('speak')),
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

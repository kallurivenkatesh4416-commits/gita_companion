import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../i18n/app_strings.dart';
import '../models/models.dart';
import '../services/voice_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/ui_text_utils.dart';
import '../widgets/app_bottom_nav.dart';
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
    final strings = AppStrings(appState.languageCode);

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
            setState(() {
              _error = mapFriendlyError(
                error,
                strings: strings,
                context: 'chat',
              );
            });
          }
        }
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = mapFriendlyError(
          error,
          strings: strings,
          context: 'chat',
        );
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

  void _sendFollowUp(String text) {
    if (_sending) {
      return;
    }
    _messageController.text = text;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    _send();
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
        animate: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final message = _messages[index];
                  final isLatestAssistant = message.role == 'assistant' &&
                      index == _messages.length - 1 &&
                      message.response != null;
                  return _MessageBubble(
                    message: message,
                    strings: strings,
                    speaking: _speakingMessageIndex == index,
                    showFollowUps: isLatestAssistant,
                    onFollowUpSelected: isLatestAssistant ? _sendFollowUp : null,
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
      bottomNavigationBar: const SafeArea(
        top: false,
        child: AppBottomNav(currentIndex: 2),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final AppStrings strings;
  final bool speaking;
  final bool showFollowUps;
  final ValueChanged<String>? onFollowUpSelected;
  final VoidCallback? onSpeakPressed;

  const _MessageBubble({
    required this.message,
    required this.strings,
    required this.speaking,
    required this.showFollowUps,
    required this.onFollowUpSelected,
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
              if (isUser)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 30,
                      height: 30,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2E4CD),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD99A52).withValues(alpha: 0.6),
                        ),
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        size: 18,
                        color: Color(0xFF9A5C2D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EC),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(4),
                            bottomRight: Radius.circular(18),
                          ),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: Color(0xFFD1863B),
                                width: 3,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            message.text,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF2D2419),
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (!isUser)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 38),
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
                Padding(
                  padding: EdgeInsets.only(left: isUser ? 0 : 38),
                  child: _AssistantContextCard(
                      response: message.response!, strings: strings),
                ),
              ],
              if (showFollowUps && onFollowUpSelected != null) ...<Widget>[
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(left: isUser ? 0 : 38),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.t('suggested_followups'),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <String>[
                          strings.t('follow_up_tell_more'),
                          strings.t('follow_up_related_verse'),
                          strings.t('follow_up_practice_this'),
                        ]
                            .map(
                              (prompt) => ActionChip(
                                label: Text(prompt),
                                onPressed: () => onFollowUpSelected!(prompt),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          strings.t('supporting_verses'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          '${strings.t('action')}: ${response.actionStep}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        children: <Widget>[
          ...response.verses.map(
            (verse) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'BG ${verse.ref}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verse.sanskrit,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.sanskritStyle(
                      context,
                      fontSize: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    verse.translation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Text(
            '${strings.t('reflect')}: ${response.reflectionPrompt}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
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

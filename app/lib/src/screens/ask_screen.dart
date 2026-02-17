import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      role: 'assistant',
      text:
          'Ask me anything, and I will respond using Bhagavad Gita verses with practical guidance.',
    ),
  ];

  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }

    _messageController.clear();
    setState(() {
      _error = null;
      _messages.add(_ChatMessage(role: 'user', text: text));
      _sending = true;
    });
    _scrollToBottom();

    final appState = context.read<AppState>();
    final history = _messages
        .where((message) => message.role == 'user' || message.role == 'assistant')
        .map((message) => ChatTurn(role: message.role, content: message.text))
        .toList(growable: false);

    try {
      final response = await appState.repository.chat(
        message: text,
        mode: appState.guidanceMode,
        history: history,
      );

      setState(() {
        _messages.add(_ChatMessage(
          role: 'assistant',
          text: response.reply,
          response: response,
        ));
      });
    } catch (error) {
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
      setState(() => _sending = false);
      _scrollToBottom();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gita Chatbot'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final message = _messages[index];
                  return _MessageBubble(message: message);
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
                    top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.35)),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask about stress, duty, focus, relationships...',
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

  const _MessageBubble({required this.message});

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
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      : Border.all(color: colorScheme.outline.withValues(alpha: 0.35)),
                ),
                child: Text(
                  message.text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                ),
              ),
              if (message.response != null) ...<Widget>[
                const SizedBox(height: 8),
                _AssistantContextCard(response: message.response!),
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

  const _AssistantContextCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Supporting verses', style: Theme.of(context).textTheme.titleSmall),
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
              'Action: ${response.actionStep}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reflect: ${response.reflectionPrompt}',
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
